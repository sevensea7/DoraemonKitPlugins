//
//  DoraemonNetworkDetailController.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/18.
//

#if DEBUG

#import <UIKit/UIKit.h>
@class DoraemonNetworkTransaction;

NS_ASSUME_NONNULL_BEGIN

@interface DoraemonNetworkDetailController : UIViewController
@property (nonatomic) DoraemonNetworkTransaction *transaction;
@end

NS_ASSUME_NONNULL_END

#endif
