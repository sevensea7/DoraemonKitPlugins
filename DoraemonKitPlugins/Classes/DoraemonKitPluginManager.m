//
//  DoraemonKitPluginManager.m
//  WMDoraemonKitPlugins
//
//  Created by sevensea996 on 2022/2/17.
//

#import "DoraemonKitPluginManager.h"
#import <DoraemonKit/DoraemonManager.h>
#import <MLeaksFinder/NSObject+MemoryLeak.h>

@implementation DoraemonKitPluginManager

+ (void)addCommonPlugins {
    DoraemonManager *doraemonManager = [DoraemonManager shareInstance];
    
    [doraemonManager addPluginWithTitle:@"内存泄漏"
                                   icon:@"doraemon_memory_leak"
                                   desc:@"内存泄漏"
                             pluginName:@"DoraemonMLeaksFinderPlugin"
                               atModule:@"性能检测"];
    NSArray *mLeakClassNameArray = @[@"WMAssetsPicker"];
    [self addClassNamesToWhitelist:mLeakClassNameArray];
}

@end
