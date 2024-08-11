//
//  DoraemonNetworkTransaction.m
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/15.
//

#if DEBUG

#import "DoraemonNetworkTransaction.h"

@interface DoraemonNetworkTransaction ()

@property (nonatomic, readwrite) NSData *cachedRequestBody;

@end

@implementation DoraemonNetworkTransaction

- (NSString *)description {
    NSString *description = [super description];

    description = [description stringByAppendingFormat:@" id = %@;", self.requestID];
    description = [description stringByAppendingFormat:@" url = %@;", self.request.URL];
    description = [description stringByAppendingFormat:@" duration = %f;", self.duration];
    description = [description stringByAppendingFormat:@" receivedDataLength = %lld", self.receivedDataLength];

    return description;
}

- (NSData *)cachedRequestBody {
    if (!_cachedRequestBody) {
        if (self.request.HTTPBody != nil) {
            _cachedRequestBody = self.request.HTTPBody;
        } else if ([self.request.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
            NSInputStream *bodyStream = [self.request.HTTPBodyStream copy];
            const NSUInteger bufferSize = 1024;
            uint8_t buffer[bufferSize];
            NSMutableData *data = [NSMutableData new];
            [bodyStream open];
            NSInteger readBytes = 0;
            do {
                readBytes = [bodyStream read:buffer maxLength:bufferSize];
                [data appendBytes:buffer length:readBytes];
            } while (readBytes > 0);
            [bodyStream close];
            _cachedRequestBody = data;
        }
    }
    return _cachedRequestBody;
}

+ (NSString *)readableStringFromTransactionState:(NetworkTransactionState)state {
    NSString *readableString = nil;
    switch (state) {
        case NetworkTransactionStateUnstarted:
            readableString = @"Unstarted";
            break;

        case NetworkTransactionStateAwaitingResponse:
            readableString = @"Awaiting Response";
            break;

        case NetworkTransactionStateReceivingData:
            readableString = @"Receiving Data";
            break;

        case NetworkTransactionStateFinished:
            readableString = @"Finished";
            break;

        case NetworkTransactionStateFailed:
            readableString = @"Failed";
            break;
    }
    return readableString;
}

@end

@implementation NetworkDetailRow

@end

@implementation NetworkDetailSection

@end

#endif
