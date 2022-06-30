//
//  WMNetworkUtility.h
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/15.
//  Copyright © 2021 Choice. All rights reserved.
//

#import <Foundation/Foundation.h>


#define weakify(var) __weak __typeof(var) __weak__##var = var;

#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = __weak__##var; \
_Pragma("clang diagnostic pop")


NSArray<Class> * _Nullable WMGetAllSubclasses(_Nullable Class cls, BOOL includeSelf);

NS_ASSUME_NONNULL_BEGIN

@interface WMNetworkUtility : NSObject

+ (NSString *)stringFromRequestDuration:(NSTimeInterval)duration;
+ (NSString *)statusCodeStringFromURLResponse:(NSURLResponse *)response;
+ (BOOL)isErrorStatusCodeFromURLResponse:(NSURLResponse *)response;
+ (NSArray<NSURLQueryItem *> *)itemsFromQueryString:(NSString *)query;
+ (NSString *)prettyJSONStringFromData:(NSData *)data;
+ (BOOL)isValidJSONData:(NSData *)data;
+ (NSData *)inflatedDataFromCompressedData:(NSData *)compressedData;
+ (NSString *)stringByEscapingHTMLEntitiesInString:(NSString *)originalString;

// Swizzling utilities
+ (SEL)swizzledSelectorForSelector:(SEL)selector;
+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls;
+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)class withBlock:(id)block swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock;

/**
 * Generates a cURL command equivalent to the given request.
 *
 * @param request The request to be translated
 */
+ (NSString *)curlCommandString:(NSURLRequest *)request;

+ (void)showHUDWithText:(NSString *)text;

@end


@interface NSArray<T> (Network)

/// Actually more like flatmap, but it seems like the objc way to allow returning nil to omit objects.
/// So, return nil from the block to omit objects, and return an object to include it in the new array.
/// Unlike flatmap, however, this will not flatten arrays of arrays into a single array.
- (__kindof NSArray *)wm_mapped:(id(^)(T obj, NSUInteger idx))mapFunc;
/// Like wm_mapped, but expects arrays to be returned, and flattens them into one array.
- (__kindof NSArray *)wm_flatmapped:(NSArray *(^)(id, NSUInteger idx))block;
- (instancetype)wm_filtered:(BOOL(^)(T obj, NSUInteger idx))filterFunc;
- (void)wm_forEach:(void(^)(T obj, NSUInteger idx))block;

@end


@interface NSUserDefaults (Network)

// Not actually stored in defaults, but written to a file
@property (nonatomic) NSArray<NSString *> *wm_networkHostDenylist;

@end

NS_ASSUME_NONNULL_END
