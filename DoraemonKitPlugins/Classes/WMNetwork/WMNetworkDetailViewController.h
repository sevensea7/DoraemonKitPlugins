//
//  WMNetworkDetailViewController.h
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/18.
//  Copyright © 2021 Choice. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WMNetworkTransaction;

NS_ASSUME_NONNULL_BEGIN

@interface WMNetworkDetailViewController : UIViewController
@property (nonatomic) WMNetworkTransaction *transaction;
@end

NS_ASSUME_NONNULL_END
