//
//  WMDoraemonNetworkPlugin.m
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/13.
//  Copyright © 2021 Choice. All rights reserved.
//

#ifdef DEBUG

#import "WMDoraemonNetworkPlugin.h"
#import <DoraemonKit/DoraemonManager.h>
#import <DoraemonKit/DoraemonHomeWindow.h>
#import "WMNetworkListViewController.h"

@implementation WMDoraemonNetworkPlugin

- (void)pluginDidLoad {
    WMNetworkListViewController *vc = [[WMNetworkListViewController alloc] init];
    [DoraemonHomeWindow openPlugin:vc];
}

@end

#endif
