//
//  NSObject+BGBASwizzle.h
//  BGBadAccessProtect
//
//  Created by jin fu on 2022/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (BGBASwizzle)
/**
 Swizzle Class Method

 @param originSelector originSelector
 @param swizzleSelector swizzleSelector
 */
+ (void)fj_swizzleClassMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector;

/**
 Swizzle Instance Method

 @param originSelector originSelector
 @param swizzleSelector swizzleSelector
 */
- (void)fj_swizzleInstanceMethod:(SEL)originSelector withSwizzleMethod:(SEL)swizzleSelector;
@end

NS_ASSUME_NONNULL_END
