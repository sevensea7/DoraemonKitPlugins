//
//  DoraemonMLeaksFinderViewController.m
//  WMDoraemonKitPlugins
//
//  Created by sevensea996 on 2022/2/17.
//

#import "DoraemonMLeaksFinderViewController.h"
#import <DoraemonKit/DoraemonHomeWindow.h>
#import <DoraemonKit/DoraemonCellSwitch.h>
#import <DoraemonKit/UIView+Doraemon.h>

static NSString * const kDoraemonMemoryLeakAlertKey = @"doraemon_memory_leak_alert_key";

@interface DoraemonMLeaksFinderViewController () <DoraemonSwitchViewDelegate>

@property (nonatomic, strong) DoraemonCellSwitch *alertSwitchView;

@end

@implementation DoraemonMLeaksFinderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"内存泄漏检测";
    [self.view addSubview:self.alertSwitchView];
}

- (BOOL)needBigTitleView{
    return YES;
}

#pragma mark - DoraemonSwitchViewDelegate

- (void)changeSwitchOn:(BOOL)on sender:(id)sender{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (sender == self.alertSwitchView.switchView) {
        [userDefaults setBool:on forKey:kDoraemonMemoryLeakAlertKey];
    }
    
    [userDefaults synchronize];
}

#pragma mark - Accessor

- (DoraemonCellSwitch *)alertSwitchView {
    if (!_alertSwitchView) {
        _alertSwitchView = [[DoraemonCellSwitch alloc] initWithFrame:CGRectMake(0, self.bigTitleView.doraemon_bottom, self.view.doraemon_width, 53)];
        _alertSwitchView.delegate = self;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL memoryLeakAlert = [userDefaults boolForKey:kDoraemonMemoryLeakAlertKey];
        [_alertSwitchView renderUIWithTitle:@"弹框提醒开关" switchOn:memoryLeakAlert];
        [_alertSwitchView needDownLine];
    }
    return _alertSwitchView;
}

@end
