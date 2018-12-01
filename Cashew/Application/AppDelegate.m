//
//  AppDelegate.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "AppDelegate.h"
#import "QView.h"
#import "QSourceListViewController.h"
#import "QIssuesViewController.h"
#import "QIssueDetailsViewController.h"
#import "QIssuesSearchViewController.h"
#import "QContext.h"
#import "QLineSplitterView.h"
#import "QAccountStore.h"
#import "NSUserDefaults+SplitViewState.h"
#import "QAccountCreationWindowController.h"
#import "QIssueSync.h"
#ifndef DEBUG
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#endif
#import <Crashlytics/Answers.h>
#import "Cashew-Swift.h"
#import "NSUserDefaults+Application.h"
#import "QRepositoryStore.h"
#import "QUserService.h"
#import "SRUserFeebackViewController.h"
#import "SRMenuUtilities.h"
#import "SRIssueNotificationSyncer.h"
#import "QIssueFavoriteStore.h"
#import "QIssueNotificationStore.h"
#import "SRStatusImageView.h"

@interface _QTitlebarView : QView

@end

@implementation _QTitlebarView {
    CGPoint _initialLocation;
}


- (BOOL)mouseDownCanMoveWindow
{
    return YES;
}

@end

@interface AppDelegate () <QSourceListViewControllerDelegate, QIssuesViewControllerDelegate, QLineSplitterViewDelegate, QAccountCreationWindowControllerDelegate, BaseModalWindowControllerDelegate, NSWindowDelegate, NSUserNotificationCenterDelegate, SRStatusImageViewDelegate, QStoreObserver, NSPopoverDelegate>

@property (weak) IBOutlet NSMenuItem *closeOrOpenIssuesMenuItem;
@property (nonatomic, weak) IBOutlet QView *rightContainerView;
@property (nonatomic, weak) IBOutlet QView *centerContainerView;
@property (nonatomic, weak) IBOutlet QView *leftContainerView;
@property (nonatomic) SRBaseSeparatorView *titleBarLineView;
@property (weak) IBOutlet QView *windowMainView;

@property (weak) IBOutlet QLineSplitterView *leftCenterLineSplitterView;
@property (weak) IBOutlet QLineSplitterView *rightCenterLineSplitterView;

@property (weak) IBOutlet NSLayoutConstraint *leftContainerViewWidthConstraint;
@property (weak) IBOutlet NSLayoutConstraint *centerContainerViewWidthConstraint;


@property (nonatomic) QSourceListViewController *sourceListViewController;
@property (nonatomic) QIssuesViewController *issuesViewController;
@property (nonatomic) QIssueDetailsViewController *issueDetailsViewController;
@property (nonatomic) QIssuesSearchViewController *searchViewController;

@property (nonatomic) NSWindowController *currentPresentedBaseModalWindowController;
@property (nonatomic) NewIssueWindowController *createIssueWindowController;

@property (nonatomic) IBOutlet BaseView *modalOverlayView;

@property (nonatomic, weak) IBOutlet NSWindow *window;
@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) SRNotificationManager *notificationManager;

@property (nonatomic) BaseModalWindowController *labelsPickerWindowController;
@property (nonatomic) BaseModalWindowController *repositoriesPickerWindowController;
@property (nonatomic) BaseModalWindowController *assigneePickerWindowController;
@property (nonatomic) BaseModalWindowController *milestonePickerWindowController;
@property (nonatomic) BaseModalWindowController *userFeedbackWindowController;
@property (nonatomic) SRPreferencesWindowController *preferencesWindowController;
@property (nonatomic) SRRepositoriesCloudKitService *repositoriesCloudKitService;
@property (nonatomic) NSMutableDictionary<QIssue *, SRImageViewerWindowController *> *imageViewerWindowControllers;
@property (nonatomic) SRStatusBarViewController *statusBarViewController;
@property (nonatomic) SRSearchBuilderViewController *searchBuilderViewController;
@property (nonatomic) SRCoalescer *issueDetailCoalescer;
@property (nonatomic) SRCoalescer *splitViewUserDefaultsCoalescer;
@property (nonatomic) QAccount *currentAccount;

//@property (nonatomic) NSMenuItem *notificationsMenuItem;
@property (weak) IBOutlet NSMenuItem *shareIssueMenuItem;
@property (weak) IBOutlet NSMenuItem *issueExtensionsMenuItem;

@property (nonatomic) SRIssueExtensionsJSContextRunner *codeExtensionRunner;

@property (nonatomic) NSPopover *statusBarPopover;
@property (nonatomic) NSPopover *searchBuilderPopover;
@property (nonatomic) SREventMonitor *popoverEventMonitor;

@property (weak) IBOutlet NSToolbarItem *searchBarToolbarItem;
@property (weak) IBOutlet NSToolbarItem *searchBuilderButton;
@property (weak) IBOutlet NSToolbarItem *syncButton;
//@property (weak) IBOutlet NSToolbarItem *createIssueToolbarItem;
@property (weak) IBOutlet NSToolbarItem *refreshToolbarItem;


@property (weak) IBOutlet NSPopUpButton *accountsPopUpButton;
@property (weak) IBOutlet NSSplitView *classicModeSplitView;
@property (weak) IBOutlet NSView *classicModeDetailsContainerView;
@property (weak) IBOutlet NSView *classicModeIssueListContainerView;

@property (nonatomic) SRLayoutPreference layoutMode;

@property (nonatomic) HotKeyCreator *hotKey;

@end

@implementation AppDelegate {
    //NSLayoutConstraint *_searchFieldLeftConstraint;
    //NSTimer *_syncTimer;
}

+ (id<CashewAppDelegate>)sharedCashewAppDelegate {
    return (id<CashewAppDelegate>)[[NSApplication sharedApplication] delegate];
}

- (void)dealloc
{
    [QAccountStore remove:self];
    [QIssueNotificationStore remove:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:[NSUserDefaults layoutModeKeyPath]];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
{
    return false;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    [self.window setMovableByWindowBackground:YES];
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSUserDefaults fixDefaultsIfNeeded];
    
    // setup loggers
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    
#ifndef DEBUG
    [Fabric with:@[[Crashlytics class], [Answers class]]];
#endif
    
    self.hotKey = [HotKeyCreator new];
    [self.hotKey register];
    
    // setup database
    [QBaseStore setupDatabaseQueues];
    
    // run db conversions
    if (![NSUserDefaults didRunEmbedLabelsInIssuesConversion]) {
        SREmbedLabelsInIssuesConversion *embedLabelsInIssueConversion = [SREmbedLabelsInIssuesConversion new];
        [embedLabelsInIssueConversion runConversion];
        [NSUserDefaults embedLabelsInIssuesConversionCompleted];
    }
    
    // setup code extension runner
    self.codeExtensionRunner = [[SRIssueExtensionsJSContextRunner alloc] initWithEnvironment:[[SRProductionIssueExtensionEnvironment alloc] init]];
    
    
    self.window.contentView.wantsLayer = YES;
    self.window.allowsConcurrentViewDrawing = true;
    self.layoutMode = [NSUserDefaults layoutModePreference];
    
    [self _setupSourceListViewController];
    [self _setupTitleBar];
    [self _setupLineSplitters];
    [self _setupModalOverlayView];
    [self _setupIssueViewWithCurrentIssueFilter];
    
    // setup close/open menu item
    self.closeOrOpenIssuesMenuItem.action = @selector(sr_closeIssues:);
    self.closeOrOpenIssuesMenuItem.target = [AppDelegate sharedCashewAppDelegate];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:[NSUserDefaults layoutModeKeyPath] options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidResize:) name:NSWindowDidResizeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didContextIssueFilterChange:) name:kQContextChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showCreateIssueWindowController:) name:kQShowCreateNewIssueNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didClickNewIssue:) name:kQCreateIssueNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showAccountCreationController) name:kQForceLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showLabelPickerView) name:kQShowLabelPickerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showMilestonePickerView) name:kQShowMilestonePickerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showAssigneePickerView) name:kQShowAssigneePickerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidMaximize:) name:NSWindowDidDeminiaturizeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidMinimize:) name:NSWindowDidMiniaturizeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidResignKeyWindow:) name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidBecomeKeyWindow:) name:NSWindowDidBecomeKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_addAccountCreationController:) name:kSRShowAddAccountNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showImageViewer:) name:kSRShowImageViewerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowWillClose:) name:NSWindowWillCloseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_issueSelectionDidChange:) name:kQContextIssueSelectionChangeNotification object:nil];
    
    //[self.window setMovableByWindowBackground:YES];
    self.window.delegate = self;
    
    self.issueDetailCoalescer = [[SRCoalescer alloc] initWithInterval:0.10 name:@"co.cashewapp.issueDetailCoalescer" executionQueue:dispatch_get_main_queue()];
    self.splitViewUserDefaultsCoalescer = [[SRCoalescer alloc] initWithInterval:0.05
                                                                           name:@"co.cashewapp.AppDelegate.splitViewUserDefaultsCoalescer"
                                                                 executionQueue:dispatch_queue_create("co.cashewapp.AppDelegate.splitViewUserDefaultsCoalescer.serialQueue", DISPATCH_QUEUE_SERIAL)];
    
    [QAccountStore addObserver:self];
    [QIssueNotificationStore addObserver:self];
    
    self.repositoriesCloudKitService = [SRRepositoriesCloudKitService new];
    
    self.classicModeSplitView.wantsLayer = true;
    self.classicModeIssueListContainerView.wantsLayer = true;
    self.classicModeDetailsContainerView.wantsLayer = true;
    
    __weak AppDelegate *weakSelf = self;
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        AppDelegate *strongSelf = weakSelf;
        
        if (!strongSelf) {
            return;
        }
        
        NSColor *bgColor = nil;
        NSAppearance *appearance = nil;
        if (mode == SRThemeModeDark) {
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
            strongSelf.modalOverlayView.backgroundColor = [NSColor colorWithWhite:1 alpha:0.5];
            [strongSelf.window setTitlebarAppearsTransparent:YES];
            bgColor = [NSColor colorWithCalibratedWhite:0 alpha:1];
            
        } else {
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            strongSelf.modalOverlayView.backgroundColor = [NSColor colorWithWhite:0 alpha:0.5];
            [strongSelf.window setTitlebarAppearsTransparent:NO];
            bgColor = [NSColor whiteColor];
        }
        
        strongSelf.window.backgroundColor = bgColor;
        strongSelf.window.appearance = appearance;
        strongSelf.classicModeSplitView.appearance = appearance;
        strongSelf.classicModeSplitView.layer.backgroundColor = bgColor.CGColor;
        strongSelf.classicModeIssueListContainerView.appearance = appearance;
        strongSelf.classicModeIssueListContainerView.layer.backgroundColor = bgColor.CGColor;
        strongSelf.classicModeDetailsContainerView.appearance = appearance;
        strongSelf.classicModeDetailsContainerView.layer.backgroundColor = bgColor.CGColor;
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:@(500) forKey:@"NSInitialToolTipDelay"];
    
    if ([NSUserDefaults themeMode] == SRThemeModeDark) {
        [SRAnalytics logCustomEventWithName:@"Running Dark Mode" customAttributes:nil];
    } else {
        [SRAnalytics logCustomEventWithName:@"Running Light Mode" customAttributes:nil];
    }
    
    QAccount *currentAccount = [self _findCurrentSelectedAccount];
    if (currentAccount) {
        NSArray<QRepository *> *repositories = [QRepositoryStore repositoriesForAccountId:currentAccount.identifier];
        if (repositories.count > 0) {
            dispatch_block_t onSuccessulLogin = [self _onSuccessfulLoginBlockForAccount:currentAccount];
            onSuccessulLogin();
        }
    }
    
    [self _checkAuth];
    
    
    //    let picker = NSOpenPanel()
    //    picker.canChooseFiles = true
    //    picker.canChooseDirectories = false
    //    picker.allowsMultipleSelection = true
    //    if picker.runModal() == NSFileHandlingPanelOKButton {
    //        let paths: [String] = picker.URLs.flatMap({ $0.path })
    //        uploadFilePaths(paths)
    //    }
    
    //    NSOpenPanel *picker = [[NSOpenPanel alloc] init];
    //    picker.canChooseFiles = false;
    //    picker.canChooseDirectories = true;
    //    picker.allowsMultipleSelection = false;
    //
    //    NSURL *appDocDir = [self applicationDocumentsDirectory];
    //    NSURL *file = [appDocDir URLByAppendingPathComponent:@"repo.data"];
    //
    //  // if ([picker runModal] == NSFileHandlingPanelOKButton) {
    //        NSError *repositoryError = nil;
    //       //NSURL *url = [[picker URLs] firstObject]; //[NSURL fileURLWithPath:@"/Users/hicham/Code/Cashew"];
    //       NSError *errRead = nil;
    //    NSData *data = [NSData dataWithContentsOfURL:file];
    //       NSURL *url = [NSURL URLByResolvingBookmarkData:data options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:nil error:&errRead];
    //    [url startAccessingSecurityScopedResource];
    ////       NSURL *appDocDir = [self applicationDocumentsDirectory];
    ////       NSURL *file = [appDocDir URLByAppendingPathComponent:@"repo.data"];
    //        GTRepository *repository = [GTRepository repositoryWithURL:url error:&repositoryError];
    //        if (repositoryError != nil) {
    //            NSLog(@"An error occurred: %@", repositoryError);
    //            return;
    //        } else {
    //            NSLog(@"repository = %@ - %@", repository, [url absoluteString]);
    //           // NSError *err;
    //           // NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&err];
    //           // [data writeToURL:file atomically:YES];
    ////            if (err) {
    ////                NSLog(@"bookmark err = %@", err);
    ////            }
    //        }
    //   // }
    //
    
}

