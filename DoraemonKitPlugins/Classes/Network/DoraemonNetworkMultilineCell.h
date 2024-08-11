//
//  DoraemonNetworkMultilineCell.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/22.
//

#if DEBUG

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DoraemonNetworkMultilineCell : UITableViewCell

/// Use this instead of .textLabel
@property (nonatomic, readonly) UILabel *titleLabel;
/// Use this instead of .detailTextLabel
@property (nonatomic, readonly) UILabel *subtitleLabel;

/// Subclasses can override this instead of initializers to
/// perform additional initialization without lots of boilerplate.
/// Remember to call super!
- (void)postInit;

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText
                                    maxWidth:(CGFloat)contentViewWidth
                                       style:(UITableViewStyle)style
                              showsAccessory:(BOOL)showsAccessory;

+ (NSString *)reuseId;

@end

@interface NetworkMultilineDetailCell : DoraemonNetworkMultilineCell

@end

NS_ASSUME_NONNULL_END

#endif
