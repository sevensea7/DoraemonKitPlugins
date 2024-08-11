//
//  DoraemonNetworkRecorder.m
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/15.
//

#if DEBUG

#import "DoraemonNetworkRecorder.h"
#import "DoraemonNetworkUtility.h"
#import "DoraemonNetworkTransaction.h"
#import "OSCache.h"

NSString *const kNetworkRecorderNewTransactionNotification = @"kNetworkRecorderNewTransactionNotification";
NSString *const kNetworkRecorderTransactionUpdatedNotification = @"kNetworkRecorderTransactionUpdatedNotification";
NSString *const kNetworkRecorderUserInfoTransactionKey = @"transaction";
NSString *const kNetworkRecorderTransactionsClearedNotification = @"kNetworkRecorderTransactionsClearedNotification";
NSString *const kNetworkRecorderResponseCacheLimitDefaultsKey = @"com.responseCacheLimit";

@interface DoraemonNetworkRecorder ()

@property (nonatomic) OSCache *restCache;
@property (nonatomic) NSMutableArray<DoraemonNetworkTransaction *> *orderedTransactions;
@property (nonatomic) NSMutableDictionary<NSString *, DoraemonNetworkTransaction *> *requestIDsToTransactions;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation DoraemonNetworkRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.restCache = [OSCache new];
        NSUInteger responseCacheLimit = [[NSUserDefaults.standardUserDefaults
            objectForKey:kNetworkRecorderResponseCacheLimitDefaultsKey] unsignedIntegerValue];
        
        // Default to 100 MB max. The cache will purge earlier if there is memory pressure.
        self.restCache.totalCostLimit = responseCacheLimit ?: 100 * 1024 * 1024;
        [self.restCache setTotalCostLimit:responseCacheLimit];
        
        self.orderedTransactions = [NSMutableArray new];
        self.requestIDsToTransactions = [NSMutableDictionary new];
        self.hostDenylist = NSUserDefaults.standardUserDefaults._networkHostDenylist.mutableCopy;
//        [self.hostDenylist addObject:@"umeng.com"];
//        [self.hostDenylist addObject:@"umengcloud.com"];
//        [self.hostDenylist addObject:@"dokit.cn"];
//        [self.hostDenylist addObject:@"qq.com"];
//        [self.hostDenylist addObject:@"taobao.com"];
//        [self.hostDenylist addObject:@"aliyuncs.com"];

        // Serial queue used because we use mutable objects that are not thread safe
        self.queue = dispatch_queue_create("com.network.recorder", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

+ (instancetype)defaultRecorder {
    static DoraemonNetworkRecorder *defaultRecorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [self new];
    });
    
    return defaultRecorder;
}

#pragma mark - Public Data Access

- (NSUInteger)responseCacheByteLimit {
    return self.restCache.totalCostLimit;
}

- (void)setResponseCacheByteLimit:(NSUInteger)responseCacheByteLimit {
    self.restCache.totalCostLimit = responseCacheByteLimit;
    [NSUserDefaults.standardUserDefaults
        setObject:@(responseCacheByteLimit)
        forKey:kNetworkRecorderResponseCacheLimitDefaultsKey
    ];
}

- (NSArray<DoraemonNetworkTransaction *> *)networkTransactions {
    __block NSArray<DoraemonNetworkTransaction *> *transactions = nil;
    dispatch_sync(self.queue, ^{
        transactions = self.orderedTransactions.copy;
    });
    return transactions;
}

- (NSData *)cachedResponseBodyForTransaction:(DoraemonNetworkTransaction *)transaction {
    return (NSData *)[self.restCache objectForKey:transaction.requestID];
}

- (void)clearRecordedActivity {
    dispatch_async(self.queue, ^{
        [self.restCache removeAllObjects];
        [self.orderedTransactions removeAllObjects];
        [self.requestIDsToTransactions removeAllObjects];
        
        [self notify:kNetworkRecorderTransactionsClearedNotification transaction:nil];
    });
}

- (void)clearExcludedTransactions {
    dispatch_sync(self.queue, ^{
        self.orderedTransactions = ({
            [self.orderedTransactions _filtered:^BOOL(DoraemonNetworkTransaction *ta, NSUInteger idx) {
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
    NSUserDefaults.standardUserDefaults._networkHostDenylist = self.hostDenylist;
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse {
    // filter xxxx
//    if ([request.URL.absoluteString containsString:@"xxxx"]) {
//        return;
//    }
    
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
        DoraemonNetworkTransaction *transaction = [DoraemonNetworkTransaction new];
        transaction.requestID = requestID;
        transaction.request = request;
        transaction.startTime = startDate;

        [self.orderedTransactions insertObject:transaction atIndex:0];
        [self.requestIDsToTransactions setObject:transaction forKey:requestID];
        transaction.transactionState = NetworkTransactionStateAwaitingResponse;
        
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response {
    // Before async block to stay accurate
    NSDate *responseDate = [NSDate date];

    dispatch_async(self.queue, ^{
        DoraemonNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.response = response;
        transaction.transactionState = NetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceDate:responseDate];

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength {
    dispatch_async(self.queue, ^{
        DoraemonNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
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
        DoraemonNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.transactionState = NetworkTransactionStateFinished;
        transaction.duration = -[transaction.startTime timeIntervalSinceDate:finishedDate];

        BOOL shouldCache = responseBody.length > 0;
        if (!self.shouldCacheMediaResponses) {
            NSArray<NSString *> *ignoredMIMETypePrefixes = @[ @"audio", @"image", @"video" ];
            for (NSString *ignoredPrefix in ignoredMIMETypePrefixes) {
                shouldCache = shouldCache && ![transaction.response.MIMEType hasPrefix:ignoredPrefix];
            }
        }
        if (shouldCache) {
            [self.restCache setObject:responseBody forKey:requestID cost:responseBody.length];
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
        DoraemonNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.transactionState = NetworkTransactionStateFailed;
        transaction.duration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID {
    dispatch_async(self.queue, ^{
        DoraemonNetworkTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.requestMechanism = mechanism;
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark Notification Posting

- (void)postNewTransactionNotificationWithTransaction:(DoraemonNetworkTransaction *)transaction {
    [self notify:kNetworkRecorderNewTransactionNotification transaction:transaction];
}

- (void)postUpdateNotificationForTransaction:(DoraemonNetworkTransaction *)transaction {
    [self notify:kNetworkRecorderTransactionUpdatedNotification transaction:transaction];
}

- (void)notify:(NSString *)name transaction:(DoraemonNetworkTransaction *)transaction {
    NSDictionary *userInfo = nil;
    if (transaction) {
        userInfo = @{ kNetworkRecorderUserInfoTransactionKey : transaction };
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self userInfo:userInfo];
    });
}


@end

#endif
