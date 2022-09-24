//
//  BGViewController.m
//  BGBadAccessProtect
//
//  Created by jin fu on 05/07/2022.
//  Copyright (c) 2022 jin fu. All rights reserved.
//

#import "BGViewController.h"
#import "BGBadAccessProtect.h"
#import "BGTestObject.h"

@interface BGViewController ()<FJExceptionHandle>
@property (nonatomic, assign) BGTestObject *testObj;
@end

@implementation BGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *registBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [registBtn setTitle:@"Regist BGBadAccessProtect" forState:UIControlStateNormal];
    [registBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    registBtn.frame = CGRectMake(0, 150, self.view.frame.size.width, 50);
    [registBtn addTarget:self action:@selector(registBGBadAccessProtect) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:registBtn];
    
    UIButton *creatBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [creatBtn setTitle:@"Creat BGBadAccess Object" forState:UIControlStateNormal];
    [creatBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    creatBtn.frame = CGRectMake(0, 250, self.view.frame.size.width, 50);
    [creatBtn addTarget:self action:@selector(creatBadAccessObj) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:creatBtn];
    
    UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [testBtn setTitle:@"Test Bad Access Crash" forState:UIControlStateNormal];
    [testBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    testBtn.frame = CGRectMake(0, 300, self.view.frame.size.width, 50);
    [testBtn addTarget:self action:@selector(testBadAccess) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testBtn];
    
    UIButton *testCreatBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [testCreatBtn setTitle:@"Test creat 10000 obj" forState:UIControlStateNormal];
    [testCreatBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    testCreatBtn.frame = CGRectMake(0, 350, self.view.frame.size.width, 50);
    [testCreatBtn addTarget:self action:@selector(testCreatAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testCreatBtn];
    
    
//    NSLog(@"%zd, %zd, %zd", class_getInstanceSize(str.class), sizeof(char), malloc_size((__bridge void *) obj));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - FJExceptionHandle
/*
 @{
 @"msg": @"[TestObj test]", // 野指针crash msgsend
 @"deallocStack": @[],      // 野指针dealloc时的调用栈情况
 @"zombieStack" : @[],      // 野指针发生时的调用栈情况
 @"loadAddress" : @"",      // 加载地址
 @"slideAddress" : @""      // 偏移地址
 }
 该字典 根据上面的key进行获取，最好使用objecForKey安全获取
*/
- (void)handleCrashException:(NSDictionary *_Nullable)exceptionMessageDic
{
    
}

#pragma mark - Test

- (void)creatBadAccessObj
{
    self.testObj = [[BGTestObject alloc] init];
}

- (void)registBGBadAccessProtect
{
//    BGBadAccessProtect.exceptionWhenTerminate = YES;
    [BGBadAccessProtect registerBadAccessExceptionHandle:self];
    [BGBadAccessProtect startWithCofigurations:BGZombieCofigurationsDefault];
}

- (void)testBadAccess
{
    if (self.testObj && [self.testObj respondsToSelector:@selector(test)]) {
        [self.testObj test];
    }
}

- (void)testCreatAction
{
    @autoreleasepool {
        for (NSInteger i = 0; i<10000; i++) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
            view.backgroundColor = UIColor.redColor;
        }
    }
}

@end
