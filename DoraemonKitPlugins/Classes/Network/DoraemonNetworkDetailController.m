//
//  DoraemonNetworkDetailController.m
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/18.
//

#if DEBUG

#import "DoraemonNetworkDetailController.h"
#import "DoraemonNetworkRecorder.h"
#import "DoraemonNetworkUtility.h"
#import "DoraemonNetworkTransaction.h"
#import "DoraemonNetworkMultilineCell.h"
#import "DoraemonNetworkWebController.h"
#import "DoraemonNetworkDataWebView.h"

@interface DoraemonNetworkDetailController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) DoraemonNetworkDataWebView *dataView;
@property (nonatomic, copy) NSArray<NetworkDetailSection *> *sections;

@end

@implementation DoraemonNetworkDetailController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:false animated:animated];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [NSNotificationCenter.defaultCenter addObserver:self
            selector:@selector(handleTransactionUpdatedNotification:)
            name:kNetworkRecorderTransactionUpdatedNotification
            object:nil];
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.frame;
    self.dataView.frame = self.view.frame;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.titleView = self.segmentedControl;
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.dataView];

    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithTitle:@"CURL" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightBtn;
}

- (void)segmentAction:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.tableView.hidden = NO;
        self.dataView.hidden = YES;
    } else {
        self.tableView.hidden = YES;
        self.dataView.hidden = NO;
    }
}

- (void)copyButtonPressed:(UIBarButtonItem *)sender {
    [UIPasteboard.generalPasteboard setString:[DoraemonNetworkUtility curlCommandString:self.transaction.request]];
}

- (void)setTransaction:(DoraemonNetworkTransaction *)transaction {
    if (![_transaction isEqual:transaction]) {
        _transaction = transaction;
        self.title = [transaction.request.URL lastPathComponent];
        [self rebuildTableSections];
        [self rebuildDataView];
    }
}

- (void)rebuildDataView {
    NSData *data = [DoraemonNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:self.transaction];
    NSString *prettyJSON = [DoraemonNetworkUtility prettyJSONStringFromData:data];
    if (prettyJSON.length > 0) {
        [self.dataView showWithText:prettyJSON];
    }
}

- (void)setSections:(NSArray<NetworkDetailSection *> *)sections {
    if (![_sections isEqual:sections]) {
        _sections = [sections copy];
        [self.tableView reloadData];
    }
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification {
    DoraemonNetworkTransaction *transaction = [[notification userInfo] objectForKey:kNetworkRecorderUserInfoTransactionKey];
    if (transaction == self.transaction) {
        [self rebuildTableSections];
    }
}

- (void)rebuildTableSections {
    NSMutableArray<NetworkDetailSection *> *sections = [NSMutableArray new];

    NetworkDetailSection *generalSection = [[self class] generalSectionForTransaction:self.transaction];
    if (generalSection.rows.count > 0) {
        [sections addObject:generalSection];
    }
    NetworkDetailSection *queryParametersSection = [[self class] queryParametersSectionForTransaction:self.transaction];
    if (queryParametersSection.rows.count > 0) {
        [sections addObject:queryParametersSection];
    }
    NetworkDetailSection *postBodySection = [[self class] postBodySectionForTransaction:self.transaction];
    if (postBodySection.rows.count > 0) {
        [sections addObject:postBodySection];
    }
    NetworkDetailSection *requestHeadersSection = [[self class] requestHeadersSectionForTransaction:self.transaction];
    if (requestHeadersSection.rows.count > 0) {
        [sections addObject:requestHeadersSection];
    }
    NetworkDetailSection *responseHeadersSection = [[self class] responseHeadersSectionForTransaction:self.transaction];
    if (responseHeadersSection.rows.count > 0) {
        [sections addObject:responseHeadersSection];
    }

    self.sections = sections;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DoraemonNetworkMultilineCell *cell = [tableView dequeueReusableCellWithIdentifier:DoraemonNetworkMultilineCell.reuseId forIndexPath:indexPath];
    NetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];
    cell.textLabel.attributedText = [[self class] attributedTextForRow:rowModel];
    cell.accessoryType = rowModel.selectionFuture ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = rowModel.selectionFuture ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

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
    NetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
    NSAttributedString *attributedText = [[self class] attributedTextForRow:row];
    BOOL showsAccessory = row.selectionFuture != nil;
    return [DoraemonNetworkMultilineCell
        preferredHeightWithAttributedText:attributedText
        maxWidth:tableView.bounds.size.width
        style:tableView.style
        showsAccessory:showsAccessory
    ];
}

