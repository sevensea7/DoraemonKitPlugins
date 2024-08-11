//
//  DoraemonNetworkDataWebView.m
//  ZZHLBidder
//
//  Created by 七海 on 2023/6/1.
//

#if DEBUG

#import "DoraemonNetworkDataWebView.h"
#import "DoraemonNetworkUtility.h"
#import <WebKit/WebKit.h>

@interface DoraemonNetworkDataWebView () <WKNavigationDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) NSString *originalText;

@end

@implementation DoraemonNetworkDataWebView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        if (@available(iOS 10.0, *)) {
            configuration.dataDetectorTypes = WKDataDetectorTypeLink;
        }

        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        self.webView.navigationDelegate = self;
        [self addSubview:self.webView];
        self.webView.frame = self.bounds;
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)showWithText:(NSString *)text {
    self.originalText = text;
    // white-space:normal/nowrap/pre/pre-wrap/pre-line/break-spaces
    NSString *htmlString = [NSString stringWithFormat:@"<head>\
                            <meta name='viewport' content='initial-scale=1.0'>\
                            </head>\
                            <body style='font-size:14px;'>\
                            <pre style='white-space:pre;'>%@</pre>\
                            </body>", [DoraemonNetworkUtility stringByEscapingHTMLEntitiesInString:text]];
    [self.webView loadHTMLString:htmlString baseURL:nil];
}

- (void)dealloc {
    // WKWebView's delegate is assigned so we need to clear it manually.
    if (_webView.navigationDelegate == self) {
        _webView.navigationDelegate = nil;
    }
}

#pragma mark - WKWebView Delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyCancel;
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        // Allow the initial load
        policy = WKNavigationActionPolicyAllow;
    } else {
        // For clicked links, push another web view controller onto the navigation stack so that hitting the back button works as expected.
        // Don't allow the current web view to handle the navigation.
    }
    decisionHandler(policy);
}


#pragma mark - Class Helpers

+ (BOOL)supportsPathExtension:(NSString *)extension {
    BOOL supported = NO;
    NSSet<NSString *> *supportedExtensions = [self webViewSupportedPathExtensions];
    if ([supportedExtensions containsObject:[extension lowercaseString]]) {
        supported = YES;
    }
    return supported;
}

+ (NSSet<NSString *> *)webViewSupportedPathExtensions {
    static NSSet<NSString *> *pathExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Note that this is not exhaustive, but all these extensions should work well in the web view.
        pathExtensions = [NSSet<NSString *> setWithArray:@[@"jpg", @"jpeg", @"png", @"gif", @"pdf", @"svg", @"tiff", @"3gp", @"3gpp", @"3g2",@"3gp2", @"aiff", @"aif", @"aifc", @"cdda", @"amr", @"mp3", @"swa", @"mp4", @"mpeg",@"mpg", @"mp3", @"wav", @"bwf", @"m4a", @"m4b", @"m4p", @"mov", @"qt", @"mqv", @"m4v"]];
    });
    return pathExtensions;
}



@end

#endif