- (void)setLayoutMode:(SRLayoutPreference)layoutMode
{
    _layoutMode = layoutMode;
    NSView *detailsContainerView = nil;
    NSView *issuesListContainerView = nil;
    if (self.layoutMode == SRLayoutPreferenceClassic) {
        //self.leftCenterLineSplitterView;
        self.rightCenterLineSplitterView.hidden = true;
        self.rightContainerView.hidden = true;
        self.centerContainerView.hidden = true;
        self.classicModeSplitView.hidden = false;
        //[self.classicModeSplitView.superview addSubview:self.classicModeSplitView positioned:NSWindowAbove relativeTo:nil];
        detailsContainerView = self.classicModeDetailsContainerView;
        issuesListContainerView = self.classicModeIssueListContainerView;
        
        
    } else {
        self.rightCenterLineSplitterView.hidden = false;
        self.rightContainerView.hidden = false;
        self.centerContainerView.hidden = false;
        self.classicModeSplitView.hidden = true;
        
        //        [self.centerContainerView.superview addSubview:self.centerContainerView positioned:NSWindowAbove relativeTo:nil];
        //        [self.rightContainerView.superview addSubview:self.rightContainerView positioned:NSWindowAbove relativeTo:nil];
        //        [self.rightCenterLineSplitterView.superview addSubview:self.rightCenterLineSplitterView positioned:NSWindowAbove relativeTo:nil];
        detailsContainerView = self.rightContainerView;
        issuesListContainerView = self.centerContainerView;
        
        //[self.classicModeSplitView.superview addSubview:self.classicModeSplitView];
    }
    
    if (self.issuesViewController && self.issuesViewController.view.superview && issuesListContainerView != self.issuesViewController.view.superview) {
        [self.issuesViewController.view removeFromSuperview];
        [issuesListContainerView addSubview:self.issuesViewController.view];
        [self.issuesViewController.view pinAnchorsToSuperview];
    }
    
    if (self.issueDetailsViewController && self.issueDetailsViewController.view.superview && detailsContainerView != self.issueDetailsViewController.view.superview) {
        [self.issueDetailsViewController.view removeFromSuperview];
        [detailsContainerView addSubview:self.issueDetailsViewController.view];
        [self.issueDetailsViewController.view pinAnchorsToSuperview];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSUserDefaults.layoutModeKeyPath]) {
        self.layoutMode = [NSUserDefaults layoutModePreference];
    }
}

- (void)_showImageViewer:(NSNotification *)notification
{
    NSArray<NSURL *> *imgURLs = notification.object;
    //guard let imgURLs = imgURLs, issue = notification.userInfo[@""] where imgURLs.count > 0 else { return; }
    QIssue *issue = notification.userInfo[@"issue"];
    if(!issue || !imgURLs || imgURLs.count == 0) {
        return;
    }
    
    if (!self.imageViewerWindowControllers) {
        self.imageViewerWindowControllers = [NSMutableDictionary new];
    }
    
    SRImageViewerWindowController *windowController = self.imageViewerWindowControllers[issue];
    if (!windowController) {
        windowController = [[SRImageViewerWindowController alloc] initWithWindowNibName:@"ImageViewerWindowController"];
        windowController.window.delegate = self;
        windowController.issue = issue;
        self.imageViewerWindowControllers[issue] = windowController;
        [windowController.window makeKeyAndOrderFront:self];
        windowController.imageURLs = imgURLs;
        
        CGFloat windowLeft = self.window.frame.origin.x + self.window.frame.size.width/2.0 - windowController.window.frame.size.width/2.0;
        CGFloat windowTop = self.window.frame.origin.y + self.window.frame.size.height/2.0 - windowController.window.frame.size.height/2.0;
        [windowController.window setFrameOrigin:NSMakePoint(windowLeft, windowTop)];
    } else {
        windowController.imageURLs = imgURLs;
        [windowController.window orderFrontRegardless];
    }
}

- (QAccount *)_findCurrentSelectedAccount
{
    NSArray *accounts = [QAccountStore accounts];
    QAccount *currentAccount = nil;
    for (QAccount *account in accounts) {
        if ([NSUserDefaults q_currentAccountId] != nil && [account.identifier isEqualToNumber:[NSUserDefaults q_currentAccountId]]) {
            currentAccount = account;
            break;
        }
    }
    
    currentAccount = currentAccount ?: [accounts firstObject];
    
    if (currentAccount) {
        [NSUserDefaults q_setCurrentAccountId:currentAccount.identifier];
    }
    
    return currentAccount;
}

- (void)_checkAuth
{
    // show add account page if no account available
    QAccount *currentAccount = [self _findCurrentSelectedAccount];
    if (currentAccount == nil) {
        [self _showAccountCreationController];
    } else {
        QIssueFilter *filter = [QIssueFilter new];
        filter.account = currentAccount;
        [[QContext sharedContext] setCurrentFilter:filter sender:self postNotification:false];
        
        [self.repositoriesCloudKitService syncRepositoriesForAccount:currentAccount onCompletion:^(NSArray<QRepository *> *cloudRepositories, NSError * err) {
            
            NSArray<QRepository *> *repositories = [QRepositoryStore repositoriesForAccountId:currentAccount.identifier];
            if (repositories.count == 0) {
                [self _showRepositoryPickerOnAccountCreationController];
                return;
            }
            
            dispatch_block_t onSuccessulLogin = [self _onSuccessfulLoginBlockForAccount:currentAccount];
            QUserService *userService = [QUserService serviceForAccount:currentAccount];
            [userService currentUserOnCompletion:^(QOwner *owner, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
                if (error || !owner) {
                    if (error && error.code == NSURLErrorNotConnectedToInternet) { // allow offline access
                        onSuccessulLogin();
                    } else {
                        [self _showAccountCreationController];
                    }
                } else {
                    onSuccessulLogin();
                }
            }];
        }];
    }
}

