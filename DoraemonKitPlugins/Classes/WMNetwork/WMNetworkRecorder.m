//
//  WMNetworkRecorder.m
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/15.
//  Copyright © 2021 Choice. All rights reserved.
//

#import "WMNetworkRecorder.h"
#import "WMNetworkUtility.h"
#import "WMNetworkTransaction.h"

NSString *const kNetworkRecorderNewTransactionNotification = @"kNetworkRecorderNewTransactionNotification";
NSString *const kNetworkRecorderTransactionUpdatedNotification = @"kNetworkRecorderTransactionUpdatedNotification";
NSString *const kNetworkRecorderUserInfoTransactionKey = @"transaction";
NSString *const kNetworkRecorderTransactionsClearedNotification = @"kNetworkRecorderTransactionsClearedNotification";
NSString *const kNetworkRecorderResponseCacheLimitDefaultsKey = @"com.wm.responseCacheLimit";

@interface WMNetworkRecorder ()

@property (nonatomic) NSCache *responseCache;
@property (nonatomic) NSMutableArray<WMNetworkTransaction *> *orderedTransactions;
@property (nonatomic) NSMutableDictionary<NSString *, WMNetworkTransaction *> *requestIDsToTransactions;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation WMNetworkRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.responseCache = [NSCache new];
        NSUInteger responseCacheLimit = [[NSUserDefaults.standardUserDefaults objectForKey:kNetworkRecorderResponseCacheLimitDefaultsKey] unsignedIntegerValue];
        
        // Default to 50 MB max. The cache will purge earlier if there is memory pressure.
        self.responseCache.totalCostLimit = responseCacheLimit ?: 50 * 1024 * 1024;
        [self.responseCache setTotalCostLimit:responseCacheLimit];
        
        self.orderedTransactions = [NSMutableArray new];
        self.requestIDsToTransactions = [NSMutableDictionary new];
        self.hostDenylist = NSUserDefaults.standardUserDefaults.wm_networkHostDenylist.mutableCopy;

        // Serial queue used because we use mutable objects that are not thread safe
        self.queue = dispatch_queue_create("com.wm.networkRecorder", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

+ (instancetype)defaultRecorder {
    static WMNetworkRecorder *defaultRecorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [self new];
    });
    
    return defaultRecorder;
}

#pragma mark - Public Data Access

- (NSUInteger)responseCacheByteLimit {
    return self.responseCache.totalCostLimit;
}

- (void)setResponseCacheByteLimit:(NSUInteger)responseCacheByteLimit {
    self.responseCache.totalCostLimit = responseCacheByteLimit;
    [NSUserDefaults.standardUserDefaults
        setObject:@(responseCacheByteLimit)
        forKey:kNetworkRecorderResponseCacheLimitDefaultsKey
    ];
}

- (NSArray<WMNetworkTransaction *> *)networkTransactions {
    __block NSArray<WMNetworkTransaction *> *transactions = nil;
    dispatch_sync(self.queue, ^{
        transactions = self.orderedTransactions.copy;
    });
    return transactions;
}

- (NSData *)cachedResponseBodyForTransaction:(WMNetworkTransaction *)transaction {
    return [self.responseCache objectForKey:transaction.requestID];
}

- (void)clearRecordedActivity {
    dispatch_async(self.queue, ^{
        [self.responseCache removeAllObjects];
        [self.orderedTransactions removeAllObjects];
        [self.requestIDsToTransactions removeAllObjects];
        
        [self notify:kNetworkRecorderTransactionsClearedNotification transaction:nil];
    });
}

- (void)clearExcludedTransactions {
    dispatch_sync(self.queue, ^{
        self.orderedTransactions = ({
            [self.orderedTransactions wm_filtered:^BOOL(WMNetworkTransaction *ta, NSUInteger idx) {
                NSString *host = ta.request.URL.host;
                for (NSString *excluded in self.hostDenylist) {
                    if ([host hasSuffix:excluded]) {
                        return NO;
                    }
                }
                
                return YES;
            }];
        });
    });
}

- (void)synchronizeDenylist {
    NSUserDefaults.standardUserDefaults.wm_networkHostDenylist = self.hostDenylist;
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse {
    // filter myweimai
    if (![request.URL.absoluteString containsString:@"myweimai"]) {
        return;
    }
    
    for (NSString *host in self.hostDenylist) {
        if ([request.URL.host hasSuffix:host]) {
            return;
        }
    }
    
    // Before async block to stay accurate
    NSDate *startDate = [NSDate date];

    if (redirectResponse) {
        [self recordResponseReceivedWithRequestID:requestID response:redirectResponse];
        [self recordLoadingFinishedWithRequestID:requestID responseBody:nil];
    }

    dispatch_async(self.queue, ^{
        WMNetworkTransaction *transaction = [WMNetworkTransaction new];
        transaction.requestID = requestID;
        transaction.request = request;
        transaction.startTime = startDate;

        [self.orderedTransactions insertObject:transaction atIndex:0];
        [self.requestIDsToTransactions setObject:transaction forKey:requestID];
        transaction.transactionState = WMNetworkTransactionStateAwaitingResponse;
        
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response {
    // Before async block to stay accurate
    NSDate *responseDate = [NSDate date];

    dispatch_async(self.queue, ^{
        WMNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.response = response;
        transaction.transactionState = WMNetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceDate:responseDate];

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength {
    dispatch_async(self.queue, ^{
        WMNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.receivedDataLength += dataLength;
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody {
    NSDate *finishedDate = [NSDate date];

    dispatch_async(self.queue, ^{
        WMNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.transactionState = WMNetworkTransactionStateFinished;
        transaction.duration = -[transaction.startTime timeIntervalSinceDate:finishedDate];

        BOOL shouldCache = responseBody.length > 0;
        if (!self.shouldCacheMediaResponses) {
            NSArray<NSString *> *ignoredMIMETypePrefixes = @[ @"audio", @"image", @"video" ];
            for (NSString *ignoredPrefix in ignoredMIMETypePrefixes) {
                shouldCache = shouldCache && ![transaction.response.MIMEType hasPrefix:ignoredPrefix];
            }
        }
        if (shouldCache) {
            [self.responseCache setObject:responseBody forKey:requestID cost:responseBody.length];
        }
        NSString *mimeType = transaction.response.MIMEType;
        if ([mimeType hasPrefix:@"image/"] && responseBody.length > 0) {
            return;
        }
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error {
    dispatch_async(self.queue, ^{
        WMNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.transactionState = WMNetworkTransactionStateFailed;
        transaction.duration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID {
    dispatch_async(self.queue, ^{
        WMNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.requestMechanism = mechanism;
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark Notification Posting

- (void)postNewTransactionNotificationWithTransaction:(WMNetworkTransaction *)transaction {
    [self notify:kNetworkRecorderNewTransactionNotification transaction:transaction];
}

- (void)postUpdateNotificationForTransaction:(WMNetworkTransaction *)transaction {
    [self notify:kNetworkRecorderTransactionUpdatedNotification transaction:transaction];
}

- (void)notify:(NSString *)name transaction:(WMNetworkTransaction *)transaction {
    NSDictionary *userInfo = nil;
    if (transaction) {
        userInfo = @{ kNetworkRecorderUserInfoTransactionKey : transaction };
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self userInfo:userInfo];
    });
}


@end
