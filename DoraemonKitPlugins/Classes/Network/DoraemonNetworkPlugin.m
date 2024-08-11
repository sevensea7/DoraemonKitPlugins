//
//  DoraemonNetworkPlugin.m
//  DoraemonKitPlugins
//
//  Created by 七海 on 2024/8/11.
//

#ifdef DEBUG

#import "DoraemonNetworkPlugin.h"
#import <DoraemonKit/DoraemonManager.h>
#import <DoraemonKit/DoraemonHomeWindow.h>
#import "DoraemonNetworkListController.h"

@implementation DoraemonNetworkPlugin

- (void)pluginDidLoad {
    DoraemonNetworkListController *vc = [[DoraemonNetworkListController alloc] init];
    [DoraemonHomeWindow openPlugin:vc];
}

@end

#endif
