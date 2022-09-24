//
//  BGZombieSub.m
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/11.
//

#import "BGZombieSub.h"
#import <objc/runtime.h>
#import "BGZombieExceptionProxy.h"
#import "NSObject+ZombieHook.h"

@implementation BGZombieSub

// 捕获野指针发生
void handleException(void *p, SEL selector)
{
    Class originalClass = zombieObjMessageAndReferCountAdd(p);
    if (!originalClass) {
        originalClass = BGZombieSub.class;
    }
    [BGZombieExceptionProxy.share handleExceptionWithClass:originalClass selector:selector];
}

-(void)forwardInvocation:(NSInvocation *)anInvocation
{
    handleException((__bridge void *)self, anInvocation.selector);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    // Customer method signature
    // void xxx(id,sel,id)
    return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}

- (instancetype)retain
{
    handleException((__bridge void *)self, NSSelectorFromString(@"retain"));
    return self;
}

- (id)performSelector:(SEL)aSelector
{
    handleException((__bridge void *)self, NSSelectorFromString(@"performSelector:"));
    return nil;
}

- (id)performSelector:(SEL)aSelector withObject:(id)object
{
    handleException((__bridge void *)self, NSSelectorFromString(@"performSelector:withObject:"));
    return nil;
}

- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2
{
    handleException((__bridge void *)self, NSSelectorFromString(@"performSelector:withObject:withObject:"));
    return nil;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    handleException((__bridge void *)self, NSSelectorFromString(@"isKindOfClass:"));
    return NO;
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    handleException((__bridge void *)self, NSSelectorFromString(@"isMemberOfClass:"));
    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    handleException((__bridge void *)self, NSSelectorFromString(@"conformsToProtocol:"));
    return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    handleException((__bridge void *)self, NSSelectorFromString(@"respondsToSelector:"));
    return NO;
}

- (oneway void)release
{
    handleException((__bridge void *)self, NSSelectorFromString(@"release"));
}

- (instancetype)autorelease
{
    handleException((__bridge void *)self, NSSelectorFromString(@"autorelease"));
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wobjc-missing-super-calls"
- (void)dealloc
{
    Class originalClass = zombieObjMessageAndReferCountAdd((__bridge void *)self);
    if (!originalClass) {
        originalClass = BGZombieSub.class;
    }
    [BGZombieExceptionProxy.share handleExceptionWithClass:originalClass selector:NSSelectorFromString(@"dealloc")];
}
#pragma clang diagnostic pop

@end