- (NetworkDetailRow *)rowModelAtIndexPath:(NSIndexPath *)indexPath {
    NetworkDetailSection *sectionModel = self.sections[indexPath.section];
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
        NetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
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
                    NetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
                    UIPasteboard.generalPasteboard.string = row.detailText;
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

+ (NSAttributedString *)attributedTextForRow:(NetworkDetailRow *)row {
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

+ (NetworkDetailSection *)generalSectionForTransaction:(DoraemonNetworkTransaction *)transaction {
    NSMutableArray<NetworkDetailRow *> *rows = [NSMutableArray new];

    NetworkDetailRow *requestURLRow = [NetworkDetailRow new];
    requestURLRow.title = @"Request URL";
    NSURL *url = transaction.request.URL;
    requestURLRow.detailText = url.absoluteString;
    [rows addObject:requestURLRow];

    NetworkDetailRow *requestMethodRow = [NetworkDetailRow new];
    requestMethodRow.title = @"Request Method";
    requestMethodRow.detailText = transaction.request.HTTPMethod;
    [rows addObject:requestMethodRow];

    if (transaction.cachedRequestBody.length > 0) {
        NetworkDetailRow *postBodySizeRow = [NetworkDetailRow new];
        postBodySizeRow.title = @"Request Body Size";
        postBodySizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.cachedRequestBody.length countStyle:NSByteCountFormatterCountStyleBinary];
        [rows addObject:postBodySizeRow];

        NetworkDetailRow *postBodyRow = [NetworkDetailRow new];
        postBodyRow.title = @"Request Body";
        postBodyRow.detailText = @"点击查看";
        wmweakify(transaction)
        postBodyRow.selectionFuture = ^UIViewController * () {
            wmstrongify(transaction)
            // Show the body if we can
            NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
            UIViewController *detailViewController = [self detailViewControllerForMIMEType:contentType data:[self postBodyDataForTransaction:transaction]];
            if (detailViewController) {
                detailViewController.title = @"Request Body";
                return detailViewController;
            }
            // We can't show the body, alert user
            return [[self new] makeAlertWithTitle:@"无法查看Body数据" message:[NSString stringWithFormat:@"没有%@类型的Body数据", contentType] button:@"确定"];
        };

        [rows addObject:postBodyRow];
    }

    NSString *statusCodeString = [DoraemonNetworkUtility statusCodeStringFromURLResponse:transaction.response];
    if (statusCodeString.length > 0) {
        NetworkDetailRow *statusCodeRow = [NetworkDetailRow new];
        statusCodeRow.title = @"Status Code";
        statusCodeRow.detailText = statusCodeString;
        [rows addObject:statusCodeRow];
    }

    if (transaction.error) {
        NetworkDetailRow *errorRow = [NetworkDetailRow new];
        errorRow.title = @"Error";
        errorRow.detailText = transaction.error.localizedDescription;
        [rows addObject:errorRow];
    }

    NetworkDetailRow *responseBodyRow = [NetworkDetailRow new];
    responseBodyRow.title = @"Response Body";
    NSData *responseData = [DoraemonNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
    if (responseData.length > 0) {
        responseBodyRow.detailText = @"点击查看";
        // Avoid a long lived strong reference to the response data in case we need to purge it from the cache.
        wmweakify(responseData)
        responseBodyRow.selectionFuture = ^UIViewController *() {
            wmstrongify(responseData)
            
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
            return [[self new] makeAlertWithTitle:@"无法查看Response数据" message:responseData ? [NSString stringWithFormat:@"没有%@类型的Response数据", contentType] : @"Response已从缓存中清除"  button:@"确定"];

        };
    } else {
        BOOL emptyResponse = transaction.receivedDataLength == 0;
        responseBodyRow.detailText = emptyResponse ? @"空" : @"无缓存";
    }

    [rows addObject:responseBodyRow];

    NetworkDetailRow *responseSizeRow = [NetworkDetailRow new];
    responseSizeRow.title = @"Response Size";
    responseSizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
    [rows addObject:responseSizeRow];

    NetworkDetailRow *mimeTypeRow = [NetworkDetailRow new];
    mimeTypeRow.title = @"MIME Type";
    mimeTypeRow.detailText = transaction.response.MIMEType;
    [rows addObject:mimeTypeRow];

    NetworkDetailRow *mechanismRow = [NetworkDetailRow new];
    mechanismRow.title = @"Mechanism";
    mechanismRow.detailText = transaction.requestMechanism;
    [rows addObject:mechanismRow];

    NSDateFormatter *startTimeFormatter = [NSDateFormatter new];
    startTimeFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";

    NetworkDetailRow *localStartTimeRow = [NetworkDetailRow new];
    localStartTimeRow.title = [NSString stringWithFormat:@"Start Time (%@)", [NSTimeZone.localTimeZone abbreviationForDate:transaction.startTime]];
    localStartTimeRow.detailText = [startTimeFormatter stringFromDate:transaction.startTime];
    [rows addObject:localStartTimeRow];

    startTimeFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

    NetworkDetailRow *utcStartTimeRow = [NetworkDetailRow new];
    utcStartTimeRow.title = @"Start Time (UTC)";
    utcStartTimeRow.detailText = [startTimeFormatter stringFromDate:transaction.startTime];
    [rows addObject:utcStartTimeRow];

    NetworkDetailRow *unixStartTime = [NetworkDetailRow new];
    unixStartTime.title = @"Unix Start Time";
    unixStartTime.detailText = [NSString stringWithFormat:@"%f", [transaction.startTime timeIntervalSince1970]];
    [rows addObject:unixStartTime];

    NetworkDetailRow *durationRow = [NetworkDetailRow new];
    durationRow.title = @"Total Duration";
    durationRow.detailText = [DoraemonNetworkUtility stringFromRequestDuration:transaction.duration];
    [rows addObject:durationRow];

    NetworkDetailRow *latencyRow = [NetworkDetailRow new];
    latencyRow.title = @"Latency";
    latencyRow.detailText = [DoraemonNetworkUtility stringFromRequestDuration:transaction.latency];
    [rows addObject:latencyRow];

    NetworkDetailSection *generalSection = [NetworkDetailSection new];
    generalSection.title = @"常规";
    generalSection.rows = rows;

    return generalSection;
}

+ (NetworkDetailSection *)requestHeadersSectionForTransaction:(DoraemonNetworkTransaction *)transaction {
    NetworkDetailSection *requestHeadersSection = [NetworkDetailSection new];
    requestHeadersSection.title = @"请求标头";
    requestHeadersSection.rows = [self networkDetailRowsFromDictionary:transaction.request.allHTTPHeaderFields];

    return requestHeadersSection;
}

+ (NetworkDetailSection *)postBodySectionForTransaction:(DoraemonNetworkTransaction *)transaction {
    NetworkDetailSection *postBodySection = [NetworkDetailSection new];
    postBodySection.title = @"请求参数";
    if (transaction.cachedRequestBody.length > 0) {
        NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
        if ([contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSData *body = [self postBodyDataForTransaction:transaction];
            NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
            postBodySection.rows = [self networkDetailRowsFromQueryItems:[DoraemonNetworkUtility itemsFromQueryString:bodyString]];
        }
    }
    return postBodySection;
}

+ (NetworkDetailSection *)queryParametersSectionForTransaction:(DoraemonNetworkTransaction *)transaction {
    NSArray<NSURLQueryItem *> *queries = [DoraemonNetworkUtility itemsFromQueryString:transaction.request.URL.query];
    NetworkDetailSection *querySection = [NetworkDetailSection new];
    querySection.title = @"查询参数";
    querySection.rows = [self networkDetailRowsFromQueryItems:queries];

    return querySection;
}

+ (NetworkDetailSection *)responseHeadersSectionForTransaction:(DoraemonNetworkTransaction *)transaction {
    NetworkDetailSection *responseHeadersSection = [NetworkDetailSection new];
    responseHeadersSection.title = @"响应标头";
    if ([transaction.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)transaction.response;
        responseHeadersSection.rows = [self networkDetailRowsFromDictionary:httpResponse.allHeaderFields];
    }
    return responseHeadersSection;
}

+ (NSArray<NetworkDetailRow *> *)networkDetailRowsFromDictionary:(NSDictionary<NSString *, id> *)dictionary {
    NSMutableArray<NetworkDetailRow *> *rows = [NSMutableArray new];
    NSArray<NSString *> *sortedKeys = [dictionary.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (NSString *key in sortedKeys) {
        id value = dictionary[key];
        NetworkDetailRow *row = [NetworkDetailRow new];
        row.title = key;
        row.detailText = [value description];
        [rows addObject:row];
    }

    return rows.copy;
}

+ (NSArray<NetworkDetailRow *> *)networkDetailRowsFromQueryItems:(NSArray<NSURLQueryItem *> *)items {
    // Sort the items by name
    items = [items sortedArrayUsingComparator:^NSComparisonResult(NSURLQueryItem *item1, NSURLQueryItem *item2) {
        return [item1.name caseInsensitiveCompare:item2.name];
    }];

    NSMutableArray<NetworkDetailRow *> *rows = [NSMutableArray new];
    for (NSURLQueryItem *item in items) {
        NetworkDetailRow *row = [NetworkDetailRow new];
        row.title = item.name;
        row.detailText = item.value;
        [rows addObject:row];
    }

    return [rows copy];
}

+ (UIViewController *)detailViewControllerForMIMEType:(NSString *)mimeType data:(NSData *)data {
    // FIXME (RKO): Don't rely on UTF8 string encoding
    UIViewController *detailViewController = nil;
    if ([DoraemonNetworkUtility isValidJSONData:data]) {
        NSString *prettyJSON = [DoraemonNetworkUtility prettyJSONStringFromData:data];
        if (prettyJSON.length > 0) {
            detailViewController = [[DoraemonNetworkWebController alloc] initWithText:prettyJSON];
        }
    } else if ([mimeType isEqual:@"application/x-plist"]) {
        id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
        detailViewController = [[DoraemonNetworkWebController alloc] initWithText:[propertyList description]];
    }

    // Fall back to trying to show the response as text
    if (!detailViewController) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (text.length > 0) {
            detailViewController = [[DoraemonNetworkWebController alloc] initWithText:text];
        }
    }
    return detailViewController;
}

+ (NSData *)postBodyDataForTransaction:(DoraemonNetworkTransaction *)transaction {
    NSData *bodyData = transaction.cachedRequestBody;
    if (bodyData.length > 0) {
        NSString *contentEncoding = [transaction.request valueForHTTPHeaderField:@"Content-Encoding"];
        if ([contentEncoding rangeOfString:@"deflate" options:NSCaseInsensitiveSearch].length > 0 || [contentEncoding rangeOfString:@"gzip" options:NSCaseInsensitiveSearch].length > 0) {
            bodyData = [DoraemonNetworkUtility inflatedDataFromCompressedData:bodyData];
        }
    }
    return bodyData;
}

- (UIAlertController *)makeAlertWithTitle:(NSString *)title message:(NSString *)message button:(NSString *)button {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:button style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}]];
    [self presentViewController:alertController animated:YES completion:nil];
    return alertController;
}

#pragma mark - lazy load

- (UISegmentedControl *)segmentedControl {
    if (!_segmentedControl) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"General", @"Data"]];
        _segmentedControl.frame = CGRectMake(60, 0, [UIScreen mainScreen].bounds.size.width - 120, 30);
        _segmentedControl.selectedSegmentIndex = 0;
        [_segmentedControl addTarget:self action:@selector(segmentAction:)forControlEvents:UIControlEventValueChanged];
    }
    return _segmentedControl;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.sectionHeaderHeight = 40;
        [_tableView registerClass:[DoraemonNetworkMultilineCell class] forCellReuseIdentifier:DoraemonNetworkMultilineCell.reuseId];
    }
    return _tableView;
}

- (DoraemonNetworkDataWebView *)dataView {
    if (!_dataView) {
        _dataView = [[DoraemonNetworkDataWebView alloc] init];
        _dataView.backgroundColor = [UIColor systemGroupedBackgroundColor];
        _dataView.hidden = YES;
    }
    return _dataView;
}

@end

#endif