- (dispatch_block_t)_onSuccessfulLoginBlockForAccount:(QAccount *)currentAccount
{
    DDLogDebug(@"AppDelegate onSuccessfulLogin");
    return ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self _setupSourceListViewController];
            [self _setupSearchField];
            
            [self syncForced:false];
            
            QIssueFilter *filter = [QIssueFilter new];
            filter.account = currentAccount;
            [[QContext sharedContext] setCurrentFilter:filter sender:self postNotification:true];
            
            // setup notification manager
            [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
            if (!self.notificationManager) {
                self.notificationManager = [[SRNotificationManager alloc] init];
            }
            
            // show
            [self _setupStatusBar];
            [self.window makeKeyAndOrderFront:self];
            
            // make sure search bar is positioned correctly. shitty hack
            //_searchFieldLeftConstraint.constant = NSWidth(_leftContainerView.frame);
        });
    };
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification;
{
    DDLogDebug(@"Did deliver notification = %@", notification);
    [SRAnalytics logCustomEventWithName:@"Delivered System Notification" customAttributes:nil];
    
    //[[[NSApplication sharedApplication] dockTile] setBadgeLabel:@"2234"];
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification];
    //    });
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification;
{
    DDLogDebug(@"Did activate notification = %@", notification);
    [SRAnalytics logCustomEventWithName:@"Clicked System Notification" customAttributes:nil];
    if (notification.userInfo[@"issueNumber"]  && notification.userInfo[@"accountId"] && notification.userInfo[@"repositoryId"] ) {
        QRepository *repository = [QRepositoryStore repositoryForAccountId:notification.userInfo[@"accountId"] identifier:notification.userInfo[@"repositoryId"]];
        QIssue *issue = [QIssueStore issueWithNumber:notification.userInfo[@"issueNumber"] forRepository:repository];
        [[NSNotificationCenter defaultCenter] postNotificationName:kOpenNewIssueDetailsWindowNotification object:issue];
    } else if (notification.userInfo[@"issuesCount"]) {
        [self.sourceListViewController showNotification];
    }
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

- (void)_windowWillClose:(NSNotification *)notification
{
    if (self.window == notification.object) {
        //[NSApp terminate:self];
    }
}

- (void)_setIssueDetailsViewControllerForIssue:(QIssue *)issue
{
    NSParameterAssert([NSThread isMainThread]);
    // dispatch_block_t block = ^{
    if (self.issueDetailsViewController) {
        [self.issueDetailsViewController.view removeFromSuperview];
        self.issueDetailsViewController = nil;
    }
    
    [self.issueDetailCoalescer executeBlock:^{
        if (!self.issueDetailsViewController) {
            self.issueDetailsViewController = [QIssueDetailsViewController new];
            QView *issueView = (QView *)[self.issueDetailsViewController view];
            
            NSView *containerView = self.layoutMode == SRLayoutPreferenceClassic ? self.classicModeDetailsContainerView : self.rightContainerView;
            
            [containerView addSubview:issueView];
            
            [issueView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [issueView.leftAnchor constraintEqualToAnchor:containerView.leftAnchor].active = YES;
            [issueView.rightAnchor constraintEqualToAnchor:containerView.rightAnchor].active = YES;
            [issueView.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:0].active = YES;
            [issueView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor].active = YES;
        }
        
        [self.issueDetailsViewController setIssue:issue];
    }];
    
    
}

- (NSURL *)applicationDocumentsDirectory
{
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.simplerocket.Queues" in the user's Application Support directory.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    // DDLogDebug(@"APP PATH = %@", path);
    return [NSURL fileURLWithPath:path];
}


#pragma mark - General Setup

- (void)_setupAccountView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        QAccount *currentAccount = [QContext sharedContext].currentAccount;
        
        NSArray<QAccount *> *accounts = [QAccountStore accounts];
        
        NSArray<NSMenuItem *> *existingMenuItems = [[self.accountsPopUpButton.menu itemArray] mutableCopy];
        NSMutableOrderedSet<QAccount *> *existingAccounts = [NSMutableOrderedSet new];
        [existingMenuItems enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
            NSObject *repObject = [menuItem representedObject];
            if (repObject && [repObject isKindOfClass:QAccount.class]) {
                QAccount *existingAccount = (QAccount *)repObject;
                [existingAccounts addObject:existingAccount];
            }
        }];
        
        if (existingAccounts.count == accounts.count && accounts.count > 0) {
            __block BOOL foundMismatch = false;
            [accounts enumerateObjectsUsingBlock:^(QAccount * _Nonnull account, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![existingAccounts containsObject:account]) {
                    foundMismatch = true;
                    *stop = true;
                    return;
                }
            }];
            
            if (!currentAccount || ![existingAccounts.firstObject isEqualToAccount:currentAccount]) {
                foundMismatch = true;
            }
            
            if (!foundMismatch) {
                return;
            }
        }
        
        SRMenu *menu = [SRMenu new];
        
        if (currentAccount != nil) {
            NSMenuItem *firstMenuItem = [[NSMenuItem alloc] initWithTitle:currentAccount.accountName action:@selector(_switchAccount:) keyEquivalent:@""];
            firstMenuItem.representedObject = currentAccount;
            [menu addItem:firstMenuItem];
            
            QOwner *currentUser = [QOwnerStore ownerForAccountId:currentAccount.identifier identifier:currentAccount.userId];
            [[QImageManager sharedImageManager] downloadImageURL:currentUser.avatarURL onCompletion:^(NSImage *image, NSURL *URL, NSError *error) {
                image = [image copy];
                image.size = NSMakeSize(15, 15);
                firstMenuItem.image = [image circularImage];
            }];
            
            
            for (QAccount *anAccount in accounts) {
                if (![anAccount.identifier isEqualToNumber:currentAccount.identifier]) {
                    //[menuItems addObject:];
                    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:anAccount.accountName action:@selector(_switchAccount:) keyEquivalent:@""];
                    menuItem.representedObject = anAccount;
                    
                    QOwner *currentUser = [QOwnerStore ownerForAccountId:anAccount.identifier identifier:anAccount.userId];
                    [[QImageManager sharedImageManager] downloadImageURL:currentUser.avatarURL onCompletion:^(NSImage *image, NSURL *URL, NSError *error) {
                        image = [image copy];
                        image.size = NSMakeSize(15, 15);
                        menuItem.image = [image circularImage];
                    }];
                    
                    [menu addItem:menuItem];
                }
            }
        }
        
        if (menu.numberOfItems > 0) {
            [menu addItem:[NSMenuItem separatorItem]];
        }
        
        NSMenuItem *addAnotherAccountMenuItem = [[NSMenuItem alloc] initWithTitle:@"Add Account" action:@selector(_didClickAddAccountFromMenuItem) keyEquivalent:@""];
        addAnotherAccountMenuItem.image = [NSImage imageNamed:NSImageNameAddTemplate];
        addAnotherAccountMenuItem.image.size = NSMakeSize(10, 10);
        [menu addItem:addAnotherAccountMenuItem];
        
        self.accountsPopUpButton.menu = menu;
    });
}


- (IBAction)didClickBetaFeedbackLabel:(id)sender
{
    DDLogDebug(@"Add Label");
    SRUserFeebackViewController *userFeedbackViewController = [[SRUserFeebackViewController alloc] init];
    
    
    if (self.userFeedbackWindowController) {
        return;
    }
    BaseModalWindowController *windowController = [[BaseModalWindowController alloc] initWithWindowNibName:@"BaseModalWindowController"];
    
    windowController.windowTitle = @"SEND FEEDBACK";
    windowController.darkModeOverrideBackgroundColor = [SRCashewColor backgroundColor];
    windowController.viewController = userFeedbackViewController;
    windowController.baseModalWindowControllerDelegate = self;
    windowController.window.frameAutosaveName = NSStringFromClass(SRUserFeebackViewController.class);
    windowController.window.parentWindow = self.window;
    
    self.userFeedbackWindowController = windowController;
    [windowController.window makeKeyAndOrderFront:self];
}

//- (void)_setupSwitchUserButton
//{
//    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(didClickSwitchAccountButton:)];
//
//    recognizer.numberOfClicksRequired = 1;
//    [self.switchUserContainerView addGestureRecognizer:recognizer];
//}

- (void)_setupStatusBar
{
    if (self.statusItem) {
        return;
    }
    
    self.statusBarViewController = [[SRStatusBarViewController alloc] initWithNibName:@"StatusBarViewController" bundle:nil];
    
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    NSButton *button = [statusItem button];
    NSImage *image = [NSImage imageNamed:@"status_bar_icon"];
    image.size = NSMakeSize(20, 20);
    button.image = image;
    //button.image.template = false;
    button.action = @selector(_didClickStatusItem:);
    
    self.statusItem = statusItem;
    
    [self _updateNotificationDotOnStatusItem];
}

- (void)_didClickStatusItem:(id)sender
{
    NSLog(@"Did click status item %@", sender);
    
    [self _toggleStatusBarPopover];
}

- (void)_closePopover:(id)sender
{
    dispatch_block_t block = ^{
        if (self.statusBarPopover) {
            [self.statusBarPopover close];
            //self.statusBarPopover.contentViewController = nil;
            self.statusBarPopover = nil;
        }
        
        if (self.popoverEventMonitor) {
            [self.popoverEventMonitor stop];
            self.popoverEventMonitor = nil;
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)_showPopover:(id)sender
{
    dispatch_block_t block = ^{
        if (!self.statusBarPopover) {
            self.statusBarPopover = [[NSPopover alloc] init];
            self.statusBarPopover.animates = false;
            self.statusBarPopover.behavior = NSPopoverBehaviorTransient;
            if ([NSUserDefaults themeMode] == SRThemeModeDark) {
                self.statusBarPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
            } else {
                self.statusBarPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            }
            
            self.statusBarPopover.contentViewController = self.statusBarViewController;
            
            __weak AppDelegate *weakSelf = self;
            self.statusBarViewController.didClickCreateIssueAction = ^{
                [weakSelf _closePopover:weakSelf];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf _didClickCreateIssueStatusItemMenuItem:weakSelf];
                });
            };
            
            self.statusBarViewController.didClickQuitAction = ^{
                [NSApp terminate:weakSelf];
            };
            
            self.statusBarViewController.didClickPreferencesAction = ^{
                [weakSelf _showPreferencesWindowControllerWithTab:SRPreferencesTabGeneral];
            };
            
            self.statusBarViewController.didClickShowAppAction = ^{
                [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
                [[weakSelf window] makeKeyAndOrderFront:nil];
                [NSApp activateIgnoringOtherApps:YES];
                //                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //                   [weakSelf _updateNotificationDotOnStatusItem];
                //                });
            };
            
            ///_didClickCreateIssueStatusItemMenuItem
        }
        
        __weak AppDelegate *weakSelf = self;
        self.popoverEventMonitor = [[SREventMonitor alloc] initWithMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:^(NSEvent * event) {
            NSView *contentView = weakSelf.statusBarPopover.contentViewController.view;
            NSRect screenRect = [contentView.window convertRectToScreen:contentView.frame];
            NSPoint locationInWindow = [event locationInWindow];
            NSPoint mousePoint = [contentView.window convertRectToScreen:NSMakeRect(locationInWindow.x, locationInWindow.y, 1, 1)].origin; //[contentView convertPoint:[event locationInWindow] toView:nil];
            if (!NSPointInRect(mousePoint, screenRect)) {
                [weakSelf _closePopover:weakSelf];
            }
        }];
        
        [self.popoverEventMonitor start];
        [self.statusBarPopover showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSMinYEdge];
        self.statusBarPopover.delegate = self;
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)_toggleStatusBarPopover
{
    [self _closePopover:self];
    if (!self.statusBarPopover.shown) {
        //[self _closePopover:self];
        //} else {
        [self _showPopover:self];
    }
}

- (void)_setupModalOverlayView
{
    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_dismissCurrentWindowController:)];
    
    recognizer.numberOfClicksRequired = 1;
    
    [self.modalOverlayView addGestureRecognizer:recognizer];
    
    self.modalOverlayView.disableThemeObserver = true;
}

- (void)_dismissCurrentWindowController:(NSClickGestureRecognizer *)recognizer
{
    if (_currentPresentedBaseModalWindowController) {
        [_currentPresentedBaseModalWindowController.window close];
    }
}

- (void)_setupLineSplitters
{
    [_leftCenterLineSplitterView setDelegate:self];
    [_rightCenterLineSplitterView setDelegate:self];
    
    NSDictionary *state = [NSUserDefaults q_splitViewState];
    if (state) {
        CGFloat left = [state[@"left"] floatValue];
        CGFloat right = [state[@"right"] floatValue];
        [self lineSplitterView:_leftCenterLineSplitterView didMoveToPoint:CGPointMake(left+NSMinX(_leftContainerView.frame), 0)];
        [self lineSplitterView:_rightCenterLineSplitterView didMoveToPoint:CGPointMake(right+NSMinX(_centerContainerView.frame), 0)];
    }
}

