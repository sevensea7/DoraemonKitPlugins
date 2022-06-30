//
//  WMNetworkDetailViewController.m
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/18.
//  Copyright © 2021 Choice. All rights reserved.
//

#import "WMNetworkDetailViewController.h"
#import "WMNetworkRecorder.h"
#import "WMNetworkUtility.h"
#import "WMNetworkTransaction.h"
#import "WMNetworkMultilineCell.h"
#import "WMNetworkWebViewController.h"

CGFloat const kNavigationHeight = 44.f;
CGFloat const kSegmentHeight = 40.f;


@interface WMNetworkDetailViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<WMNetworkDetailSection *> *sections;
@property (nonatomic, strong) UIViewController *bodyDetails;

@end

@implementation WMNetworkDetailViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = UIColor.whiteColor;
        [NSNotificationCenter.defaultCenter addObserver:self
            selector:@selector(handleTransactionUpdatedNotification:)
            name:kNetworkRecorderTransactionUpdatedNotification
            object:nil
        ];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithTitle:@"CURL" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightBtn;
    
    NSArray *scopeTitles = @[@"ALL", @"HEADER", @"PARAM", @"BODY"];
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:scopeTitles];
    segment.frame = CGRectMake(20, [UIApplication sharedApplication].statusBarFrame.size.height + kNavigationHeight + 10, self.view.frame.size.width - 40, kSegmentHeight);
    segment.selectedSegmentIndex = 0;
    [segment addTarget:self action:@selector(handleValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segment];
    
    self.tableView.frame = CGRectMake(0, segment.frame.origin.y + kSegmentHeight + 10, self.view.frame.size.width, self.view.frame.size.height - segment.frame.origin.y - kSegmentHeight - 10);
    [self.view addSubview:self.tableView];
}

- (void)copyButtonPressed:(id)sender {
    [UIPasteboard.generalPasteboard setString:[WMNetworkUtility curlCommandString:self.transaction.request]];
    [WMNetworkUtility showHUDWithText:@"复制成功"];
}

- (void)handleValueChanged:(UISegmentedControl *)sender {
    // body
    if (sender.selectedSegmentIndex == 3) {
        
        NSData *responseData = [WMNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:self.transaction];
        NSString *contentType = self.transaction.response.MIMEType;
        
        if ([contentType hasPrefix:@"image/"]) {
            self.bodyDetails = [[WMNetworkWebViewController alloc] initWithURL:self.transaction.request.URL];

        } else {
            self.bodyDetails = [WMNetworkDetailViewController detailViewControllerForMIMEType:contentType data:responseData];
            
        }
        
        [self addChildViewController:self.bodyDetails];
        [self.view addSubview:self.bodyDetails.view];
        [self.bodyDetails didMoveToParentViewController:self];
        self.bodyDetails.view.frame = self.tableView.frame;
        
    } else {
        if (self.bodyDetails) {
            [self.bodyDetails willMoveToParentViewController:nil];
            [self.bodyDetails removeFromParentViewController];
            [self.bodyDetails.view removeFromSuperview];
        }

        if (sender.selectedSegmentIndex == 0) {
            [self rebuildTableSections];
            
        } else if (sender.selectedSegmentIndex == 1) {
            NSMutableArray<WMNetworkDetailSection *> *sections = [NSMutableArray new];
            
            WMNetworkDetailSection *requestHeadersSection = [[self class] requestHeadersSectionForTransaction:self.transaction];
            if (requestHeadersSection.rows.count > 0) {
                [sections addObject:requestHeadersSection];
            }
            self.sections = sections;
            
        } else if (sender.selectedSegmentIndex == 2) {
            NSMutableArray<WMNetworkDetailSection *> *sections = [NSMutableArray new];

            WMNetworkDetailSection *queryParametersSection = [[self class] queryParametersSectionForTransaction:self.transaction];
            if (queryParametersSection.rows.count > 0) {
                [sections addObject:queryParametersSection];
            }
            self.sections = sections;

        }
    }
}

- (void)setTransaction:(WMNetworkTransaction *)transaction {
    if (![_transaction isEqual:transaction]) {
        _transaction = transaction;
        self.title = [transaction.request.URL lastPathComponent];
        [self rebuildTableSections];
    }
}

