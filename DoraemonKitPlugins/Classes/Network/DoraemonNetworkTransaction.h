//
//  DoraemonNetworkTransaction.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/15.
//

#if DEBUG

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NetworkTransactionState) {
    NetworkTransactionStateUnstarted,
    NetworkTransactionStateAwaitingResponse,
    NetworkTransactionStateReceivingData,
    NetworkTransactionStateFinished,
    NetworkTransactionStateFailed
};

NS_ASSUME_NONNULL_BEGIN


@interface DoraemonNetworkTransaction : NSObject

@property (nonatomic, copy) NSString *requestID;

@property (nonatomic) NSURLRequest *request;
@property (nonatomic) NSURLResponse *response;
@property (nonatomic, copy) NSString *requestMechanism;
@property (nonatomic) NetworkTransactionState transactionState;
@property (nonatomic) NSError *error;

@property (nonatomic) NSDate *startTime;
@property (nonatomic) NSTimeInterval latency;
@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) int64_t receivedDataLength;

/// Populated lazily. Handles both normal HTTPBody data and HTTPBodyStreams.
@property (nonatomic, readonly) NSData *cachedRequestBody;

+ (NSString *)readableStringFromTransactionState:(NetworkTransactionState)state;


@end


typedef UIViewController *_Nullable(^NetworkDetailRowSelectionFuture)(void);

@interface NetworkDetailRow : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, copy) NetworkDetailRowSelectionFuture selectionFuture;

@end


@interface NetworkDetailSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<NetworkDetailRow *> *rows;

@end


NS_ASSUME_NONNULL_END

#endif