- (void)_setupTitleBar
{
    self.window.titleVisibility = NSWindowTitleHidden;
    
    //    NSButton *createIssueImageButton = (NSButton *)self.createIssueToolbarItem.view;
    //
    NSButton *searchBuilderImageButton = (NSButton *)self.searchBuilderButton.view;
    searchBuilderImageButton.image.size = NSMakeSize(17, 12);
    [searchBuilderImageButton.image setTemplate:YES];
    //    searchBuilderImageButton.frame = NSMakeRect(searchBuilderImageButton.frame.origin.x, searchBuilderImageButton.frame.origin.y, createIssueImageButton.frame.size.width, searchBuilderImageButton.frame.size.height);
    //
    //
    NSButton *syncImageButton = (NSButton *)self.syncButton.view;
    //    CGFloat syncDelta = fabs(syncImageButton.frame.size.width - createIssueImageButton.frame.size.width);
    syncImageButton.image.size = NSMakeSize(12, 12);
    [syncImageButton.image setTemplate:YES];
    //    syncImageButton.frame = NSMakeRect(syncImageButton.frame.origin.x + syncDelta, syncImageButton.frame.origin.y, createIssueImageButton.frame.size.width, syncImageButton.frame.size.height);
    //
    [@[self.searchBuilderButton, self.syncButton, self.refreshToolbarItem] enumerateObjectsUsingBlock:^(NSToolbarItem  *item, NSUInteger idx, BOOL * _Nonnull stop) {
        item.minSize = NSMakeSize(45, 34);
        item.maxSize = item.minSize;
    }];
    
    //self.refreshToolbarItem.view.frame = NSMakeRect(self.refreshToolbarItem.view.frame.origin.x - 12, self.refreshToolbarItem.view.frame.origin.y, self.refreshToolbarItem.view.frame.size.width, self.refreshToolbarItem.view.frame.size.height)
    //NSRect searchBarFrame = self.searchBarToolbarItem.view.frame;
    
    
}

- (void)_issueSelectionDidChange:(NSNotification *)notification
{
    
}

- (void)_windowDidResignKeyWindow:(NSNotification *)notification
{
//    [SRAnalytics logCustomEventWithName:@"Did Resign Key Window" customAttributes:nil];
}

- (void)_windowDidBecomeKeyWindow:(NSNotification *)notification
{
//    [SRAnalytics logCustomEventWithName:@"Did Become Key Window" customAttributes:nil];
    //    if (notification.object == self.window) {
    //        [self sync];
    //    }
}


- (void)_windowDidMaximize:(NSNotification *)notification
{
    DDLogDebug(@"window did maximize -> %@", notification.object);
}

- (void)_windowDidMinimize:(NSNotification *)notification
{
    DDLogDebug(@"window did minimize -> %@", notification.object);
    
}

- (void)_windowDidResize:(NSNotification *)notification
{
    // [self _setupTitleBar];
}

- (void)_setupSearchField
{
    if (_searchViewController) {
        return;
    }
    QIssuesSearchViewController *controller = [QIssuesSearchViewController new];
    NSView *controllerView = [controller view];
    self.searchViewController = controller;
    
    NSView *searchBarToolbarView = [self.searchBarToolbarItem view];
    [searchBarToolbarView addSubview:controllerView];
    [controllerView pinAnchorsToSuperview];
    //    controllerView.wantsLayer = true;
    //    controllerView.layer.backgroundColor = NSColor.redColor.CGColor;
    
    //    [controllerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    ////    _searchFieldLeftConstraint = [controllerView.leftAnchor constraintEqualToAnchor:_customTitleBarView.leftAnchor constant:NSWidth(_leftContainerView.frame)];
    ////    _searchFieldLeftConstraint.active = YES;
    //    [controllerView.heightAnchor constraintEqualToConstant:24.0].active = YES;
    //    //[controllerView.widthAnchor constraintEqualToAnchor:_centerContainerView.widthAnchor constant:0].active = YES;
    //    [controllerView.widthAnchor constraintEqualToConstant:500].active = true;
    //    [controllerView.centerYAnchor constraintEqualToAnchor:self.customTitleBarView.centerYAnchor constant:0].active = YES;
    //    [controllerView.centerXAnchor constraintEqualToAnchor:self.customTitleBarView.centerXAnchor constant:0].active = YES;
}

- (void)_setupSourceListViewController
{
    if (!_sourceListViewController) {
        QSourceListViewController *repositiesExplorerViewController = [QSourceListViewController new];
        [repositiesExplorerViewController setDelegate:self];
        
        QView *repositiesExplorerView = (QView *)[repositiesExplorerViewController view];
        [_leftContainerView addSubview:repositiesExplorerView];
        
        [repositiesExplorerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [repositiesExplorerView.leftAnchor constraintEqualToAnchor:_leftContainerView.leftAnchor].active = YES;
        [repositiesExplorerView.rightAnchor constraintEqualToAnchor:_leftContainerView.rightAnchor].active = YES;
        [repositiesExplorerView.topAnchor constraintEqualToAnchor:_leftContainerView.topAnchor].active = YES;
        [repositiesExplorerView.bottomAnchor constraintEqualToAnchor:_leftContainerView.bottomAnchor].active = YES;
        
        _sourceListViewController = repositiesExplorerViewController;
    }
}

#pragma mark - QLineSplitterViewDelegate

- (void)lineSplitterView:(QLineSplitterView *)lineSplitterView didMoveToPoint:(NSPoint)point;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *state = [[NSUserDefaults q_splitViewState] mutableCopy] ?: [NSMutableDictionary dictionary];
        
        if (_leftCenterLineSplitterView == lineSplitterView) {
            CGFloat width = MIN(1000, MAX(240, point.x-NSMinX(_leftContainerView.frame)));
            [_leftContainerViewWidthConstraint setConstant:width];
            // [_searchFieldLeftConstraint setConstant:width];
            state[@"left"] = @(width);
          //  DDLogDebug(@"left.width = %@", @(width));
        } else if (_rightCenterLineSplitterView == lineSplitterView) {
            CGFloat width = MAX(475, point.x-NSMinX(_centerContainerView.frame));
           // DDLogDebug(@"right.width = %@", @(width));
            state[@"right"] = @(width);
            
            [_centerContainerViewWidthConstraint setConstant:width];
        }
        
        [self.splitViewUserDefaultsCoalescer executeBlock:^{
            [NSUserDefaults q_setSplitViewState:state];
        }];
    });
}

#pragma mark - QIssuesViewControllerDelegate

- (void)issuesViewController:(QIssuesViewController *)constroller didSelectIssue:(QIssue *)issue
{
    //DDLogDebug(@"issue = %@", issue);
    [self _setIssueDetailsViewControllerForIssue:issue];
}

- (void)issuesViewController:(QIssuesViewController *)controller keyUp:(NSEvent *)theEvent
{
    // arrow left
    if (theEvent.keyCode == 123) {
        [self.sourceListViewController focus];
    }
}

#pragma mark - QSourceListViewControllerDelegate

- (void)_didContextIssueFilterChange:(NSNotification *)notification
{
    QAccount *newCurrentAccount = [QContext sharedContext].currentAccount;
    
#ifndef DEBUG
    NSNumber *userId = [newCurrentAccount userId];
    if (userId) {
        [CrashlyticsKit setUserIdentifier:[NSString stringWithFormat:@"%@", userId]];
    } else {
        [CrashlyticsKit setUserIdentifier:nil];
    }
#endif
    
    // never force sync if sender is AppDelegate. This helps prevent syncher running on startup. Need the delay for fast boot
    if (notification.object != self && ( !self.currentAccount || (newCurrentAccount && ![newCurrentAccount isEqual:self.currentAccount]) )) {
        [self syncForced:false];
    }
    
    self.currentAccount = newCurrentAccount;
    [self _setupIssueViewWithCurrentIssueFilter];
    [self _setupAccountView];
    [self _updateNotificationDotOnStatusItem];
}

- (void)_setupIssueViewWithCurrentIssueFilter
{
    if (self.issuesViewController == nil) {
        QIssuesViewController *controller = [QIssuesViewController new];
        self.issuesViewController = controller;
        [controller setDelegate:self];
        QView *issueView = (QView *)[self.issuesViewController view];
        NSView *containerView = self.layoutMode == SRLayoutPreferenceClassic ? self.classicModeIssueListContainerView : self.centerContainerView;
        [containerView addSubview:issueView];
        [issueView pinAnchorsToSuperview];
        
        //        issueView.translatesAutoresizingMaskIntoConstraints = false;
        //        [issueView.leftAnchor constraintEqualToAnchor:_centerContainerView.leftAnchor].active = YES;
        //        [issueView.rightAnchor constraintEqualToAnchor:_centerContainerView.rightAnchor].active = YES;
        //        [issueView.topAnchor constraintEqualToAnchor:_centerContainerView.topAnchor constant:-1].active = YES;
        //        [issueView.bottomAnchor constraintEqualToAnchor:_centerContainerView.bottomAnchor].active = YES;
    }
    
    QIssueFilter *filter = [[QContext sharedContext] currentFilter];
    [NSUserDefaults q_setCurrentAccountId:filter.account.identifier];
    
    [self.issuesViewController setFilter:filter];
}

- (IBAction)didClickAddMilestoneInMenuItem:(id)sender
{
    [self _showMilestonePickerView];
}

- (IBAction)didClickAddAssigneeInMenuItem:(id)sender
{
    [self _showAssigneePickerView];
}

- (IBAction)didClickAddLabelInMenuItem:(id)sender
{
    [self _showLabelPickerView];
}

- (void)didClickAddLabelInSourceListViewController:(QSourceListViewController *)controller
{
    [self _showLabelPickerView];
}

- (NSArray<QIssue *> *)_currentIssues
{
    //return [self.window isKeyWindow] ?  : @[];
    
    if ([self.window isKeyWindow]) {
        return [QContext sharedContext].currentIssues;
    } else {
        __block QIssueDetailsViewController *issueDetailViewController = nil;
        [[NSApp windows] enumerateObjectsUsingBlock:^(NSWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([window isKeyWindow] && [[window windowController] isKindOfClass:BaseModalWindowController.class]) {
                BaseModalWindowController *windowController = (BaseModalWindowController *)window.windowController;
                if ([[windowController viewController] isKindOfClass:QIssueDetailsViewController.class]) {
                    issueDetailViewController = (QIssueDetailsViewController *)[windowController viewController];
                    *stop = true;
                }
            }
        }];
        
        QIssue *issue = [issueDetailViewController issue];
        if (issue) {
            return @[issue];
        }
        
    }
    
    return @[];
}