- (void)setSections:(NSArray<WMNetworkDetailSection *> *)sections {
    if (![_sections isEqual:sections]) {
        _sections = [sections copy];
        [self.tableView reloadData];
    }
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification {
    WMNetworkTransaction *transaction = [[notification userInfo] objectForKey:kNetworkRecorderUserInfoTransactionKey];
    if (transaction == self.transaction) {
        [self rebuildTableSections];
    }
}

- (void)rebuildTableSections {
    NSMutableArray<WMNetworkDetailSection *> *sections = [NSMutableArray new];

    WMNetworkDetailSection *generalSection = [[self class] generalSectionForTransaction:self.transaction];
    if (generalSection.rows.count > 0) {
        [sections addObject:generalSection];
    }
    WMNetworkDetailSection *queryParametersSection = [[self class] queryParametersSectionForTransaction:self.transaction];
    if (queryParametersSection.rows.count > 0) {
        [sections addObject:queryParametersSection];
    }
    WMNetworkDetailSection *postBodySection = [[self class] postBodySectionForTransaction:self.transaction];
    if (postBodySection.rows.count > 0) {
        [sections addObject:postBodySection];
    }
    WMNetworkDetailSection *requestHeadersSection = [[self class] requestHeadersSectionForTransaction:self.transaction];
    if (requestHeadersSection.rows.count > 0) {
        [sections addObject:requestHeadersSection];
    }
    WMNetworkDetailSection *responseHeadersSection = [[self class] responseHeadersSectionForTransaction:self.transaction];
    if (responseHeadersSection.rows.count > 0) {
        [sections addObject:responseHeadersSection];
    }

    self.sections = sections;
}


#pragma mark - Table view Init

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.sectionHeaderHeight = 40;
        _tableView.sectionFooterHeight = 0;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:[WMNetworkMultilineCell class] forCellReuseIdentifier:WMNetworkMultilineCell.reuseId];
    }
    return _tableView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    WMNetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    WMNetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMNetworkMultilineCell *cell = [tableView dequeueReusableCellWithIdentifier:WMNetworkMultilineCell.reuseId forIndexPath:indexPath];
    WMNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];
    cell.textLabel.attributedText = [[self class] attributedTextForRow:rowModel];
    cell.accessoryType = rowModel.selectionFuture ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = rowModel.selectionFuture ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WMNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

    UIViewController *viewController = nil;
    if (rowModel.selectionFuture) {
        viewController = rowModel.selectionFuture();
    }

    if ([viewController isKindOfClass:UIAlertController.class]) {
        [self presentViewController:viewController animated:YES completion:nil];
    } else if (viewController) {
        [self.navigationController pushViewController:viewController animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
    NSAttributedString *attributedText = [[self class] attributedTextForRow:row];
    BOOL showsAccessory = row.selectionFuture != nil;
    return [WMNetworkMultilineCell
        preferredHeightWithAttributedText:attributedText
        maxWidth:tableView.bounds.size.width
        style:tableView.style
        showsAccessory:showsAccessory
    ];
}

- (WMNetworkDetailRow *)rowModelAtIndexPath:(NSIndexPath *)indexPath {
    WMNetworkDetailSection *sectionModel = self.sections[indexPath.section];
    return sectionModel.rows[indexPath.row];
}

#pragma mark - Cell Copying

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        WMNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
        UIPasteboard.generalPasteboard.string = row.detailText;
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point __IOS_AVAILABLE(13.0) {
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
        previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UIAction *copy = [UIAction
                actionWithTitle:@"复制"
                image:nil
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    WMNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
                    if (row.selectionFuture) {
                        NSData *responseData = [WMNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:self.transaction];
                        if ([WMNetworkUtility isValidJSONData:responseData]) {
                            NSString *text = [WMNetworkUtility prettyJSONStringFromData:responseData];
                            UIPasteboard.generalPasteboard.string = text;
                        } else {
                            NSString *text = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                            UIPasteboard.generalPasteboard.string = text;
                        }
                    } else {
                        UIPasteboard.generalPasteboard.string = row.detailText;
                    }
                    [WMNetworkUtility showHUDWithText:@"复制成功"];
                }
            ];
            return [UIMenu
                menuWithTitle:@"" image:nil identifier:nil
                options:UIMenuOptionsDisplayInline
                children:@[copy]
            ];
        }
    ];
}

