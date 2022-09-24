//
//  BGZombieExceptionProxy.m
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/11.
//

#import "BGZombieExceptionProxy.h"
#import "NSObject+ZombieHook.h"
#import <mach-o/dyld.h>

#define KAvailableMemoryUpdateTimer 5
#define KClearZombieTimer 30
@interface BGZombieExceptionProxy ()
@property (nonatomic, assign, readwrite) BGZombieCofigurations cofigurations;

@property (nonatomic, strong) NSMutableSet *zombieClassSet;

@property (nonatomic, strong) NSTimer *availableMemoryUpdateTimer; // 5s更新一次
@property (nonatomic, strong) NSTimer *clearZombieTimer; // 30s更新一次

@end

@implementation BGZombieExceptionProxy
+ (instancetype)share
{
    static dispatch_once_t onceToken;
    static id share;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _zombieClassSet = [[NSMutableSet alloc] init];
        _cofigurations = BGZombieCofigurationsDefault;
        _exceptionWhenTerminate = NO;
    }
    return self;
}

#pragma mark - pulic api
- (void)addZombieClassArray:(NSArray*)classs
{
    if (classs && [classs isKindOfClass:NSArray.class] && classs.count > 0) {
        [_zombieClassSet addObjectsFromArray:classs];
    }
}

- (NSSet *)checkClassesSet
{
    return _zombieClassSet;
}

- (void)startWithCofigurations:(BGZombieCofigurations)cofigurations
{
    _cofigurations = cofigurations;
    [NSObject fj_swizzleZombie];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    self.clearZombieTimer = [NSTimer scheduledTimerWithTimeInterval:KClearZombieTimer
                                                  target:self
                                                selector:@selector(clearZombie)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.clearZombieTimer forMode:NSDefaultRunLoopMode];
    self.availableMemoryUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:KAvailableMemoryUpdateTimer
                                                  target:self
                                                selector:@selector(availableMemoryUpdate)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.availableMemoryUpdateTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark - privicy Memory Manager
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    clearZombieObjs();
}

- (void)availableMemoryUpdate
{
    availableMemoryUpdate();
}

// 主动清理僵尸对象
- (void)clearZombie
{
    clearUnReferZombieObj();
}

@end

/**
 Get application base address,the application different base address after started
 
 @return base address
 */
uintptr_t get_load_address(void) {
    const struct mach_header *exe_header = NULL;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            exe_header = header;
            break;
        }
    }
    return (uintptr_t)exe_header;
}

/**
 Address Offset

 @return slide address
 */
uintptr_t get_slide_address(void) {
    uintptr_t vmaddr_slide = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            vmaddr_slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    
    return (uintptr_t)vmaddr_slide;
}

@implementation BGZombieExceptionProxy (Exception)
- (void)handleExceptionWithClass:(Class)realClass selector:(SEL)sel
{
    NSString *msg;
    if (realClass && sel) {
        msg = [NSString stringWithFormat:@"[%@ %@]", realClass, NSStringFromSelector(sel)];
    }

    if ([self.delegate respondsToSelector:@selector(handleCrashException:)]) {
        NSMutableDictionary *dic = [NSMutableDictionary new];
        if (msg) {
            [dic setObject:msg forKey:@"msg"];
        }

        NSArray *zombieStack = [NSThread callStackSymbols];
        if (zombieStack) {
            [dic setObject:zombieStack forKey:@"zombieStack"];
        }

        uintptr_t loadAddress =  get_load_address();
        NSString *loadAddressStr = [NSString stringWithFormat:@"%ld", loadAddress];
        if (loadAddressStr) {
            [dic setObject:loadAddressStr forKey:@"loadAddress"];
        }

        uintptr_t slideAddress =  get_slide_address();
        NSString *slideAddressStr = [NSString stringWithFormat:@"%ld", slideAddress];
        if (slideAddressStr) {
            [dic setObject:slideAddressStr forKey:@"slideAddress"];
        }

        [self.delegate handleCrashException:dic];
    }
    
#if DEBUG
    NSLog(@"================================BGBadAccessProtect Start==================================");
    if (msg) {
        NSLog(@"Bad Access msg:%@",msg);
    }
    NSArray *zombieStack = [NSThread callStackSymbols];
    if (zombieStack) {
        NSLog(@"Zombie Stack info:%@",zombieStack);
    }
    NSLog(@"================================BGBadAccessProtect End====================================");
    if (self.exceptionWhenTerminate) {
        NSAssert(NO, @"");
    }
#endif
}

@end