- (void)_showMilestonePickerView
{
    if ([self _currentIssues].count == 0) {
        return;
    }
    SRMilestoneSearchablePickerViewController *milestonePickerController = [[SRMilestoneSearchablePickerViewController alloc] init];
    milestonePickerController.popoverBackgroundColorFixEnabed = false;
    //[labelsPickerController presentViewControllerInWindowControllerModallyWithTitle:@"SELECT LABELS"];
    
    
    if (self.milestonePickerWindowController) {
        return;
    }
    [self.issuesViewController reloadContextIssueSelection];
    
    //MilestonePickerViewController *pickerViewController = [MilestonePickerViewController new];
    BaseModalWindowController *windowController = [[BaseModalWindowController alloc] initWithWindowNibName:@"BaseModalWindowController"];
    
    windowController.windowTitle = @"SELECT MILESTONE";
    windowController.viewController = milestonePickerController;
    windowController.baseModalWindowControllerDelegate = self;
    windowController.window.frameAutosaveName = NSStringFromClass(SRMilestoneSearchablePickerViewController.class);
    windowController.window.parentWindow = self.window;
    
    self.milestonePickerWindowController = windowController;
    //windowController.window.level = NSFloatingWindowLevel;
    [windowController.window makeKeyAndOrderFront:self];
}

- (void)_showAssigneePickerView
{
    if ([self _currentIssues].count == 0) {
        return;
    }
    
    SRAssigneeSearchablePickerViewController *assigneePickerView = [[SRAssigneeSearchablePickerViewController alloc] init];
    assigneePickerView.popoverBackgroundColorFixEnabed = false;
    //[labelsPickerController presentViewControllerInWindowControllerModallyWithTitle:@"SELECT LABELS"];
    
    
    if (self.assigneePickerWindowController) {
        return;
    }
    [self.issuesViewController reloadContextIssueSelection];
    
    //MilestonePickerViewController *pickerViewController = [MilestonePickerViewController new];
    BaseModalWindowController *windowController = [[BaseModalWindowController alloc] initWithWindowNibName:@"BaseModalWindowController"];
    
    windowController.windowTitle = @"SELECT ASSIGNEE";
    windowController.viewController = assigneePickerView;
    windowController.baseModalWindowControllerDelegate = self;
    windowController.window.frameAutosaveName = NSStringFromClass(SRAssigneeSearchablePickerViewController.class);
    windowController.window.parentWindow = self.window;
    
    self.assigneePickerWindowController = windowController;
    //windowController.window.level = NSFloatingWindowLevel;
    [windowController.window makeKeyAndOrderFront:self];
}

- (void)_showLabelPickerView
{
    if ([self _currentIssues].count == 0) {
        return;
    }
    
    DDLogDebug(@"Add Label");
    SRLabelSearchablePickerViewController *labelsPickerController = [[SRLabelSearchablePickerViewController alloc] init];
    labelsPickerController.popoverBackgroundColorFixEnabed = false;
    //[labelsPickerController presentViewControllerInWindowControllerModallyWithTitle:@"SELECT LABELS"];
    
    
    if (self.labelsPickerWindowController) {
        return;
    }
    [self.issuesViewController reloadContextIssueSelection];
    
    //MilestonePickerViewController *pickerViewController = [MilestonePickerViewController new];
    BaseModalWindowController *windowController = [[BaseModalWindowController alloc] initWithWindowNibName:@"BaseModalWindowController"];
    
    windowController.windowTitle = @"SELECT LABELS";
    windowController.viewController = labelsPickerController;
    windowController.baseModalWindowControllerDelegate = self;
    windowController.window.frameAutosaveName = NSStringFromClass(SRLabelSearchablePickerViewController.class);
    windowController.window.parentWindow = self.window;
    
    self.labelsPickerWindowController = windowController;
    //  windowController.window.level = NSFloatingWindowLevel;
    [windowController.window makeKeyAndOrderFront:self];
}

- (void)didClickAddAccountInSourceListViewController:(QSourceListViewController *)controller;
{
    [self _addAccountCreationController:nil];
}

- (void)_didClickAddAccountFromMenuItem
{
    [self _addAccountCreationController:nil];
}

- (void)_showAccountCreationController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_currentPresentedBaseModalWindowController) {
            return;
        }
        [self _stopSynching];
        
        
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
        self.statusItem = nil;
        
        [[SRMilestoneCache sharedCache] removeAll];
        [[SRAccountCache sharedCache] removeAll];
        [[SRLabelCache sharedCache] removeAll];
        [[SROwnerCache sharedCache] removeAll];
        
        // Hide
        [self.window orderOut:self];
        
        [self _resetAllControllers];
        [self _setupSourceListViewController];
        [self _addAccountCreationController:nil];
    });
}

- (void)_addAccountCreationController:(NSNotification *)notification
{
    void(^centerWindow)(NSWindow *) = ^(NSWindow *win) {
        NSWindow *mainAppWindow = NSApp.windows[0];
        CGFloat windowLeft = mainAppWindow.frame.origin.x + mainAppWindow.frame.size.width/2.0 - win.frame.size.width/2.0;
        CGFloat windowTop = mainAppWindow.frame.origin.y + mainAppWindow.frame.size.height/2.0 - win.frame.size.height/2.0;
        [win setFrameOrigin:NSMakePoint(windowLeft, windowTop)];
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        if (_currentPresentedBaseModalWindowController) {
            if (![self.currentPresentedBaseModalWindowController.window isKeyWindow] && [self.window isKeyWindow]) {
                centerWindow(self.currentPresentedBaseModalWindowController.window);
                [self.currentPresentedBaseModalWindowController.window makeKeyAndOrderFront:self];
            }
            return;
        }
        QAccountCreationWindowController *accountCreationWindowController = [[QAccountCreationWindowController alloc] initWithWindowNibName:@"QAccountCreationWindowController"];
        self.currentPresentedBaseModalWindowController = accountCreationWindowController;
        
        if ([notification object]) {
            accountCreationWindowController.showSessionExpiredForAccount = notification.object;
        }
        
        [accountCreationWindowController setDelegate:self];
        centerWindow(accountCreationWindowController.window);
        
        [self fadeInModalOverlayOnCompletion:^{
            [accountCreationWindowController presentModalWindow];
        } animated:NO];
    });
}

- (void)_showRepositoryPickerOnAccountCreationController
{
    // [self _stopSynching];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_currentPresentedBaseModalWindowController) {
            return;
        }
        // Hide
        [self.window orderOut:self];
        
        [self _resetAllControllers];
        
        QAccountCreationWindowController *accountCreationWindowController = [[QAccountCreationWindowController alloc] initWithWindowNibName:@"QAccountCreationWindowController"];
        [accountCreationWindowController setDelegate:self];
        accountCreationWindowController.showRepositoryPickerAccount = [QContext sharedContext].currentAccount;
        _currentPresentedBaseModalWindowController = accountCreationWindowController;
        [self fadeInModalOverlayOnCompletion:^{
            [accountCreationWindowController presentModalWindow];
            
        } animated:NO];
    });
}


- (void)didClickAddRepositoryInSourceListViewController:(QSourceListViewController *)controller
{
    SRRepositorySearchablePickerViewController *repositoryPickerController = [[SRRepositorySearchablePickerViewController alloc] init];
    //  [repositoryPickerController presentViewControllerInWindowControllerModallyWithTitle:@"SELECT REPOSITORIES"];
    
    // SRLabelSearchablePickerViewController *labelsPickerController = [[SRLabelSearchablePickerViewController alloc] init];
    //[labelsPickerController presentViewControllerInWindowControllerModallyWithTitle:@"SELECT LABELS"];
    
    
    if (self.repositoriesPickerWindowController) {
        [self.repositoriesPickerWindowController close];
        self.repositoriesPickerWindowController = nil;
    }
    
    //MilestonePickerViewController *pickerViewController = [MilestonePickerViewController new];
    BaseModalWindowController *windowController = [[BaseModalWindowController alloc] initWithWindowNibName:@"BaseModalWindowController"];
    
    windowController.windowTitle = @"SELECT REPOSITORIES TO SYNC LOCALLY";
    windowController.viewController = repositoryPickerController;
    windowController.baseModalWindowControllerDelegate = self;
    windowController.window.parentWindow = self.window;
    
    self.repositoriesPickerWindowController = windowController;
    //  windowController.window.level = NSFloatingWindowLevel;
    [windowController.window makeKeyAndOrderFront:self];
}


- (void)sourceListViewController:(QSourceListViewController *)controller keyUp:(NSEvent *)theEvent
{
    if ([[self.window firstResponder] isKindOfClass:NSTextField.class] || [[self.window firstResponder] isKindOfClass:NSTextView.class]) {
        return;
    }
    
    // arrow right
    if (theEvent.keyCode == 124) {
        [_issuesViewController focus];
    }
    
    //    // '/'
    //    else if (theEvent.keyCode == 44) {
    //        [_searchViewController focus];
    //    }
}


#pragma mark - CashewAppDelegate

- (void)dismissWindowWithViewController:(nonnull NSViewController *)viewController;
{
    
}

- (void)presentWindowWithViewController:(NSViewController *)viewController title:(NSString *)title onCompletion:(dispatch_block_t)onCompletion
{
    if (self.currentPresentedBaseModalWindowController) {
        [self.currentPresentedBaseModalWindowController close];
        self.currentPresentedBaseModalWindowController = nil;
    }
    
    BaseModalWindowController *windowController = [[BaseModalWindowController alloc] initWithWindowNibName:@"BaseModalWindowController"];
    
    windowController.windowTitle = title;
    windowController.viewController = viewController;
    windowController.baseModalWindowControllerDelegate = self;
    
    self.currentPresentedBaseModalWindowController = windowController;
    windowController.window.level = NSFloatingWindowLevel;
    [windowController presentModalWindow];
}

- (void)fadeOutModalOverlayOnCompletion:(dispatch_block_t)onCompletion;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSParameterAssert(self.modalOverlayView.superview);
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            self.modalOverlayView.animator.alphaValue = 0;
        } completionHandler:^{
            NSView *currentSuperView = self.modalOverlayView.superview;
            [currentSuperView addSubview:self.modalOverlayView positioned:NSWindowBelow relativeTo:nil];
            if (onCompletion) {
                onCompletion();
            }
        }];
    });
}


- (void)syncForced:(BOOL)forced;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        (void)[SRIssueNotificationSyncer sharedIssueNotificationSync];
        [[SRRepositorySyncController sharedController] start:forced];
    });
}

- (void)_stopSynching
{
    [[SRRepositorySyncController sharedController] stop];
}

