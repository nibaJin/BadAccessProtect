//
//  BGBadAccessProtect.h
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/12.
//

#import <Foundation/Foundation.h>

@protocol FJExceptionHandle <NSObject>

/*
 @{
 @"msg": @"[TestObj test]", // 野指针crash msgsend
 @"zombieStack" : @[],      // 野指针发生时的调用栈情况
 @"loadAddress" : @"",      // 加载地址
 @"slideAddress" : @""      // 偏移地址
 }
 该字典 根据上面的key进行获取，最好使用objecForKey安全获取
*/
- (void)handleCrashException:(NSDictionary *_Nullable)exceptionMessageDic;
@end

/*
 BGZombieDefault: 默认所有类进行防护
 BGZombieJustZombieClass : 只对protectClass防护
 */
typedef NS_ENUM(NSUInteger, BGZombieCofigurations) {
    BGZombieCofigurationsDefault = 0, // 默认
    BGZombieCofigurationsJustZombieClass // 指定类防护
};

NS_ASSUME_NONNULL_BEGIN

@interface BGBadAccessProtect : NSObject

// 设置是否发现野指针断言crash （调试使用 默认NO）
@property(class,nonatomic,readwrite, assign)BOOL exceptionWhenTerminate;

// 防护已知类列表
// 已知类列表 会保留更详细的调用栈，所以内存会占用的更多
@property(class,nonatomic,readwrite, strong)NSArray<Class> *protectClass;

// 注册崩溃回调
+ (void)registerBadAccessExceptionHandle:(id<FJExceptionHandle>)handle;

// 开启野指针防护 （建议： 设置好所有其他参数，再调用 ）
+ (void)startWithCofigurations:(BGZombieCofigurations)cofigurations;

@end

NS_ASSUME_NONNULL_END
