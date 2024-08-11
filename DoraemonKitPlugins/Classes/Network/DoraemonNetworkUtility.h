//
//  DoraemonNetworkUtility.h
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/15.
//

#if DEBUG

#import <Foundation/Foundation.h>

#define wmweakify(var) __weak __typeof(var) __weak__##var = var;

#define wmstrongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = __weak__##var; \
_Pragma("clang diagnostic pop")


NSArray<Class> * _Nullable GetAllSubclasses(_Nullable Class cls, BOOL includeSelf);

NS_ASSUME_NONNULL_BEGIN

@interface DoraemonNetworkUtility : NSObject

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

@end


@interface NSArray<T> (Network)

/// Actually more like flatmap, but it seems like the objc way to allow returning nil to omit objects.
/// So, return nil from the block to omit objects, and return an object to include it in the new array.
/// Unlike flatmap, however, this will not flatten arrays of arrays into a single array.
- (__kindof NSArray *)_mapped:(id(^)(T obj, NSUInteger idx))mapFunc;
/// Like flex_mapped, but expects arrays to be returned, and flattens them into one array.
- (__kindof NSArray *)_flatmapped:(NSArray *(^)(id, NSUInteger idx))block;
- (instancetype)_filtered:(BOOL(^)(T obj, NSUInteger idx))filterFunc;
- (void)_forEach:(void(^)(T obj, NSUInteger idx))block;

@end


@interface NSUserDefaults (Network)

// Not actually stored in defaults, but written to a file
@property (nonatomic) NSArray<NSString *> *_networkHostDenylist;

@end

NS_ASSUME_NONNULL_END

#endif