- (void)fadeInModalOverlayOnCompletion:(dispatch_block_t)onCompletion animated:(BOOL) animated;
{
    dispatch_block_t block = ^{
        NSParameterAssert(self.modalOverlayView.superview);
        self.modalOverlayView.userInteractionEnabled = NO;
        self.modalOverlayView.alphaValue = 0;
        NSView *currentSuperView = self.modalOverlayView.superview;
        [currentSuperView addSubview:self.modalOverlayView positioned:NSWindowAbove relativeTo:nil];
        
        if (animated) {
            
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                self.modalOverlayView.animator.alphaValue = 1.0;
            } completionHandler:^{
                if (onCompletion) {
                    onCompletion();
                }
            }];
        } else {
            self.modalOverlayView.alphaValue = 1.0;
            if (onCompletion) {
                onCompletion();
            }
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


#pragma mark - QAccountCreationWindowControllerDelegate

//- (void)didSuccessfullySigninInAccountCreationWindowController:(QAccountCreationWindowController *)controller;
- (void)creationWindowController:(QAccountCreationWindowController *)controller didSignInToAccount:(QAccount *)account
{
    [self _onSuccessfulLoginBlockForAccount:account]();
}

- (void)willCloseAccountCreationWindowController:(QAccountCreationWindowController *)controller;
{
    [self fadeOutModalOverlayOnCompletion:nil];
    if (_currentPresentedBaseModalWindowController == controller) {
        _currentPresentedBaseModalWindowController = nil;
    }
}

#pragma mark - BaseModalWindowControllerDelegate

- (void)willCloseBaseModalWindowController:(BaseModalWindowController *)baseModalWindowController
{
    [self fadeOutModalOverlayOnCompletion:nil];
    if (_currentPresentedBaseModalWindowController == baseModalWindowController) {
        _currentPresentedBaseModalWindowController = nil;
    }
    
    if (baseModalWindowController == self.repositoriesPickerWindowController) {
        self.repositoriesPickerWindowController = nil;
    }
    
    if (baseModalWindowController == self.labelsPickerWindowController) {
        self.labelsPickerWindowController = nil;
    }
    
    if (baseModalWindowController == self.milestonePickerWindowController) {
        self.milestonePickerWindowController = nil;
    }
    
    if (baseModalWindowController == self.assigneePickerWindowController) {
        self.assigneePickerWindowController = nil;
    }
    
    if (baseModalWindowController == self.userFeedbackWindowController) {
        self.userFeedbackWindowController = nil;
    }
    
    [self.issuesViewController reloadContextIssueSelection];
}

#pragma mark - NSWindowDelegate
- (void)windowWillStartLiveResize:(NSNotification *)notification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kQWindowWillStartLiveNotificationNotification object:notification.object];
}

- (void)windowDidEndLiveResize:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kQWindowDidEndLiveNotificationNotification object:notification.object];
}

- (void)windowDidChangeScreen:(NSNotification *)notification;
{
    if (notification.object == self.window) {
        DDLogDebug(@"Window did change screen");
        [self.window.contentView setNeedsDisplay:YES];
        [self.window.contentView setNeedsLayout:YES];
        [self.window.contentView layoutSubtreeIfNeeded];
    }
}

- (BOOL)windowShouldClose:(id)sender;
{
    if (sender == self.preferencesWindowController.window) {
        self.preferencesWindowController = nil;
        return YES;
    }
    
    __block QIssue *foundIssueForImageViewerWindowController = nil;
    [self.imageViewerWindowControllers enumerateKeysAndObjectsUsingBlock:^(QIssue * _Nonnull key, SRImageViewerWindowController * _Nonnull windowController, BOOL * _Nonnull stop) {
        if (windowController.window == sender){
            foundIssueForImageViewerWindowController = key;
            *stop = true;
            return;
        }
    }];
    
    if (foundIssueForImageViewerWindowController) {
        [self.imageViewerWindowControllers removeObjectForKey:foundIssueForImageViewerWindowController];
        return true;
    }
    
    if (sender == self.window) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        return NO;
    }
    
    
    return YES;
}

#pragma mark - Actions


// NEEDED. Do not delete
- (IBAction)sr_dummyExtensionsAction:(id)sender { }
- (IBAction)sr_dummyShareAction:(id)sender { }

