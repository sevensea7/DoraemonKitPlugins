//
//  WMNetworkTransaction.m
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/15.
//  Copyright © 2021 Choice. All rights reserved.
//

#import "WMNetworkTransaction.h"

@interface WMNetworkTransaction ()

@property (nonatomic, readwrite) NSData *cachedRequestBody;

@end

@implementation WMNetworkTransaction

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

+ (NSString *)readableStringFromTransactionState:(WMNetworkTransactionState)state {
    NSString *readableString = nil;
    switch (state) {
        case WMNetworkTransactionStateUnstarted:
            readableString = @"Unstarted";
            break;

        case WMNetworkTransactionStateAwaitingResponse:
            readableString = @"Awaiting Response";
            break;

        case WMNetworkTransactionStateReceivingData:
            readableString = @"Receiving Data";
            break;

        case WMNetworkTransactionStateFinished:
            readableString = @"Finished";
            break;

        case WMNetworkTransactionStateFailed:
            readableString = @"Failed";
            break;
    }
    return readableString;
}

@end

@implementation WMNetworkDetailRow

@end

@implementation WMNetworkDetailSection

@end
