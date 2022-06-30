//
//  WMNetworkWebViewController.h
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/22.
//  Copyright © 2021 Choice. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMNetworkWebViewController : UIViewController

- (id)initWithURL:(NSURL *)url;
- (id)initWithText:(NSString *)text;

+ (BOOL)supportsPathExtension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END
