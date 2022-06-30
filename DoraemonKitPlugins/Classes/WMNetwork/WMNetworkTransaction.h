//
//  WMNetworkTransaction.h
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/15.
//  Copyright © 2021 Choice. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WMNetworkTransactionState) {
    WMNetworkTransactionStateUnstarted,
    WMNetworkTransactionStateAwaitingResponse,
    WMNetworkTransactionStateReceivingData,
    WMNetworkTransactionStateFinished,
    WMNetworkTransactionStateFailed
};

NS_ASSUME_NONNULL_BEGIN


@interface WMNetworkTransaction : NSObject

@property (nonatomic, copy) NSString *requestID;

@property (nonatomic) NSURLRequest *request;
@property (nonatomic) NSURLResponse *response;
@property (nonatomic, copy) NSString *requestMechanism;
@property (nonatomic) WMNetworkTransactionState transactionState;
@property (nonatomic) NSError *error;

@property (nonatomic) NSDate *startTime;
@property (nonatomic) NSTimeInterval latency;
@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) int64_t receivedDataLength;

/// Populated lazily. Handles both normal HTTPBody data and HTTPBodyStreams.
@property (nonatomic, readonly) NSData *cachedRequestBody;

+ (NSString *)readableStringFromTransactionState:(WMNetworkTransactionState)state;


@end


typedef UIViewController *_Nullable(^WMNetworkDetailRowSelectionFuture)(void);

@interface WMNetworkDetailRow : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, copy) WMNetworkDetailRowSelectionFuture selectionFuture;

@end


@interface WMNetworkDetailSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<WMNetworkDetailRow *> *rows;

@end


NS_ASSUME_NONNULL_END
