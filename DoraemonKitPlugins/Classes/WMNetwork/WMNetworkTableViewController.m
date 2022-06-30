//
//  WMNetworkTableViewController.m
//  WMDoctor
//
//  Created by Baizhuo on 2021/10/18.
//  Copyright © 2021 Choice. All rights reserved.
//

#import "WMNetworkTableViewController.h"
#import "WMNetworkUtility.h"
#import <objc/runtime.h>

CGFloat const kWMDebounceInstant = 0.f;
CGFloat const kWMDebounceFast = 0.05;
CGFloat const kWMDebounceForAsyncSearch = 0.15;
CGFloat const kWMDebounceForExpensiveIO = 0.5;

@interface WMNetworkTableViewController ()
@property (nonatomic) BOOL didInitiallyRevealSearchBar;
@property (nonatomic) UITableViewStyle style;
@property (nonatomic) BOOL hasAppeared;
@property (nonatomic, readonly) UIView *tableHeaderViewContainer;
@property (nonatomic, readonly) BOOL manuallyDeactivateSearchOnDisappear;

@end

@implementation WMNetworkTableViewController
@synthesize tableHeaderViewContainer = _tableHeaderViewContainer;
@synthesize automaticallyShowsSearchBarCancelButton = _automaticallyShowsSearchBarCancelButton;

#pragma mark - Initialization

- (id)init {
    if (@available(iOS 13.0, *)) {
        self = [self initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [self initWithStyle:UITableViewStyleGrouped];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _searchBarDebounceInterval = kWMDebounceFast;
        _showSearchBarInitially = YES;
        _style = style;
        _manuallyDeactivateSearchOnDisappear = ({
            NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 11;
        });
        
        // We will be our own search delegate if we implement this method
        if ([self respondsToSelector:@selector(updateSearchResults:)]) {
            self.searchDelegate = (id)self;
        }
    }
    return self;
}

#pragma mark - Public

- (void)setShowsSearchBar:(BOOL)showsSearchBar {
    if (_showsSearchBar == showsSearchBar) return;
    _showsSearchBar = showsSearchBar;
    
    if (showsSearchBar) {
        UIViewController *results = self.searchResultsController;
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:results];
        self.searchController.searchBar.placeholder = @"搜索";
        self.searchController.searchResultsUpdater = (id)self;
        self.searchController.delegate = (id)self;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        /// Not necessary in iOS 13; remove this when iOS 13 is the minimum deployment target
        self.searchController.searchBar.delegate = self;

        self.automaticallyShowsSearchBarCancelButton = YES;

        if (@available(iOS 13, *)) {
            self.searchController.automaticallyShowsScopeBar = NO;
        }
        
        [self addSearchController:self.searchController];
    } else {
        // Search already shown and just set to NO, so remove it
        [self removeSearchController:self.searchController];
    }
}

- (NSInteger)selectedScope {
    if (self.searchController.searchBar.showsScopeBar) {
        return self.searchController.searchBar.selectedScopeButtonIndex;
    } else {
        return 0;
    }
}

- (void)setSelectedScope:(NSInteger)selectedScope {
    if (self.searchController.searchBar.showsScopeBar) {
        self.searchController.searchBar.selectedScopeButtonIndex = selectedScope;
    }

    [self.searchDelegate updateSearchResults:self.searchText];
}

- (NSString *)searchText {
    return self.searchController.searchBar.text;
}

- (BOOL)automaticallyShowsSearchBarCancelButton {
    if (@available(iOS 13, *)) {
        return self.searchController.automaticallyShowsCancelButton;
    }
    return _automaticallyShowsSearchBarCancelButton;
}

- (void)setAutomaticallyShowsSearchBarCancelButton:(BOOL)value {
    if (@available(iOS 13, *)) {
        self.searchController.automaticallyShowsCancelButton = value;
    }
    _automaticallyShowsSearchBarCancelButton = value;
}

- (void)onBackgroundQueue:(NSArray *(^)(void))backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *items = backgroundBlock();
        dispatch_async(dispatch_get_main_queue(), ^{
            mainBlock(items);
        });
    });
}

#pragma mark - View Controller Lifecycle

