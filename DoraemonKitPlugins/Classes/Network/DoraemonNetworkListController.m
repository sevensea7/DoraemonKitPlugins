//
//  DoraemonNetworkListController.m
//  ZZHLBidder
//
//  Created by 七海 on 2023/10/18.
//

#if DEBUG

#import "DoraemonNetworkListController.h"
#import "DoraemonNetworkDetailController.h"
#import "DoraemonNetworkObserver.h"
#import "DoraemonNetworkRecorder.h"
#import "DoraemonNetworkUtility.h"
#import "DoraemonNetworkTransaction.h"
#import "DoraemonNetworkTransactionCell.h"

@interface DoraemonNetworkListController ()
@property (nonatomic, copy) NSArray<DoraemonNetworkTransaction *> *networkTransactions;
@property (nonatomic) long long bytesReceived;
@property (nonatomic, copy) NSArray<DoraemonNetworkTransaction *> *filteredNetworkTransactions;
@property (nonatomic) long long filteredBytesReceived;

@property (nonatomic) BOOL rowInsertInProgress;
@property (nonatomic) BOOL isPresentingSearch;
@property (nonatomic) BOOL pendingReload;
@end

@implementation DoraemonNetworkListController

#pragma mark - Lifecycle

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"网络监测";
    self.showsSearchBar = YES;
    self.showSearchBarInitially = NO;

    [self.tableView registerClass:DoraemonNetworkTransactionCell.class forCellReuseIdentifier:DoraemonNetworkTransactionCell.reuseId];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 95;
    
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearNetworkData:)];
    self.navigationItem.rightBarButtonItem = rightBtn;
    
    [self registerForNotifications];
    [self updateTransactions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Reload the table if we received updates while not on-screen
    if (self.pendingReload) {
        [self.tableView reloadData];
        self.pendingReload = NO;
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)registerForNotifications {
    NSDictionary *notifications = @{
        kNetworkRecorderNewTransactionNotification: NSStringFromSelector(@selector(handleNewTransactionRecordedNotification:)),
        kNetworkRecorderTransactionUpdatedNotification: NSStringFromSelector(@selector(handleTransactionUpdatedNotification:)),
        kNetworkRecorderTransactionsClearedNotification: NSStringFromSelector(@selector(handleTransactionsClearedNotification:)),
        kNetworkObserverEnabledStateChangedNotification: NSStringFromSelector(@selector(handleNetworkObserverEnabledStateChangedNotification:)),
    };
    
    for (NSString *name in notifications.allKeys) {
        [NSNotificationCenter.defaultCenter addObserver:self
            selector:NSSelectorFromString(notifications[name]) name:name object:nil
        ];
    }
}

- (void)clearNetworkData:(UIBarButtonItem *)sender {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil
                                   message:@"确定清空吗?"
                                   preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive
       handler:^(UIAlertAction *action) {
        [DoraemonNetworkRecorder.defaultRecorder clearRecordedActivity];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
       handler:nil];
    [sheet addAction:defaultAction];
    [sheet addAction:cancelAction];
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark Transactions

- (void)updateTransactions {
    self.networkTransactions = [DoraemonNetworkRecorder.defaultRecorder networkTransactions];
}

- (void)setNetworkTransactions:(NSArray<DoraemonNetworkTransaction *> *)networkTransactions {
    if (![_networkTransactions isEqual:networkTransactions]) {
        _networkTransactions = networkTransactions;
        [self updateBytesReceived];
        [self updateFilteredBytesReceived];
    }
}

- (void)updateBytesReceived {
    long long bytesReceived = 0;
    for (DoraemonNetworkTransaction *transaction in self.networkTransactions) {
        bytesReceived += transaction.receivedDataLength;
    }
    self.bytesReceived = bytesReceived;
    [self updateFirstSectionHeader];
}

- (void)setFilteredNetworkTransactions:(NSArray<DoraemonNetworkTransaction *> *)networkTransactions {
    if (![_filteredNetworkTransactions isEqual:networkTransactions]) {
        _filteredNetworkTransactions = networkTransactions;
        [self updateFilteredBytesReceived];
    }
}

- (void)updateFilteredBytesReceived {
    long long filteredBytesReceived = 0;
    for (DoraemonNetworkTransaction *transaction in self.filteredNetworkTransactions) {
        filteredBytesReceived += transaction.receivedDataLength;
    }
    self.filteredBytesReceived = filteredBytesReceived;
    [self updateFirstSectionHeader];
}

#pragma mark Header

- (void)updateFirstSectionHeader {
    UIView *view = [self.tableView headerViewForSection:0];
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.text = [self headerText];
        [headerView setNeedsLayout];
    }
}

- (NSString *)headerText {
    long long bytesReceived = 0;
    NSInteger totalRequests = 0;
    if (self.searchController.isActive) {
        bytesReceived = self.filteredBytesReceived;
        totalRequests = self.filteredNetworkTransactions.count;
    } else {
        bytesReceived = self.bytesReceived;
        totalRequests = self.networkTransactions.count;
    }
    
    NSString *byteCountText = [NSByteCountFormatter
        stringFromByteCount:bytesReceived countStyle:NSByteCountFormatterCountStyleBinary
    ];
    NSString *requestsText = totalRequests == 1 ? @"Request" : @"Requests";
    return [NSString stringWithFormat:@"%@ %@ (%@ received)",
        @(totalRequests), requestsText, byteCountText
    ];
}

#pragma mark - Notification Handlers

- (void)handleNewTransactionRecordedNotification:(NSNotification *)notification {
    [self tryUpdateTransactions];
}

- (void)tryUpdateTransactions {
    // Don't do any view updating if we aren't in the view hierarchy
    if (!self.viewIfLoaded.window) {
        [self updateTransactions];
        self.pendingReload = YES;
        return;
    }
    
    // Let the previous row insert animation finish before starting a new one to avoid stomping.
    // We'll try calling the method again when the insertion completes,
    // and we properly no-op if there haven't been changes.
    if (self.rowInsertInProgress) {
        return;
    }
    
    if (self.searchController.isActive) {
        [self updateTransactions];
        [self updateSearchResults:self.searchText];
        return;
    }

    NSInteger existingRowCount = self.networkTransactions.count;
    [self updateTransactions];
    NSInteger newRowCount = self.networkTransactions.count;
    NSInteger addedRowCount = newRowCount - existingRowCount;

    if (addedRowCount != 0 && !self.isPresentingSearch) {
        // Insert animation if we're at the top.
        if (self.tableView.contentOffset.y <= 0.0 && addedRowCount > 0) {
            [CATransaction begin];
            
            self.rowInsertInProgress = YES;
            [CATransaction setCompletionBlock:^{
                self.rowInsertInProgress = NO;
                [self tryUpdateTransactions];
            }];

            NSMutableArray<NSIndexPath *> *indexPathsToReload = [NSMutableArray new];
            for (NSInteger row = 0; row < addedRowCount; row++) {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:0]];
            }
            [self.tableView insertRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];

            [CATransaction commit];
        } else {
            // Maintain the user's position if they've scrolled down.
            CGSize existingContentSize = self.tableView.contentSize;
            [self.tableView reloadData];
            CGFloat contentHeightChange = self.tableView.contentSize.height - existingContentSize.height;
            self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y + contentHeightChange);
        }
    }
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification {
    [self updateBytesReceived];
    [self updateFilteredBytesReceived];

    DoraemonNetworkTransaction *transaction = notification.userInfo[kNetworkRecorderUserInfoTransactionKey];

    // Update both the main table view and search table view if needed.
    for (DoraemonNetworkTransactionCell *cell in [self.tableView visibleCells]) {
        if ([cell.transaction isEqual:transaction]) {
            // Using -[UITableView reloadRowsAtIndexPaths:withRowAnimation:] is overkill here and kicks off a lot of
            // work that can make the table view somewhat unresponsive when lots of updates are streaming in.
            // We just need to tell the cell that it needs to re-layout.
            [cell setNeedsLayout];
            break;
        }
    }
    [self updateFirstSectionHeader];
}

