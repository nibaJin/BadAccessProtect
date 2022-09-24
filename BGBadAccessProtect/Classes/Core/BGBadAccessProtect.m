//
//  BGBadAccessProtect.m
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/12.
//

#import "BGBadAccessProtect.h"
#import "BGZombieExceptionProxy.h"

@implementation BGBadAccessProtect

+ (BOOL)exceptionWhenTerminate{
    return [BGZombieExceptionProxy share].exceptionWhenTerminate;
}

+ (void)setExceptionWhenTerminate:(BOOL)exceptionWhenTerminate{
    [BGZombieExceptionProxy share].exceptionWhenTerminate = exceptionWhenTerminate;
}

+ (NSArray<Class> *)protectClass
{
    return [BGZombieExceptionProxy share].checkClassesSet.allObjects;
}

+ (void)setProtectClass:(NSArray<Class> *)protectClass
{
    [[BGZombieExceptionProxy share] addZombieClassArray:protectClass];
}

+ (void)registerBadAccessExceptionHandle:(id<FJExceptionHandle>)handle
{
    [BGZombieExceptionProxy share].delegate = handle;
}

+ (void)startWithCofigurations:(BGZombieCofigurations)cofigurations
{
    [[BGZombieExceptionProxy share] startWithCofigurations:cofigurations];
}

@end
