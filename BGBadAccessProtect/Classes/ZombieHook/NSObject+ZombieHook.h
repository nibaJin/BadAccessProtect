//
//  NSObject+ZombieHook.h
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/11.
//

#import <Foundation/Foundation.h>

/// 获取僵尸对象真实的Class & referCnt++
/// @param p BGZombieSub 僵尸对象
Class _Nullable zombieObjMessageAndReferCountAdd(void * _Nullable p);

/// 定时清除超时未引用的僵尸对象
void clearUnReferZombieObj(void);

/// 定时监听可用内存
void availableMemoryUpdate(void);

/// 内存即将达到阀值，清理链表后面一半僵尸对象 (FIFO策略删除)
void clearZombieObjs(void);

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ZombieHook)

+ (void)fj_swizzleZombie;

@end

NS_ASSUME_NONNULL_END
