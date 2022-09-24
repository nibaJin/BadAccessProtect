//
//  BGZombieExceptionProxy.h
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/11.
//

#import <Foundation/Foundation.h>
#import "BGBadAccessProtect.h"

NS_ASSUME_NONNULL_BEGIN
@class BGZombieSub;
@interface BGZombieExceptionProxy : NSObject

// 只能通过这个实例化对象
+ (instancetype)share;

@property(nonatomic,readwrite,weak)id<FJExceptionHandle> delegate;

// 指定特定类防护 - 这里会获取详细的调用栈
- (void)addZombieClassArray:(NSArray*)classs;

// 开启野指针防护 - 设置好其他参数 再调用
- (void)startWithCofigurations:(BGZombieCofigurations)cofigurations;

// 当发生野指针时 是否断言？ 默认NO
@property (nonatomic, assign) BOOL exceptionWhenTerminate;

@property(nonatomic,readonly,strong) NSSet *checkClassesSet;

@property(nonatomic,readonly,assign) BGZombieCofigurations cofigurations;

@end

@interface BGZombieExceptionProxy (Exception)
- (void)handleExceptionWithClass:(Class)realClass selector:(SEL)sel;
@end

NS_ASSUME_NONNULL_END
