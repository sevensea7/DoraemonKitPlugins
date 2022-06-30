//
//  WMNetworkMultilineCell.h
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/22.
//  Copyright © 2021 Choice. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMNetworkMultilineCell : UITableViewCell

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

@interface WMNetworkMultilineDetailCell : WMNetworkMultilineCell

@end

NS_ASSUME_NONNULL_END
