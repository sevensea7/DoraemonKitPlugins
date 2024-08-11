//
//  DoraemonNetworkObserver.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/15.
//

#if DEBUG

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const kNetworkObserverEnabledStateChangedNotification;

@interface DoraemonNetworkObserver : NSObject
// 是否启用
@property (nonatomic, class, getter=isEnabled) BOOL enabled;

@end

#endif