#pragma mark - View Configuration

+ (NSAttributedString *)attributedTextForRow:(WMNetworkDetailRow *)row {
    NSDictionary<NSString *, id> *titleAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0],
                                                       NSForegroundColorAttributeName : [UIColor colorWithWhite:0.5 alpha:1.0] };
    NSDictionary<NSString *, id> *detailAttributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:14],
                                                        NSForegroundColorAttributeName : [UIColor blackColor] };

    NSString *title = [NSString stringWithFormat:@"%@: ", row.title];
    NSString *detailText = row.detailText ?: @"";
    NSMutableAttributedString *attributedText = [NSMutableAttributedString new];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttributes]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:detailText attributes:detailAttributes]];

    return attributedText;
}

#pragma mark - Table Data Generation

+ (WMNetworkDetailSection *)generalSectionForTransaction:(WMNetworkTransaction *)transaction {
    NSMutableArray<WMNetworkDetailRow *> *rows = [NSMutableArray new];

    WMNetworkDetailRow *requestURLRow = [WMNetworkDetailRow new];
    requestURLRow.title = @"Request URL";
    NSURL *url = transaction.request.URL;
    requestURLRow.detailText = url.absoluteString;
//    requestURLRow.selectionFuture = ^{
//        UIViewController *urlWebViewController = [[WMNetworkWebViewController alloc] initWithURL:url];
//        urlWebViewController.title = url.absoluteString;
//        return urlWebViewController;
//    };
    [rows addObject:requestURLRow];

    WMNetworkDetailRow *requestMethodRow = [WMNetworkDetailRow new];
    requestMethodRow.title = @"Request Method";
    requestMethodRow.detailText = transaction.request.HTTPMethod;
    [rows addObject:requestMethodRow];

    if (transaction.cachedRequestBody.length > 0) {
        WMNetworkDetailRow *postBodySizeRow = [WMNetworkDetailRow new];
        postBodySizeRow.title = @"Request Body Size";
        postBodySizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.cachedRequestBody.length countStyle:NSByteCountFormatterCountStyleBinary];
        [rows addObject:postBodySizeRow];

        WMNetworkDetailRow *postBodyRow = [WMNetworkDetailRow new];
        postBodyRow.title = @"Request Body";
        postBodyRow.detailText = @"点击查看";
        postBodyRow.selectionFuture = ^UIViewController * () {
            // Show the body if we can
            NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
            UIViewController *detailViewController = [self detailViewControllerForMIMEType:contentType data:[self postBodyDataForTransaction:transaction]];
            if (detailViewController) {
                detailViewController.title = @"Request Body";
                return detailViewController;
            }
            // We can't show the body, alert user
            return [self makeAlertWithTitle:@"无法查看Body数据" message:[NSString stringWithFormat:@"没有%@类型的Body数据", contentType] button:@"确定"];
        };

        [rows addObject:postBodyRow];
    }

    NSString *statusCodeString = [WMNetworkUtility statusCodeStringFromURLResponse:transaction.response];
    if (statusCodeString.length > 0) {
        WMNetworkDetailRow *statusCodeRow = [WMNetworkDetailRow new];
        statusCodeRow.title = @"Status Code";
        statusCodeRow.detailText = statusCodeString;
        [rows addObject:statusCodeRow];
    }

    if (transaction.error) {
        WMNetworkDetailRow *errorRow = [WMNetworkDetailRow new];
        errorRow.title = @"Error";
        errorRow.detailText = transaction.error.localizedDescription;
        [rows addObject:errorRow];
    }

    WMNetworkDetailRow *responseBodyRow = [WMNetworkDetailRow new];
    responseBodyRow.title = @"Response Body";
    NSData *responseData = [WMNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
    if (responseData.length > 0) {
        responseBodyRow.detailText = @"点击查看";
        // Avoid a long lived strong reference to the response data in case we need to purge it from the cache.
        weakify(responseData)
        responseBodyRow.selectionFuture = ^UIViewController *() { strongify(responseData)
            
            // Show the response if we can
            NSString *contentType = transaction.response.MIMEType;
            if (responseData) {
                UIViewController *bodyDetails = [self detailViewControllerForMIMEType:contentType data:responseData];
                if (bodyDetails) {
                    bodyDetails.title = @"Response";
                    return bodyDetails;
                }
            }

            // We can't show the response, alert user
            return [self makeAlertWithTitle:@"无法查看Response数据" message:responseData ? [NSString stringWithFormat:@"没有%@类型的Response数据", contentType] : @"Response已从缓存中清除"  button:@"确定"];

        };
    } else {
        BOOL emptyResponse = transaction.receivedDataLength == 0;
        responseBodyRow.detailText = emptyResponse ? @"空" : @"无缓存";
    }

    [rows addObject:responseBodyRow];

    WMNetworkDetailRow *responseSizeRow = [WMNetworkDetailRow new];
    responseSizeRow.title = @"Response Size";
    responseSizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
    [rows addObject:responseSizeRow];

    WMNetworkDetailRow *mimeTypeRow = [WMNetworkDetailRow new];
    mimeTypeRow.title = @"MIME Type";
    mimeTypeRow.detailText = transaction.response.MIMEType;
    [rows addObject:mimeTypeRow];

    WMNetworkDetailRow *mechanismRow = [WMNetworkDetailRow new];
    mechanismRow.title = @"Mechanism";
    mechanismRow.detailText = transaction.requestMechanism;
    [rows addObject:mechanismRow];

    NSDateFormatter *startTimeFormatter = [NSDateFormatter new];
    startTimeFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";

    WMNetworkDetailRow *localStartTimeRow = [WMNetworkDetailRow new];
    localStartTimeRow.title = [NSString stringWithFormat:@"Start Time (%@)", [NSTimeZone.localTimeZone abbreviationForDate:transaction.startTime]];
    localStartTimeRow.detailText = [startTimeFormatter stringFromDate:transaction.startTime];
    [rows addObject:localStartTimeRow];

    startTimeFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

    WMNetworkDetailRow *utcStartTimeRow = [WMNetworkDetailRow new];
    utcStartTimeRow.title = @"Start Time (UTC)";
    utcStartTimeRow.detailText = [startTimeFormatter stringFromDate:transaction.startTime];
    [rows addObject:utcStartTimeRow];

    WMNetworkDetailRow *unixStartTime = [WMNetworkDetailRow new];
    unixStartTime.title = @"Unix Start Time";
    unixStartTime.detailText = [NSString stringWithFormat:@"%f", [transaction.startTime timeIntervalSince1970]];
    [rows addObject:unixStartTime];

    WMNetworkDetailRow *durationRow = [WMNetworkDetailRow new];
    durationRow.title = @"Total Duration";
    durationRow.detailText = [WMNetworkUtility stringFromRequestDuration:transaction.duration];
    [rows addObject:durationRow];

    WMNetworkDetailRow *latencyRow = [WMNetworkDetailRow new];
    latencyRow.title = @"Latency";
    latencyRow.detailText = [WMNetworkUtility stringFromRequestDuration:transaction.latency];
    [rows addObject:latencyRow];

    WMNetworkDetailSection *generalSection = [WMNetworkDetailSection new];
    generalSection.title = @"General";
    generalSection.rows = rows;

    return generalSection;
}

