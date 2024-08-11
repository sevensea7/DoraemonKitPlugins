//
//  DoraemonNetworkTransactionCell.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/18.
//

#if DEBUG

#import <UIKit/UIKit.h>
@class DoraemonNetworkTransaction;

NS_ASSUME_NONNULL_BEGIN

@interface DoraemonNetworkTransactionCell : UITableViewCell

@property (nonatomic) DoraemonNetworkTransaction *transaction;

+ (NSString *)reuseId;

@end

NS_ASSUME_NONNULL_END

#endif
