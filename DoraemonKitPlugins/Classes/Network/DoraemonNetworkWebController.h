//
//  DoraemonNetworkWebController.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/22.
//

#if DEBUG

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DoraemonNetworkWebController : UIViewController

- (id)initWithURL:(NSURL *)url;
- (id)initWithText:(NSString *)text;

+ (BOOL)supportsPathExtension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END

#endif
