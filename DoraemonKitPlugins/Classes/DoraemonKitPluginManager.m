//
//  DoraemonKitPluginManager.m
//  DoraemonKitPlugins
//
//  Created by sevensea7 on 2022/2/17.
//

#import "DoraemonKitPluginManager.h"
#import <DoraemonKit/DoraemonManager.h>
#import "DoraemonNetworkObserver.h"

@implementation DoraemonKitPluginManager

+ (void)addCommonPlugins {
    DoraemonManager *doraemonManager = [DoraemonManager shareInstance];
    
    DoraemonNetworkObserver.enabled = true;
    [doraemonManager addPluginWithTitle:@"网络监测"
                                   icon:@"doraemon_net"
                                   desc:@"网络监测"
                             pluginName:@"DoraemonNetworkPlugin"
                               atModule:@"开发工具"];
    
}

@end
