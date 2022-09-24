//
//  NSObject+ZombieHook.m
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/11.
//

#import "NSObject+ZombieHook.h"
#import "NSObject+BGBASwizzle.h"
#import <objc/runtime.h>
#import "BGZombieSub.h"
#import "BGZombieExceptionProxy.h"
#import "pthread.h"
#include <mach/mach.h>

#define ZombieActivityTime 30 // 僵尸对象存活时间间隔

typedef struct ZombieObj {
    void *p; // BGZombieSub obj
    Class originalClass; // reall class
    int referCnt; // refer count
    NSTimeInterval addTime; // add time
}ZombieObjData;

// 单链表 管理僵尸对象🧟‍♀️
typedef struct UnfreeZombie {
    ZombieObjData *data;
    struct UnfreeZombie *next;
}ZombieNode;

// 队列链表管理
ZombieNode *_header; // 头节点
pthread_mutex_t global_mutex; // 单链表 添加和删除僵尸对象的锁
ZombieNode* creatList(void); // 创建一个空链表
void addZombieObj(ZombieNode *header, void *p, Class class); //添加一个僵尸对象 (插入表头)
void clearUnReferZombieObj(void); // 定时清除超时未引用的僵尸对象
Class zombieObjMessageAndReferCountAdd(void *p); //referCnt++ 并返回僵尸对象的相关信息 比如originalClass

// 僵尸对象内存管理
NSInteger _zombieObjCnt; // 总的僵尸对象数量
NSInteger _memoryAvailableUsage; // 可用内存
void availableMemoryUpdate(void); // 更新可用内存
void clearZombieObjs(void); // 内存即将达到阀值，清理链表后面一半僵尸对象 (FIFO策略删除)

ZombieNode* creatList(void)
{
    ZombieNode *header = (ZombieNode *)malloc(sizeof(ZombieNode));
    header->data = NULL;
    header->next = NULL;
    return header;
}

void addZombieObj(ZombieNode *header, void *p, Class class)
{
    pthread_mutex_lock(&global_mutex);
    if (!header || !p) {
        pthread_mutex_unlock(&global_mutex);
        return;
    }
    
    ZombieObjData *data = (ZombieObjData *)malloc(sizeof(ZombieObjData));
    data->p = p;
    data->originalClass = class;
    data->referCnt = 0;
    data->addTime = [NSProcessInfo.processInfo systemUptime];
    
    ZombieNode *addNode = (ZombieNode *)malloc(sizeof(ZombieNode));
    addNode->data = data;
    addNode->next = header->next;
    header->next = addNode;
    _zombieObjCnt++;
    pthread_mutex_unlock(&global_mutex);
}

void clearUnReferZombieObj(void)
{
    pthread_mutex_lock(&global_mutex);
    if (!_header || _header->next==NULL) {
        pthread_mutex_unlock(&global_mutex);
        return;
    }
    ZombieNode *lastNode = _header;
    ZombieNode *currentNode = _header;
    while (currentNode->next != NULL) {
        currentNode = currentNode->next;
        ZombieObjData *data = currentNode->data;
        NSTimeInterval currentT = [NSProcessInfo.processInfo systemUptime];
        // 存活超过30s
        if (currentT-data->addTime > ZombieActivityTime) {
            // 未被引用 删除节点并释放掉
            if (data->referCnt==0) {
                // 删除当前节点
                ZombieNode *deleteNode = currentNode;
                lastNode->next = deleteNode->next;
                currentNode = lastNode;
                // 释放内存
                free(data->p);
                free(data);
                free(deleteNode);
                _zombieObjCnt--;
            } else {
                lastNode = currentNode;
                // 30s内被引用到又可以再次存活>=30s
                data->referCnt = 0;
                data->addTime = currentT;
            }
        } else {
            lastNode = currentNode;
        }
    }
    pthread_mutex_unlock(&global_mutex);
}

Class zombieObjMessageAndReferCountAdd(void *p)
{
    pthread_mutex_lock(&global_mutex);
    if (!_header || _header->next==NULL || !p) {
        pthread_mutex_unlock(&global_mutex);
        return NULL;
    }
    ZombieNode *currentNode = _header;
    while (currentNode->next != NULL) {
        currentNode = currentNode->next;
        ZombieObjData *data = currentNode->data;
        if (data->p == p) {
            data->referCnt = data->referCnt+1;
            pthread_mutex_unlock(&global_mutex);
            return data->originalClass;;
        }
    }
    pthread_mutex_unlock(&global_mutex);
    return NULL;
}

void availableMemoryUpdate(void)
{
    NSInteger physicalMemory = (NSInteger)([NSProcessInfo processInfo].physicalMemory/1024/1024);
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS)
    {
        int64_t memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
        NSInteger memoryUsage = (NSInteger)(memoryUsageInByte/1024/1024);
        _memoryAvailableUsage = physicalMemory*0.5 - memoryUsage-10; // 内存阀值(physicalMemory*0.5) - app已经使用的内存 - 10M
        if (_memoryAvailableUsage <= 0) {
            clearZombieObjs();
        }
    }
}

void clearZombieObjs(void)
{
    pthread_mutex_lock(&global_mutex);
    if (_zombieObjCnt <= 1) {
        pthread_mutex_unlock(&global_mutex);
        return;
    }
    NSInteger clearCnt = _zombieObjCnt*0.5;
    ZombieNode *lastNode = _header;
    ZombieNode *currentNode = _header;
    NSInteger i = 1;
    while (currentNode->next != NULL) {
        currentNode = currentNode->next;
        if (i>clearCnt) {
            ZombieObjData *data = currentNode->data;
            // 删除当前节点
            ZombieNode *deleteNode = currentNode;
            lastNode->next = deleteNode->next;
            currentNode = lastNode;
            // 释放内存
            free(data->p);
            free(data);
            free(deleteNode);
            _zombieObjCnt--;
        } else {
            lastNode = currentNode;
        }
        i++;
    }
    pthread_mutex_unlock(&global_mutex);
}

@implementation NSObject (ZombieHook)

#pragma mark - piblic
+ (void)fj_swizzleZombie
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_mutex_init(&global_mutex, NULL); //创建链表管理锁
        _header = creatList();
        _memoryAvailableUsage = 10;
        _zombieObjCnt = 0;
        availableMemoryUpdate();
        [self fj_swizzleInstanceMethod:@selector(dealloc) withSwizzleMethod:@selector(zombie_dealloc)];
    });
}

- (void)zombie_dealloc
{
    Class currentClass = self.class;
    @autoreleasepool {
        // 只对设置的类进行僵尸对象
        if ([BGZombieExceptionProxy share].cofigurations == BGZombieCofigurationsJustZombieClass && ![[BGZombieExceptionProxy share].checkClassesSet containsObject:self.class]) {
            [self zombie_dealloc];
            return;
        }
    }
    // 释放掉 关联对象等
    objc_destructInstance(self);
    // 变成僵尸对象
    object_setClass(self, [BGZombieSub class]);
    BGZombieSub *obj = (BGZombieSub *)self;
    addZombieObj(_header, (__bridge void *)obj, currentClass);
}

@end
