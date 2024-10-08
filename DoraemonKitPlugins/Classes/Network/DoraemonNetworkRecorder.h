//
//  DoraemonNetworkRecorder.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/15.
//

#if DEBUG

#import <Foundation/Foundation.h>

// Notifications posted when the record is updated
extern NSString *const kNetworkRecorderNewTransactionNotification;
extern NSString *const kNetworkRecorderTransactionUpdatedNotification;
extern NSString *const kNetworkRecorderUserInfoTransactionKey;
extern NSString *const kNetworkRecorderTransactionsClearedNotification;

@class DoraemonNetworkTransaction;

@interface DoraemonNetworkRecorder : NSObject

/// In general, it only makes sense to have one recorder for the entire application.
@property (nonatomic, readonly, class) DoraemonNetworkRecorder *defaultRecorder;

/// Defaults to 25 MB if never set. Values set here are persisted across launches of the app.
@property (nonatomic) NSUInteger responseCacheByteLimit;

/// If NO, the recorder not cache will not cache response for content types
/// with an "image", "video", or "audio" prefix.
@property (nonatomic) BOOL shouldCacheMediaResponses;

@property (nonatomic) NSMutableArray<NSString *> *hostDenylist;

/// Call this after adding to or setting the \c hostDenylist to remove excluded transactions
- (void)clearExcludedTransactions;

/// Call this to save the denylist to the disk to be loaded next time
- (void)synchronizeDenylist;


// Accessing recorded network activity

/// Array of FLEXNetworkTransaction objects ordered by start time with the newest first.
- (NSArray<DoraemonNetworkTransaction *> *)networkTransactions;

/// The full response data IFF it hasn't been purged due to memory pressure.
- (NSData *)cachedResponseBodyForTransaction:(DoraemonNetworkTransaction *)transaction;

/// Dumps all network transactions and cached response bodies.
- (void)clearRecordedActivity;


// Recording network activity

/// Call when app is about to send HTTP request.
- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse;

/// Call when HTTP response is available.
- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response;

/// Call when data chunk is received over the network.
- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength;

/// Call when HTTP request has finished loading.
- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody;

/// Call when HTTP request has failed to load.
- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error;

/// Call to set the request mechanism anytime after recordRequestWillBeSent... has been called.
/// This string can be set to anything useful about the API used to make the request.
- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID;


@end

#endif
