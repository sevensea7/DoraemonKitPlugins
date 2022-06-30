//
//  WMNetworkObserver.h
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/15.
//  Copyright © 2021 Choice. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const kNetworkObserverEnabledStateChangedNotification;

@interface WMNetworkObserver : NSObject
// 是否启用
@property (nonatomic, class, getter=isEnabled) BOOL enabled;

@end