+ (WMNetworkDetailSection *)requestHeadersSectionForTransaction:(WMNetworkTransaction *)transaction {
    WMNetworkDetailSection *requestHeadersSection = [WMNetworkDetailSection new];
    requestHeadersSection.title = @"Request Headers";
    requestHeadersSection.rows = [self networkDetailRowsFromDictionary:transaction.request.allHTTPHeaderFields];

    return requestHeadersSection;
}

+ (WMNetworkDetailSection *)postBodySectionForTransaction:(WMNetworkTransaction *)transaction {
    WMNetworkDetailSection *postBodySection = [WMNetworkDetailSection new];
    postBodySection.title = @"Request Body Parameters";
    if (transaction.cachedRequestBody.length > 0) {
        NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
        if ([contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSData *body = [self postBodyDataForTransaction:transaction];
            NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
            postBodySection.rows = [self networkDetailRowsFromQueryItems:[WMNetworkUtility itemsFromQueryString:bodyString]];
        }
    }
    return postBodySection;
}

+ (WMNetworkDetailSection *)queryParametersSectionForTransaction:(WMNetworkTransaction *)transaction {
    NSArray<NSURLQueryItem *> *queries = [WMNetworkUtility itemsFromQueryString:transaction.request.URL.query];
    WMNetworkDetailSection *querySection = [WMNetworkDetailSection new];
    querySection.title = @"Query Parameters";
    querySection.rows = [self networkDetailRowsFromQueryItems:queries];

    return querySection;
}

+ (WMNetworkDetailSection *)responseHeadersSectionForTransaction:(WMNetworkTransaction *)transaction {
    WMNetworkDetailSection *responseHeadersSection = [WMNetworkDetailSection new];
    responseHeadersSection.title = @"Response Headers";
    if ([transaction.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)transaction.response;
        responseHeadersSection.rows = [self networkDetailRowsFromDictionary:httpResponse.allHeaderFields];
    }
    return responseHeadersSection;
}

+ (NSArray<WMNetworkDetailRow *> *)networkDetailRowsFromDictionary:(NSDictionary<NSString *, id> *)dictionary {
    NSMutableArray<WMNetworkDetailRow *> *rows = [NSMutableArray new];
    NSArray<NSString *> *sortedKeys = [dictionary.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (NSString *key in sortedKeys) {
        id value = dictionary[key];
        WMNetworkDetailRow *row = [WMNetworkDetailRow new];
        row.title = key;
        row.detailText = [value description];
        [rows addObject:row];
    }

    return rows.copy;
}

+ (NSArray<WMNetworkDetailRow *> *)networkDetailRowsFromQueryItems:(NSArray<NSURLQueryItem *> *)items {
    // Sort the items by name
    items = [items sortedArrayUsingComparator:^NSComparisonResult(NSURLQueryItem *item1, NSURLQueryItem *item2) {
        return [item1.name caseInsensitiveCompare:item2.name];
    }];

    NSMutableArray<WMNetworkDetailRow *> *rows = [NSMutableArray new];
    for (NSURLQueryItem *item in items) {
        WMNetworkDetailRow *row = [WMNetworkDetailRow new];
        row.title = item.name;
        row.detailText = item.value;
        [rows addObject:row];
    }

    return [rows copy];
}

+ (UIViewController *)detailViewControllerForMIMEType:(NSString *)mimeType data:(NSData *)data {
    if (!data) {
        return [WMNetworkWebViewController new];
    }
    // FIXME (RKO): Don't rely on UTF8 string encoding
    UIViewController *detailViewController = nil;
    if ([WMNetworkUtility isValidJSONData:data]) {
        NSString *prettyJSON = [WMNetworkUtility prettyJSONStringFromData:data];
        if (prettyJSON.length > 0) {
            detailViewController = [[WMNetworkWebViewController alloc] initWithText:prettyJSON];
        }
    } else if ([mimeType isEqual:@"application/x-plist"]) {
        id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
        detailViewController = [[WMNetworkWebViewController alloc] initWithText:[propertyList description]];
    }

    // Fall back to trying to show the response as text
    if (!detailViewController) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (text.length > 0) {
            detailViewController = [[WMNetworkWebViewController alloc] initWithText:text];
        }
    }
    return detailViewController;
}

+ (NSData *)postBodyDataForTransaction:(WMNetworkTransaction *)transaction {
    NSData *bodyData = transaction.cachedRequestBody;
    if (bodyData.length > 0) {
        NSString *contentEncoding = [transaction.request valueForHTTPHeaderField:@"Content-Encoding"];
        if ([contentEncoding rangeOfString:@"deflate" options:NSCaseInsensitiveSearch].length > 0 || [contentEncoding rangeOfString:@"gzip" options:NSCaseInsensitiveSearch].length > 0) {
            bodyData = [WMNetworkUtility inflatedDataFromCompressedData:bodyData];
        }
    }
    return bodyData;
}

+ (UIAlertController *)makeAlertWithTitle:(NSString *)title message:(NSString *)message button:(NSString *)button {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:button style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    return alertController;
}


@end