//
//- (IBAction)didClickCheckForUpdates:(id)sender
//{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//
//        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//        [request setHTTPMethod:@"GET"];
//        NSString *url = @"http://itunes.apple.com/us/lookup?id=1126100185";
//        [request setURL:[NSURL URLWithString:url]];
//
//        NSError *error = nil;
//        NSHTTPURLResponse *responseCode = nil;
//
//
//        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
//
//
//        if (!error && [responseCode statusCode] == 200) {
//            //NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
//            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
//
//            if (!error && json) {
//                NSString *appStoreVersion = json[@"results"][0][@"version"];
//                NSString *currentVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
//                DDLogDebug(@"Mac App Store Version = %@ vs current version = %@", appStoreVersion, currentVersion);
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    if ([currentVersion isEqualToString:@""]) {
//                        [NSAlert showOKMessage:@"You’re up-to-date!" body:[NSString stringWithFormat:@"Cashew %@ is currently the newest version available.", currentVersion] onCompletion:nil];
//                    } else {
//                        [NSAlert showWarningMessage:@"New update found!" body:@"Found a newer Cashew version in the App Store. Open Mac App Store?" onConfirmation:^{
//                            NSURL *url = [NSURL URLWithString:@"macappstore://itunes.apple.com/app/id1126100185"];
//                            [[NSWorkspace sharedWorkspace] openURL:url];
//                        }];
//                    }
//
//                });
//            }
//        }
//
//    });
//}

- (IBAction)didClickSyncButton:(id)sender
{
    
}

- (IBAction)didClickSearchBuilderButton:(id)sender
{
    
    if (!self.searchBuilderPopover) {
        self.searchBuilderPopover = [[NSPopover alloc] init];
        self.searchBuilderPopover.animates = true;
        self.searchBuilderPopover.behavior = NSPopoverBehaviorTransient;
        self.searchBuilderViewController = [[SRSearchBuilderViewController alloc] initWithNibName:@"SearchBuilderViewController" bundle:nil];
        
        self.searchBuilderPopover.contentViewController = self.searchBuilderViewController;
        self.searchBuilderViewController.popover = self.searchBuilderPopover;
    }
    
    self.searchBuilderViewController.dataSource = [SRStandardSearchBuilderViewControllerDataSource new];
    //  self.searchBuilderPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    
    if ([NSUserDefaults themeMode] == SRThemeModeDark) {
        self.searchBuilderPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]; //[NSAppearance appearanceNamed:NSAppearanceNameAqua];
        //self.searchBuilderViewController.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    } else {
        self.searchBuilderPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        //self.searchBuilderViewController.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }
    
    self.searchBuilderViewController.view.appearance = self.searchBuilderPopover.appearance;
    
    [self.searchBuilderViewController.dataSource resetCache];
    [self.searchBuilderPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
    self.searchBuilderPopover.delegate = self;
}

- (IBAction)didClickAccountsToolbarItemButton:(id)sender
{
    
    
}


//- (IBAction)didClickCreateIssueToolbarItemButton:(id)sender
//{
//    [self _showCreateIssueWindowController:nil];
//}

- (IBAction)didClickRefreshToolbarItemButton:(id)sender
{
    QIssueFilter *currentFilter = [QContext sharedContext].currentFilter;
    [[QContext sharedContext] setCurrentFilter:currentFilter.copy];
}



- (SRMarkdownEditorTextView *)_markdownEditorTextViewIfFirstResponder
{
    
    __block NSWindow *keyWindow = nil;
    NSArray<NSWindow *> *windows = [[NSApp windows] sortedArrayUsingComparator:^NSComparisonResult(NSWindow *obj1, NSWindow *obj2) {
        if ([obj1 isKindOfClass:SRBaseWindow.class] && [obj2 isKindOfClass:SRBaseWindow.class]) {
            return NSOrderedSame;
        }
        
        if ([obj1 isKindOfClass:SRBaseWindow.class]) {
            return NSOrderedAscending;
        }
        
        if ([obj2 isKindOfClass:SRBaseWindow.class]) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    [windows enumerateObjectsUsingBlock:^(NSWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([window isKeyWindow]) {
            keyWindow = window;
            *stop = true;
        }
    }];
    NSResponder *firstResponder = [keyWindow firstResponder];
    if (firstResponder && [firstResponder isKindOfClass:NSTextView.class]) {
        NSTextView *textView = (NSTextView *)firstResponder;
        NSView *containerView = [[[textView superview] superview] superview];  // Yep, I'm hacking!
        if ([containerView isKindOfClass:SRMarkdownEditorTextView.class]) {
            SRMarkdownEditorTextView *markdownEditorTextView = (SRMarkdownEditorTextView *)containerView;
            return markdownEditorTextView;
        }
    }
    return nil;
}


- (IBAction)didClickBoldMenuItem:(id)sender
{
    SRMarkdownEditorTextView *textView = [self _markdownEditorTextViewIfFirstResponder];
    if (!textView) {
        return;
    }
    [textView boldSelectedText];
}

- (IBAction)didClickItalicMenuItem:(id)sender
{
    SRMarkdownEditorTextView *textView = [self _markdownEditorTextViewIfFirstResponder];
    if (!textView) {
        return;
    }
    [textView italicSelectedText];
}

- (IBAction)didClickBiggerMenuItem:(id)sender
{
    
}

- (IBAction)didClickSmallerMenuItem:(id)sender {
    
}

- (IBAction)didClickLinkMenuItem:(id)sender
{
    SRMarkdownEditorTextView *textView = [self _markdownEditorTextViewIfFirstResponder];
    if (!textView) {
        return;
    }
    [textView linkSelectedText];
}

- (IBAction)didClickReloadSearchResults:(id)sender
{
    QIssueFilter *currentFilter = [QContext sharedContext].currentFilter;
    
    [[QContext sharedContext] setCurrentFilter:currentFilter.copy];
}

- (IBAction)_didClickShowPreferences:(id)sender
{
    [self _showPreferencesWindowControllerWithTab:SRPreferencesTabGeneral];
}

- (void)_showPreferencesWindowControllerWithTab:(SRPreferencesTab)tab
{
    if (!self.preferencesWindowController) {
        self.preferencesWindowController = [[SRPreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
        self.preferencesWindowController.onWindowLoadPreferenceTab = tab;
        self.preferencesWindowController.window.delegate = self;
    }
    [self.preferencesWindowController.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    
    if ([NSApp activationPolicy] == NSApplicationActivationPolicyAccessory) {
        [self.window orderOut:self];
    }
}

- (void)_switchAccount:(id)sender
{
    if (![sender isKindOfClass:NSMenuItem.class]) {
        return;
    }
    
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    
    // DDLogDebug(@"switch account -> %@", menuItem.representedObject);
    if (![menuItem.representedObject isKindOfClass:QAccount.class]) {
        return;
    }
    
    QIssueFilter *filter = [QIssueFilter new];
    filter.account = menuItem.representedObject;
    [[QContext sharedContext] setCurrentFilter:filter sender:nil postNotification:true];
}

/*
 - (void)a_signout:(id)sender
 {
 QAccount *account = [QContext sharedContext].currentFilter.account;
 
 NSParameterAssert(account);
 
 if (_syncTimer) {
 [_syncTimer invalidate];
 _syncTimer = nil;
 }
 
 QUserService *userService = [QUserService serviceForAccount:account];
 [userService logoutUserOnCompletion:^(id  _Nullable obj, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
 dispatch_async(dispatch_get_main_queue(), ^{
 [NSUserDefaults q_deleteCurrentAccountId];
 [[QContext sharedContext] removeAccount:account];
 [self _showAccountCreationController];
 });
 }];
 }
 */

- (void)_resetAllControllers
{
    NSArray *controllers = @[self.sourceListViewController ?: NSNull.null, self.issuesViewController ?: NSNull.null, self.issueDetailsViewController ?: NSNull.null, self.searchViewController ?: NSNull.null];
    [controllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSViewController.class]) {
            NSViewController *viewController = (NSViewController *)obj;
            [viewController removeFromParentViewController];
            [viewController.view removeFromSuperview];
        }
    }];
    
    self.sourceListViewController = nil;
    self.issuesViewController = nil;
    self.issueDetailsViewController = nil;
    self.searchViewController = nil;
    
    [self _setupIssueViewWithCurrentIssueFilter];
}

- (IBAction)_didClickNewIssue:(id)sender
{
    [self _showCreateIssueWindowController:nil];
}

- (void)didUseNewIssueHotKey {
    DDLogDebug(@"Delegate didUseNewIssueHotKey");
    [self _showCreateIssueWindowController:nil];
}

- (void)_terminateApp:(id)sender {
    //[NSApp terminate:nil];
}

- (void)_didClickCreateMilestoneStatusItemMenuItem:(id)sender
{
    DDLogDebug(@"Did click create milestone");
}

- (void)_didClickNotificationsStatusItemMenuItem:(id)sender
{
    [SRAnalytics logCustomEventWithName:@"Clicked Notifications Menu Item" customAttributes:nil];
    [self.sourceListViewController showNotification];
}

- (void)_didClickFavoritesStatusItemMenuItem:(id)sender
{
    [SRAnalytics logCustomEventWithName:@"Clicked Favorites Menu Item" customAttributes:nil];
    [self.sourceListViewController showFavorites];
}

- (void)_didClickCreateIssueStatusItemMenuItem:(id)sender
{
    [SRAnalytics logCustomEventWithName:@"Clicked Create Issue Menu Item" customAttributes:nil];
    NSRect eventFrame = [[self.statusItem valueForKey:@"window"] frame];
    CGPoint eventOrigin = eventFrame.origin;
    CGSize eventSize = eventFrame.size;
    
    // Create a window controller from your xib file and get the window reference
    if (!self.createIssueWindowController.window.isVisible) {
        NewIssueWindowController *controller = [[NewIssueWindowController alloc] initWithWindowNibName:@"NewIssueWindowController"];
        self.createIssueWindowController = controller;
        DDLogDebug(@"Did show click new issue");
    }
    NSWindow *window = [self.createIssueWindowController window];
    
    // Calculate the position of the window to place it centered below of the status item
    CGRect windowFrame = window.frame;
    CGSize windowSize = windowFrame.size;
    CGPoint windowTopLeftPosition = CGPointMake(eventOrigin.x + eventSize.width/2.f - windowSize.width/2.f, eventOrigin.y - 20);
    
    // Set position of the window and display it
    [window setFrameTopLeftPoint:windowTopLeftPosition];
    [window makeKeyAndOrderFront:self];
    //[NSApp deactivate];
    
    // Show your window in front of all other apps
    [NSApp activateIgnoringOtherApps:YES];
    if ([NSApp activationPolicy] == NSApplicationActivationPolicyAccessory) {
        [self.window orderOut:self];
    }
}

- (void)_showCreateIssueWindowController:(NSNotification *)notification
{
    DDLogDebug(@"Delegate showCreateIssueWindowController");
    [NSApp activateIgnoringOtherApps:YES];
    if (!self.createIssueWindowController.window.isVisible) {
        NewIssueWindowController *controller = [[NewIssueWindowController alloc] initWithWindowNibName:@"NewIssueWindowController"];
        self.createIssueWindowController = controller;
        // self.createIssueWindowController.window.parentWindow = self.window;
        QIssueFilter *filter = notification.userInfo[@"issueFilter"];
        NSObject *representedObject = notification.userInfo[@"representedObject"];
        
        // use current issue
        if (!filter && self.issueDetailsViewController.issue) {
            QIssue *issue = self.issueDetailsViewController.issue;
            
            filter = [QIssueFilter new];
            filter.repositories = [NSOrderedSet orderedSetWithObject:issue.repository.fullName];
            if (issue.assignee.login) {
                filter.assignees = [NSOrderedSet orderedSetWithObject:issue.assignee.login];
            }
            filter.labels = [NSOrderedSet orderedSetWithArray:[issue.labels valueForKey:@"name"]];
            if (issue.milestone.title) {
                filter.milestones = [NSOrderedSet orderedSetWithObject:issue.milestone.title];
            }
            filter.account = issue.account;
        }
        
        if (representedObject) {
            if ([representedObject isKindOfClass:QMilestone.class]) {
                QMilestone *milestone = (QMilestone *)representedObject;
                CreateIssueRequest *request = [CreateIssueRequest new];
                request.repositoryFullName = milestone.repository.fullName;
                request.milestoneNumber = milestone.number;
                self.createIssueWindowController.request = request;
                
            } else if ([representedObject isKindOfClass:QRepository.class]) {
                QRepository *repo = (QRepository *)representedObject;
                CreateIssueRequest *request = [CreateIssueRequest new];
                request.repositoryFullName = repo.fullName;
                self.createIssueWindowController.request = request;
            }
        }
        
        if (filter && !self.createIssueWindowController.request) {
            //QIssueFilter *filter = notification.userInfo[@"issueFilter"];
            CreateIssueRequest *request = [CreateIssueRequest new];
            
            request.repositoryFullName = [filter.repositories firstObject];
            request.assigneeLogin = [filter.assignees firstObject];
            request.labels = filter.labels.array;
            
            NSString *milestoneName = [filter.milestones firstObject];
            if (request.repositoryFullName && milestoneName) {
                QRepository *repo = [QRepositoryStore repositoryForAccountId:filter.account.identifier fullName:request.repositoryFullName];
                NSArray<QMilestone *> *milestones = [QMilestoneStore milestonesForAccountId:filter.account.identifier repositoryId:repo.identifier includeHidden:false];
                for (QMilestone *milestone in milestones) {
                    if ([milestone.title isEqualToString:milestoneName]) {
                        request.milestoneNumber = milestone.number;
                        break;
                    }
                }
            }
            
            self.createIssueWindowController.request = request;
        }
        //[controller showWindow:self];
        [controller.window makeKeyAndOrderFront:self];
    } else if (self.createIssueWindowController) {
        [self.createIssueWindowController.window orderFrontRegardless];
    }
}

#pragma mark - SRStatusImageViewDelegate
- (void)statusItemImageView:(SRStatusImageView *)imageView didPastePaths:(NSArray<NSString *> *)paths;
{
    [self _didClickCreateIssueStatusItemMenuItem:self];
    [self.createIssueWindowController.newIssueViewController.descriptionTextView uploadFilePaths:paths];
}

#pragma mark - Menu Items


- (void)sr_executeIssueCodeExtension:(id)sender
{
    [self.issuesViewController reloadContextIssueSelection];
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    NSMutableArray<NSDictionary *> *models = [NSMutableArray new];
    [currentIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
        [models addObject:issue.toExtensionModel];
    }];
    
    if (models.count == 0) {
        return;
    }
    
    [self.codeExtensionRunner runWithIssues:models sourceCode:[[sender representedObject] sourceCode]];
    //[[[SRIssueExtensionsJSContextRunner alloc] init] runWithIssues:models codeExtension:[sender representedObject]];
}

- (IBAction)sr_favoriteIssues:(id)sender
{
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    [currentIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [QIssueFavoriteStore favoriteIssue:obj];
        [SRAnalytics logCustomEventWithName:@"Favorite Issue" customAttributes:nil];
    }];
}

- (IBAction)sr_unfavoriteIssues:(id)sender
{
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    [currentIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [QIssueFavoriteStore unfavoriteIssue:obj];
        [SRAnalytics logCustomEventWithName:@"Unfavorite Issue" customAttributes:nil];
    }];
}

- (IBAction)didClickRepositoryPickerViewMenuItem:(id)sender
{
    [self didClickAddRepositoryInSourceListViewController:self.sourceListViewController];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    [self.issuesViewController reloadContextIssueSelection];
    
    if (self.shareIssueMenuItem == menuItem) {
        [SRMenuUtilities setupShareMenuItem:self.shareIssueMenuItem];
    }
    
    if (self.issueExtensionsMenuItem == menuItem) {
        [SRMenuUtilities setupExtensionMenuItem:self.issueExtensionsMenuItem];
    }
    
    if (menuItem.action == @selector(sr_manageExtensions:) || menuItem.action == @selector(sr_viewExtensionLogs:)) {
        return YES;
    }
    
    if (menuItem.action == @selector(sr_shareFromService:)) {
        NSArray *itemsForSharingService = [SRMenuUtilities selectedIssueItemsForSharingService];
        return itemsForSharingService.count > 0;
    }
    
    if (menuItem.action == @selector(sr_closeIssues:) || menuItem.action == @selector(sr_reopenIssues:)) {
        return [self _setupCloseOpenMenuItem:menuItem];
    }
    
    if (menuItem.action == @selector(sr_favoriteIssues:) || menuItem.action == @selector(sr_unfavoriteIssues:)) {
        return [self _setupFavoriteMenuItem:menuItem];
    }
    
    if (menuItem.action == @selector(didClickAddMilestoneInMenuItem:) || menuItem.action == @selector(didClickAddAssigneeInMenuItem:) || menuItem.action == @selector(didClickAddLabelInMenuItem:)) {
        NSArray<QIssue *> *currentIssueSelection = [self _currentIssues];
        
        BOOL helperWindowIsKey = ([self.labelsPickerWindowController.window isKeyWindow] || [self.repositoriesPickerWindowController.window isKeyWindow] || [self.assigneePickerWindowController.window isKeyWindow] || [self.milestonePickerWindowController.window isKeyWindow]);
        
        if (![self.window isKeyWindow] && !helperWindowIsKey) {
            return false;
        }
        __block BOOL isCollaborator = (currentIssueSelection.count == 0);
        [currentIssueSelection enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
            isCollaborator = [QAccount isCurrentUserCollaboratorOfRepository:issue.repository];
            if (!isCollaborator) {
                *stop = true;
                return;
            }
        }];
        
        return isCollaborator;
    }
    
    return true;
}

