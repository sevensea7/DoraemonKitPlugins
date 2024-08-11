//
//  DoraemonNetworkTransactionCell.m
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/18.
//

#if DEBUG

#import "DoraemonNetworkTransactionCell.h"
#import "DoraemonNetworkTransaction.h"
#import "DoraemonNetworkUtility.h"

@interface DoraemonNetworkTransactionCell ()
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *pathLabel;
@property (nonatomic) UILabel *transactionDetailsLabel;

@end

@implementation DoraemonNetworkTransactionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.nameLabel = [UILabel new];
        self.nameLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:self.nameLabel];

        self.pathLabel = [UILabel new];
        self.pathLabel.font = [UIFont systemFontOfSize:14];
        self.pathLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        [self.contentView addSubview:self.pathLabel];

        self.transactionDetailsLabel = [UILabel new];
        self.transactionDetailsLabel.font = [UIFont systemFontOfSize:11];
        self.transactionDetailsLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        [self.contentView addSubview:self.transactionDetailsLabel];
    }
    return self;
}

- (void)setTransaction:(DoraemonNetworkTransaction *)transaction {
    if (_transaction != transaction) {
        _transaction = transaction;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGFloat kVerticalPadding = 8.0;
    const CGFloat kLeftPadding = 10.0;

    CGFloat textOriginX = kLeftPadding;
    CGFloat availableTextWidth = self.contentView.bounds.size.width - textOriginX;

    self.nameLabel.text = [self nameLabelText];
    CGSize nameLabelPreferredSize = [self.nameLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    self.nameLabel.frame = CGRectMake(textOriginX, kVerticalPadding, availableTextWidth, nameLabelPreferredSize.height);
    self.nameLabel.textColor = (self.transaction.error || [DoraemonNetworkUtility isErrorStatusCodeFromURLResponse:self.transaction.response]) ? UIColor.redColor : UIColor.blackColor;

    self.pathLabel.text = [self pathLabelText];
    CGSize pathLabelPreferredSize = [self.pathLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat pathLabelOriginY = ceil((self.contentView.bounds.size.height - pathLabelPreferredSize.height) / 2.0);
    self.pathLabel.frame = CGRectMake(textOriginX, pathLabelOriginY, availableTextWidth, pathLabelPreferredSize.height);

    self.transactionDetailsLabel.text = [self transactionDetailsLabelText];
    CGSize transactionLabelPreferredSize = [self.transactionDetailsLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat transactionDetailsOriginX = textOriginX;
    CGFloat transactionDetailsLabelOriginY = CGRectGetMaxY(self.contentView.bounds) - kVerticalPadding - transactionLabelPreferredSize.height;
    CGFloat transactionDetailsLabelWidth = self.contentView.bounds.size.width - transactionDetailsOriginX;
    self.transactionDetailsLabel.frame = CGRectMake(transactionDetailsOriginX, transactionDetailsLabelOriginY, transactionDetailsLabelWidth, transactionLabelPreferredSize.height);
}

- (NSString *)nameLabelText {
    NSURL *url = self.transaction.request.URL;
    NSString *scheme = [url scheme];
    NSString *name = [url host];
    name = [NSString stringWithFormat:@"%@://%@", scheme, name];
    return name;
}

- (NSString *)pathLabelText {
    NSURL *url = self.transaction.request.URL;
    NSString *path = [url path];
    return path;
}

- (NSString *)transactionDetailsLabelText {
    NSMutableArray<NSString *> *detailComponents = [NSMutableArray new];

    NSString *timestamp = [[self class] timestampStringFromRequestDate:self.transaction.startTime];
    if (timestamp.length > 0) {
        [detailComponents addObject:timestamp];
    }

    // Omit method for GET (assumed as default)
    NSString *httpMethod = self.transaction.request.HTTPMethod;
    if (httpMethod.length > 0) {
        [detailComponents addObject:httpMethod];
    }

    if (self.transaction.transactionState == NetworkTransactionStateFinished || self.transaction.transactionState == NetworkTransactionStateFailed) {
        NSString *statusCodeString = [DoraemonNetworkUtility statusCodeStringFromURLResponse:self.transaction.response];
        if (statusCodeString.length > 0) {
            [detailComponents addObject:statusCodeString];
        }

        if (self.transaction.receivedDataLength > 0) {
            NSString *responseSize = [NSByteCountFormatter stringFromByteCount:self.transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
            [detailComponents addObject:responseSize];
        }

        NSString *totalDuration = [DoraemonNetworkUtility stringFromRequestDuration:self.transaction.duration];
        NSString *latency = [DoraemonNetworkUtility stringFromRequestDuration:self.transaction.latency];
        NSString *duration = [NSString stringWithFormat:@"%@ (%@)", totalDuration, latency];
        [detailComponents addObject:duration];
    } else {
        // Unstarted, Awaiting Response, Receiving Data, etc.
        NSString *state = [DoraemonNetworkTransaction readableStringFromTransactionState:self.transaction.transactionState];
        [detailComponents addObject:state];
    }

    return [detailComponents componentsJoinedByString:@" ・ "];
}

+ (NSString *)timestampStringFromRequestDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"HH:mm:ss";
    });
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)reuseId {
    return NSStringFromClass([self class]);
}

@end

#endif