- (void)handleTransactionsClearedNotification:(NSNotification *)notification {
    [self updateTransactions];
    [self.tableView reloadData];
}

- (void)handleNetworkObserverEnabledStateChangedNotification:(NSNotification *)notification {
    // Update the header, which displays a warning when network debugging is disabled
    [self updateFirstSectionHeader];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchController.isActive ? self.filteredNetworkTransactions.count : self.networkTransactions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self headerText];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
        headerView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DoraemonNetworkTransactionCell *cell = [tableView dequeueReusableCellWithIdentifier:DoraemonNetworkTransactionCell.reuseId forIndexPath:indexPath];
    cell.transaction = [self transactionAtIndexPath:indexPath];

    // Since we insert from the top, assign background colors bottom up to keep them consistent for each transaction.
//    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1];
    } else {
        cell.backgroundColor = UIColor.whiteColor;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DoraemonNetworkDetailController *detailViewController = [DoraemonNetworkDetailController new];
    detailViewController.transaction = [self transactionAtIndexPath:indexPath];
    [self.navigationController pushViewController:detailViewController animated:YES];
}


#pragma mark - Menu Actions

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        NSURLRequest *request = [self transactionAtIndexPath:indexPath].request;
        UIPasteboard.generalPasteboard.string = request.URL.absoluteString ?: @"";
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point __IOS_AVAILABLE(13.0) {
    NSURLRequest *request = [self transactionAtIndexPath:indexPath].request;
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
        previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UIAction *copy = [UIAction
                actionWithTitle:@"复制"
                image:nil
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    UIPasteboard.generalPasteboard.string = request.URL.absoluteString ?: @"";
                }
            ];
            UIAction *denylist = [UIAction
                actionWithTitle:[NSString stringWithFormat:@"移除%@", request.URL.host]
                image:nil
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    NSMutableArray *denylist = DoraemonNetworkRecorder.defaultRecorder.hostDenylist;
                    [denylist addObject:request.URL.host];
                    [DoraemonNetworkRecorder.defaultRecorder clearExcludedTransactions];
                    [DoraemonNetworkRecorder.defaultRecorder synchronizeDenylist];
                    [self tryUpdateTransactions];
                }
            ];
            return [UIMenu
                menuWithTitle:@"" image:nil identifier:nil
                options:UIMenuOptionsDisplayInline
                children:@[copy, denylist]
            ];
        }
    ];
}

- (DoraemonNetworkTransaction *)transactionAtIndexPath:(NSIndexPath *)indexPath {
    return self.searchController.isActive ? self.filteredNetworkTransactions[indexPath.row] : self.networkTransactions[indexPath.row];
}


#pragma mark - Search Bar

- (void)updateSearchResults:(NSString *)searchString {
    if (!searchString.length) {
        self.filteredNetworkTransactions = self.networkTransactions;
        [self.tableView reloadData];
    } else {
        [self onBackgroundQueue:^NSArray *{
            return [self.networkTransactions _filtered:^BOOL(DoraemonNetworkTransaction *entry, NSUInteger idx) {
                return [entry.request.URL.absoluteString localizedCaseInsensitiveContainsString:searchString];
            }];
        } thenOnMainQueue:^(NSArray *filteredNetworkTransactions) {
            if ([self.searchText isEqual:searchString]) {
                self.filteredNetworkTransactions = filteredNetworkTransactions;
                [self.tableView reloadData];
            }
        }];
    }
}


#pragma mark UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    self.isPresentingSearch = YES;
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    self.isPresentingSearch = NO;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    [self.tableView reloadData];
}


@end

#endif