- (void)sr_closeIssues:(id)sender
{
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    
    dispatch_block_t block = ^{
        NSOperationQueue *operationQueue = [NSOperationQueue new];
        operationQueue.name = @"co.cashewapp.AppDelegate.closeIssues";
        operationQueue.maxConcurrentOperationCount = 2;
        [currentIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![issue.state isEqualToString:@"closed"]) {
                NSParameterAssert([NSThread isMainThread]);
                [operationQueue addOperationWithBlock:^{
                    NSParameterAssert(![NSThread isMainThread]);
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    QIssuesService *service = [QIssuesService serviceForAccount:issue.account];
                    [service closeIssueForRepository:issue.repository number:issue.number onCompletion:^(QIssue *newIssue, QServiceResponseContext *context, NSError *error) {
                        NSParameterAssert(![NSThread isMainThread]);
                        dispatch_semaphore_signal(semaphore);
                        if (newIssue && !error) {
                            [QIssueStore saveIssue:newIssue];
                            [self.issuesViewController reloadContextIssueSelection];
                        }
                    }];
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                }];
            }
        }];
        
        if ([operationQueue operationCount] > 0) {
            [operationQueue waitUntilAllOperationsAreFinished];
        }
    };
    
    if ([NSUserDefaults shouldShowIssueCloseWarning]) {
        
        NSString *message = currentIssues.count == 1 ? @"Are you sure you want to close this issue?" : [NSString stringWithFormat:@"Are you sure you want to close these %ld issues?", currentIssues.count];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:message];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            block();
        }
    } else {
        block();
    }
}

- (void)sr_viewExtensionLogs:(id)sender
{
    NSURL *url = [sender representedObject];
    NSParameterAssert(url);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        NSString *name = [NSString stringWithFormat:@"%@-CodeExtensions.log", appName];
        NSString *urlString = [[[DDLogFileManagerDefault new] logsDirectory] stringByAppendingPathComponent:name];
        NSURL *url = [NSURL fileURLWithPath:urlString];
        [[NSWorkspace sharedWorkspace] openURL:url];
        //        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ url ]];
        
        
        //        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleIdentifier");
        //        //let timestamp = timestampFormatter.stringFromDate(NSDate())
        //        return "\(appName!)-CodeExtensions.log"
    });
}

- (void)sr_manageExtensions:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.preferencesWindowController) {
            [self.preferencesWindowController didClickIssueExtensionToolbarItem:self];
            [self.preferencesWindowController.window makeKeyAndOrderFront:self];
        } else {
            [self _showPreferencesWindowControllerWithTab:SRPreferencesTabIssueExtensions];
        }
        
    });
    
    // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [self.preferencesWindowController didClickIssueExtensionToolbarItem:self];
    // });
}

- (void)sr_reopenIssues:(id)sender
{
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    
    NSString *message = currentIssues.count == 1 ? @"Are you sure you want to open this issue?" : [NSString stringWithFormat:@"Are you sure you want to open these %ld issues?", currentIssues.count];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSOperationQueue *operationQueue = [NSOperationQueue new];
        operationQueue.name = @"co.cashewapp.AppDelegate.reopenIssues";
        operationQueue.maxConcurrentOperationCount = 2;
        [currentIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([issue.state isEqualToString:@"closed"]) {
                NSParameterAssert([NSThread isMainThread]);
                [operationQueue addOperationWithBlock:^{
                    NSParameterAssert(![NSThread isMainThread]);
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    QIssuesService *service = [QIssuesService serviceForAccount:issue.account];
                    [service reopenIssueForRepository:issue.repository number:issue.number onCompletion:^(QIssue *newIssue, QServiceResponseContext *context, NSError *error) {
                        NSParameterAssert(![NSThread isMainThread]);
                        dispatch_semaphore_signal(semaphore);
                        if (newIssue && !error) {
                            [QIssueStore saveIssue:newIssue];
                            [self.issuesViewController reloadContextIssueSelection];
                        }
                    }];
                    // });
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                }];
            }
        }];
        if ([operationQueue operationCount] > 0) {
            [operationQueue waitUntilAllOperationsAreFinished];
        }        // [operationQueue waitUntilAllOperationsAreFinished];
        // [self _setupCloseOpenMenuItem];
    }
}

- (BOOL)_setupFavoriteMenuItem:(NSMenuItem *)menuItem
{
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    NSInteger favoritedIssueCount = [QIssueFavoriteStore totalFavoritedOutOfIssues:currentIssues];
    NSInteger unfavoritedIssueCount = ABS(currentIssues.count - favoritedIssueCount);
    [SRMenuUtilities setupFavoriteIssueMenuItem:menuItem favoriteIssuesCount:favoritedIssueCount unfavoriteIssuesCount:unfavoritedIssueCount];
    return true;
}


- (BOOL)_setupCloseOpenMenuItem:(NSMenuItem *)menuItem
{
    __block NSUInteger openIssues = 0;
    __block NSUInteger closedIssues = 0;
    __block BOOL isCollaborator = true;
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    
    QAccount *currentAccount = [QContext sharedContext].currentAccount;
    QOwner *currentUser = [QOwnerStore ownerForAccountId:currentAccount.identifier identifier:currentAccount.userId];
    __block NSNumber *isAuthor = nil;
    
    [currentIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([issue.state isEqualToString:@"closed"]) {
            closedIssues++;
        } else {
            openIssues++;
        }
        
        if ([issue.user isEqual:currentUser] && isAuthor == nil) {
            isAuthor = @(true);
        } else {
            isAuthor = @(false);
        }
        
        if (![QAccount isCurrentUserCollaboratorOfRepository:issue.repository]) {
            *stop = true;
            isCollaborator = false;
            return;
        }
    }];
    [SRMenuUtilities setupCloseOrOpenIssueMenuItem:menuItem openIssuesCount:openIssues closedIssuesCount:closedIssues];
    return isCollaborator || isAuthor.boolValue;
}


- (void)sr_shareFromService:(id)sender {
    NSArray<QIssue *> *currentIssues = [self _currentIssues];
    if (currentIssues.count != 1) {
        return;
    }
    QIssue *issue = currentIssues[0];
    
    if (issue.htmlURL == nil) {
        return;
    }
    
    NSSharingService *shareService = (NSSharingService *)[sender representedObject];
    [SRAnalytics logCustomEventWithName:@"Share Issue" customAttributes:@{@"title": shareService.title ?: @""}];
    [shareService performWithItems:[SRMenuUtilities selectedIssueItemsForSharingService]];
}

#pragma mark - QStoreObserver

- (void)store:(Class)store didInsertRecord:(id)record;
{
    if (store == QIssueNotificationStore.class && [record isKindOfClass:QIssue.class]) {
        [self _updateNotificationDotOnStatusItem];
    }
}

- (void)store:(Class)store didUpdateRecord:(id)record;
{
    if (store == QIssueNotificationStore.class && [record isKindOfClass:QIssue.class]) {
        [self _updateNotificationDotOnStatusItem];
    }
}

- (void)store:(Class)store didRemoveRecord:(id)record;
{
    if (store == QAccountStore.class && [record isKindOfClass:QAccount.class]) {
        QAccount *removedAccount = (QAccount *)record;
        QAccount *currentAccount = [QContext sharedContext].currentAccount;
        
        if (![currentAccount isEqual:removedAccount]) {
            return;
        }
        
        QAccount *switchToAccount = [[QAccountStore accounts] firstObject];
        
        if (switchToAccount) {
            QIssueFilter *filter = [QIssueFilter new];
            filter.account = switchToAccount;
            [[QContext sharedContext] setCurrentFilter:filter sender:nil postNotification:true];
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _showAccountCreationController];
                if (self.preferencesWindowController) {
                    [self.preferencesWindowController close];
                    self.preferencesWindowController = nil;
                }
            });
        }
        
    } else if (store == QIssueNotificationStore.class && [record isKindOfClass:QIssue.class]) {
        [self _updateNotificationDotOnStatusItem];
    }
}

- (void)_updateNotificationDotOnStatusItem
{
    QAccount *currentAccount = [QContext sharedContext].currentAccount;
    NSInteger unreadCount = [QIssueNotificationStore totalUnreadIssueNotificationsForAccountId:currentAccount.identifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (unreadCount == 0) {
            [[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
        } else {
            [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%ld", unreadCount]];
        }
        
    });
}

#pragma mark - Routing


- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString *url = [[[event paramDescriptorForKeyword:keyDirectObject] stringValue] trimmedString];
    DDLogDebug(@"route URL %@", url);
    
    if ([self _routeToIssueWithURLString:url]) {
        return;
        
    } else if ([self _routeToAssigneeWithURLString:url]) {
        return;
        
    }
}

- (BOOL)_routeToAssigneeWithURLString:(NSString *)url
{
    NSError *error = NULL;
    NSString *pattern = @"^cashew:\\/\\/assignee\\=(.*)$";
    NSRange range = NSMakeRange(0, url.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:url options:0 range:range];
    __block BOOL handled = false;
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSRange assigneeRange = [match rangeAtIndex:1];
        
        NSString *assignee = [[url substringWithRange:assigneeRange] trimmedString];
        if ([assignee hasPrefix:@"@"]) {
            assignee = [assignee substringFromIndex:1];
        }
        if (assignee.length > 0) {
            // FIXME: hicham - temporary solution
            QAccount *account = [QContext sharedContext].currentAccount;
            QOwner *user = [[QOwnerStore ownersWithLogins:@[assignee] forAccountId:account.identifier] firstObject];
            if (user && user.htmlURL) {
                handled = true;
                [[NSWorkspace sharedWorkspace] openURL:user.htmlURL];
            }
        }
        *stop = true;
        
    }];
    return handled;
}

- (BOOL)_routeToIssueWithURLString:(NSString *)url
{
    __block BOOL handled = false;
    NSError *error = NULL;
    NSString *pattern = @"^cashew:\\/\\/repository\\=(.*)?&issueNumber\\=(.*)$";
    NSRange range = NSMakeRange(0, url.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:url options:0 range:range];
    
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSRange repositoryNameRange = [match rangeAtIndex:1];
        NSRange issueNumberRange = [match rangeAtIndex:2];
        
        NSString *issueNumber = [url substringWithRange:issueNumberRange];
        NSString *repositoryName = [url substringWithRange:repositoryNameRange];
        
        QIssueFilter *currentFilter = [QContext sharedContext].currentFilter;
        QIssueFilter *filter = [QIssueFilter filterWithSearchTokensArray:@[ [NSString stringWithFormat:@"repo:%@", repositoryName], [NSString stringWithFormat:@"#%@", issueNumber] ]];
        filter.account = currentFilter.account;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSArray<QIssue *> *issues = [QIssueStore issuesWithFilter:filter pagination:nil];
            if (issues.count == 1) {
                handled = true;
                [[NSNotificationCenter defaultCenter] postNotificationName:kOpenNewIssueDetailsWindowNotification object:issues.firstObject];
            }
        });
        
        *stop = true;
        
    }];
    
    
    return handled;
}

#pragma mark - NSPopoverDelegate

//- (BOOL)popoverShouldDetach:(NSPopover *)popover {
//    return YES;
//}

- (void)popoverDidShow:(NSNotification *)notification
{
    if (notification.object == self.statusBarPopover) {
        [self.statusBarPopover becomeFirstResponder];
    }
}

@end