- (void)loadView {
    self.view = [[UITableView alloc] initWithFrame:CGRectZero style:self.style];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    // On iOS 13, the root view controller shows it's search bar no matter what.
    // Turning this off avoids some weird flash the navigation bar does when we
    // toggle navigationItem.hidesSearchBarWhenScrolling on and off. The flash
    // will still happen on subsequent view controllers, but we can at least
    // avoid it for the root view controller
    if (@available(iOS 13, *)) {
        if (self.navigationController.viewControllers.firstObject == self) {
            _showSearchBarInitially = NO;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (@available(iOS 11.0, *)) {
        // When going back, make the search bar reappear instead of hiding
        if ((self.pinSearchBar || self.showSearchBarInitially) && !self.didInitiallyRevealSearchBar) {
            self.navigationItem.hidesSearchBarWhenScrolling = NO;
        }
    }
    
    // Make the keyboard seem to appear faster
    if (self.activatesSearchBarAutomatically) {
        [self makeKeyboardAppearNow];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Allow scrolling to collapse the search bar, only if we don't want it pinned
    if (@available(iOS 11.0, *)) {
        if (self.showSearchBarInitially && !self.pinSearchBar && !self.didInitiallyRevealSearchBar) {
            // All this mumbo jumbo is necessary to work around a bug in iOS 13 up to 13.2
            // wherein quickly toggling navigationItem.hidesSearchBarWhenScrolling to make
            // the search bar appear initially results in a bugged search bar that
            // becomes transparent and floats over the screen as you scroll
            [UIView animateWithDuration:0.2 animations:^{
                self.navigationItem.hidesSearchBarWhenScrolling = YES;
                [self.navigationController.view setNeedsLayout];
                [self.navigationController.view layoutIfNeeded];
            }];
        }
    }
    
    if (self.activatesSearchBarAutomatically) {
        // Keyboard has appeared, now we call this as we soon present our search bar
        [self removeDummyTextField];
        
        // Activate the search bar
        dispatch_async(dispatch_get_main_queue(), ^{
            // This doesn't work unless it's wrapped in this dispatch_async call
            [self.searchController.searchBar becomeFirstResponder];
        });
    }

    // We only want to reveal the search bar when the view controller first appears.
    self.didInitiallyRevealSearchBar = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.manuallyDeactivateSearchOnDisappear && self.searchController.isActive) {
        self.searchController.active = NO;
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    // Reset this since we are re-appearing under a new
    // parent view controller and need to show it again
    self.didInitiallyRevealSearchBar = NO;
}

#pragma mark - Private

- (void)layoutTableHeaderIfNeeded {
    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
}

- (void)addSearchController:(UISearchController *)controller {
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = controller;
    } else {
        controller.searchBar.autoresizingMask |= UIViewAutoresizingFlexibleBottomMargin;
        [self.tableHeaderViewContainer addSubview:controller.searchBar];
        CGRect subviewFrame = controller.searchBar.frame;
        CGRect frame = self.tableHeaderViewContainer.frame;
        frame.size.width = MAX(frame.size.width, subviewFrame.size.width);
        frame.size.height = subviewFrame.size.height;
        
        self.tableHeaderViewContainer.frame = frame;
        [self layoutTableHeaderIfNeeded];
    }
}

- (void)removeSearchController:(UISearchController *)controller {
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = nil;
    } else {
        [controller.searchBar removeFromSuperview];
        self.tableView.tableHeaderView = nil;
        _tableHeaderViewContainer = nil;
    }
}

- (UIView *)tableHeaderViewContainer {
    if (!_tableHeaderViewContainer) {
        _tableHeaderViewContainer = [UIView new];
        self.tableView.tableHeaderView = self.tableHeaderViewContainer;
    }
    return _tableHeaderViewContainer;
}


#pragma mark - Search Bar

#pragma mark Faster keyboard

static UITextField *kDummyTextField = nil;

/// Make the keyboard appear instantly. We use this to make the
/// keyboard appear faster when the search bar is set to appear initially.
/// You must call \c -removeDummyTextField before your search bar is to appear.
- (void)makeKeyboardAppearNow {
    if (!kDummyTextField) {
        kDummyTextField = [UITextField new];
        kDummyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    
    kDummyTextField.inputAccessoryView = self.searchController.searchBar.inputAccessoryView;
    [UIApplication.sharedApplication.keyWindow addSubview:kDummyTextField];
    [kDummyTextField becomeFirstResponder];
}

- (void)removeDummyTextField {
    if (kDummyTextField.superview) {
        [kDummyTextField removeFromSuperview];
    }
}

#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text;
    
    void (^updateSearchResults)(void) = ^{
        if (self.searchResultsUpdater) {
            [self.searchResultsUpdater updateSearchResults:text];
        } else {
            [self.searchDelegate updateSearchResults:text];
        }
    };
    
    updateSearchResults();
}


#pragma mark UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    // Manually show cancel button for < iOS 13
    if (!@available(iOS 13, *) && self.automaticallyShowsSearchBarCancelButton) {
        [searchController.searchBar setShowsCancelButton:YES animated:YES];
    }
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    // Manually hide cancel button for < iOS 13
    if (!@available(iOS 13, *) && self.automaticallyShowsSearchBarCancelButton) {
        [searchController.searchBar setShowsCancelButton:NO animated:YES];
    }
}


#pragma mark UISearchBarDelegate

/// Not necessary in iOS 13; remove this when iOS 13 is the deployment target
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:self.searchController];
}


#pragma mark Table View

/// Not having a title in the first section looks weird with a rounded-corner table view style
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (@available(iOS 13, *)) {
        if (self.style == UITableViewStyleInsetGrouped) {
            return @" ";
        }
    }

    return nil; // For plain/gropued style
}

@end
