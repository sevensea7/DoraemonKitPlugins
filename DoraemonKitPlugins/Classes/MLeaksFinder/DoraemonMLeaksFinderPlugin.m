//
//  DoraemonMLeaksFinderPlugin.m
//  WMDoraemonKitPlugins
//
//  Created by sevensea996 on 2022/2/17.
//

#import "DoraemonMLeaksFinderPlugin.h"
#import <DoraemonKit/DoraemonHomeWindow.h>

#import "DoraemonMLeaksFinderViewController.h"

@implementation DoraemonMLeaksFinderPlugin

- (void)pluginDidLoad {
    DoraemonMLeaksFinderViewController *vc = [DoraemonMLeaksFinderViewController new];
    [DoraemonHomeWindow openPlugin:vc];
}

@end
