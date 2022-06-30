//
//  WMNetworkMultilineCell.m
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/22.
//  Copyright © 2021 Choice. All rights reserved.
//

#import "WMNetworkMultilineCell.h"

@interface WMNetworkMultilineCell ()
@property (nonatomic) BOOL constraintsUpdated;
@end

@implementation WMNetworkMultilineCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self postInit];
    }

    return self;
}

- (void)postInit {
    UIFont *cellFont = [UIFont systemFontOfSize:14];
    self.titleLabel.font = cellFont;
    self.subtitleLabel.font = cellFont;
    self.subtitleLabel.textColor = [UIColor lightGrayColor];
    
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.subtitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    self.titleLabel.numberOfLines = 0;
    self.subtitleLabel.numberOfLines = 0;
}

- (UILabel *)titleLabel {
    return self.textLabel;
}

- (UILabel *)subtitleLabel {
    return self.detailTextLabel;
}

+ (UIEdgeInsets)labelInsets {
    return UIEdgeInsetsMake(10.0, 16.0, 10.0, 8.0);
}

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText
                                    maxWidth:(CGFloat)contentViewWidth
                                       style:(UITableViewStyle)style
                              showsAccessory:(BOOL)showsAccessory {
    CGFloat labelWidth = contentViewWidth;

    // Content view inset due to accessory view observed on iOS 8.1 iPhone 6.
    if (showsAccessory) {
        labelWidth -= 34.0;
    }

    UIEdgeInsets labelInsets = [self labelInsets];
    labelWidth -= (labelInsets.left + labelInsets.right);

    CGSize constrainSize = CGSizeMake(labelWidth, CGFLOAT_MAX);
    CGRect boundingBox = [attributedText
        boundingRectWithSize:constrainSize
        options:NSStringDrawingUsesLineFragmentOrigin
        context:nil
    ];
    CGFloat preferredLabelHeight = floor(UIScreen.mainScreen.scale * (boundingBox.size.height)) / UIScreen.mainScreen.scale;
    CGFloat preferredCellHeight = preferredLabelHeight + labelInsets.top + labelInsets.bottom + 1.0;

    return preferredCellHeight;
}

+ (NSString *)reuseId {
    return NSStringFromClass([self class]);
}

@end

@implementation WMNetworkMultilineDetailCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

@end
