//
//  QIssuesViewController.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssuesViewController.h"
#import "QView.h"
#import "QIssuesService.h"
#import "QIssue.h"
#import "Cashew-Swift.h"
#import "QContext.h"
#import "QIssueDetailsViewController.h"
#import "QBaseWindowController.h"
#import "Cashew-Swift.h"
#import "SRMenuUtilities.h"
#import "SRNotificationService.h"
@import os.log;
//Here's how I did it in Xcode 4.6...
//
//In IB, select the table view and go to the Attributes Inspector. Choose 'Uniform' for 'Column Sizing'. Then, select the table column and choose 'Autoresizes with Table' for 'Resizing'.
//
//These options correspond to:
//
//[tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
//[tableColumn setResizingMask:NSTableColumnAutoresizingMask];


static NSString *kQUpdatedDateKey = @"Date modified";
static NSString *kQCreatedDateKey = @"Date created";
static NSString *kQClosedDateKey = @"Date closed";
static NSString *kQAssigneeKey = @"Assignee";
static NSString *kQIssueNumberKey = @"Issue number";
static NSString *kQIssueStateKey = @"Issue state";
static NSString *kQTitleKey = @"Title";




@interface _QIssuesScrollView : NSScrollView

@end

@implementation _QIssuesScrollView

+ (BOOL)isCompatibleWithResponsiveScrolling
{
    // background scrolling
    return YES;
}

@end


@interface QIssuesViewController () <NSTableViewDataSource, NSTableViewDelegate, QIssuesViewDataSourceDelegate, BaseModalWindowControllerDelegate, QStoreObserver, NSMenuDelegate>

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet BaseView *createIssueContainerView;
@property (weak) IBOutlet BaseView *createIssueCircleImageView;
@property (weak) IBOutlet NSImageView *createImageView;
@property (weak) IBOutlet SRBaseTableView *tableView;
@property (weak) IBOutlet SRBaseScrollView *scrollView;
@property (weak) IBOutlet NSTextField *createIssueLabel;
@property (weak) IBOutlet SRBasePopupButton *sortByButton;
@property (weak) IBOutlet NSTextField *numberOfIssuesLabel;
@property (weak) IBOutlet NSTextField *sortByLabel;
@property (nonatomic) NSMutableSet<BaseModalWindowController *> *issueDetailControllers;
@property (weak) IBOutlet BaseView *headerContainerView;
@property (nonatomic) NSMutableSet<QRepository *> *fullSyncRepoSet;
@property (nonatomic) SRCoalescer *nextPageCoalescer;
@property (weak) IBOutlet NSTextField *issueNumberAndSortSeparatorLabel;
@property (nonatomic) NSArray *sortItems;
@property (nonatomic) SRLayoutPreference layoutMode;
//@property (nonatomic) NSView *tableHeaderView;
@end

@implementation QIssuesViewController {
    
    QIssuesViewDataSource *_dataSource;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [SRThemeObserverController.sharedInstance removeThemeObserver:self];
    [QIssueStore remove:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:[NSUserDefaults layoutModeKeyPath]];
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sortItems = @[kQUpdatedDateKey, kQClosedDateKey, kQCreatedDateKey, kQAssigneeKey, kQIssueNumberKey, kQIssueStateKey, kQTitleKey];
        _dataSource = [QIssuesViewDataSource new];
        _dataSource.dataSourceDelegate = self;
        
        self.nextPageCoalescer = [[SRCoalescer alloc] initWithInterval:0.05
                                                                  name:@"co.cashewapp.QIssuesViewController.nextPageCoalescer"
                                                        executionQueue:dispatch_queue_create("co.hellocode.cashew.QIssuesViewController.scrollSerialQueue", DISPATCH_QUEUE_SERIAL)];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_willStartSync:) name:kWillStartSynchingRepositoryNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndSync:) name:kDidFinishSynchingRepositoryNotification object:nil];
        [QIssueStore addObserver:self];
    }
    return self;
}

- (void)setLayoutMode:(SRLayoutPreference)layoutMode
{
    _layoutMode = layoutMode;
    NSParameterAssert([NSThread isMainThread]);
    if (layoutMode == SRLayoutPreferenceClassic) {
        [self _transitionToClassicMode];
    } else {
        [self _transitionToStandardMode];
    }
}

- (void)_transitionToStandardMode
{
    BOOL didChange = false;
   // [[[self.tableView tableColumns] firstObject] setResizingMask:NSTableColumnAutoresizingMask];
    
    [self.tableView setAutosaveName:nil];
    [self.tableView setAutosaveTableColumns:NO];
    
    self.tableView.gridStyleMask = NSTableViewGridNone;
    [self.tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    [self.tableView setUsesAlternatingRowBackgroundColors:NO];
    [self.tableView setHeaderView:nil];
    self.tableView.intercellSpacing = NSMakeSize(0, 0);
    
    if (self.tableView.numberOfColumns > 1) {
        [self _removeAllTableColumns];
        
        NSString *columnId = @"ViewBasedIssue";
        NSTableColumn *column = [[NSTableColumn alloc] init];
        column.headerCell = [SRIssuesTableHeaderCell new];
        column.title = columnId;
        column.identifier = columnId;
        
        [column setResizingMask:NSTableColumnAutoresizingMask];
        [self.tableView addTableColumn:column];
        
        didChange = true;
        
    }
    
    if (didChange) {
        [self.tableView reloadData];
    }
}

- (void)_transitionToClassicMode
{
    BOOL didChange = false;
 
    self.tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
    
    [self.tableView setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
    //[[[self.tableView tableColumns] firstObject] setResizingMask:NSTableColumnUserResizingMask];
    [self.tableView setUsesAlternatingRowBackgroundColors:NO];
    [self.tableView setHeaderView:[SRIssuesTableHeaderView new]];
//    self.tableView.headerView.wantsLayer = true;
//    self.tableView.headerView.layer.backgroundColor = [NSColor greenColor].CGColor;
    self.tableView.intercellSpacing = NSMakeSize(8, 4);
    //@"•"
    NSArray<NSString *> *columns = @[@"•", @"#", @"Title", @"Assignee", @"Author", @"Repository", @"Milestone", @"State", @"Modified", @"Created"];
    
    if (self.tableView.numberOfColumns != columns.count) {
        didChange = true;
        [self _removeAllTableColumns];
        
        [columns enumerateObjectsUsingBlock:^(NSString * _Nonnull columnId, NSUInteger idx, BOOL * _Nonnull stop) {
            NSTableColumn *column = [[NSTableColumn alloc] init];
            column.headerCell = [SRIssuesTableHeaderCell new];
            if ([columnId isEqualToString:@"#"] || [columnId isEqualToString:@"•"]) {
                column.headerCell.alignment = NSCenterTextAlignment;
            }
//            column.headerCell.drawsBackground = true;
//            column.headerCell.backgroundColor = [NSColor yellowColor];
            
            column.title = columnId;
            column.identifier = columnId;

            
            [column setResizingMask:NSTableColumnUserResizingMask];
            [self.tableView addTableColumn:column];
        }];
    }
    [self.tableView setAutosaveName:@"IssueListColumnInformation"];
    [self.tableView setAutosaveTableColumns:YES];
    
    SRMenu *menu = [SRMenu new];
    menu.delegate = self;
    for (NSTableColumn *col in [self.tableView tableColumns]) {
        if ([[col identifier] isEqualToString:@"Title"]) {
            continue;
        }
        NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[col.headerCell stringValue] action:@selector(toggleColumn:)  keyEquivalent:@""];
        mi.target = self;
        mi.representedObject = col;
        [menu addItem:mi];
    }
    self.tableView.headerView.menu = menu;
    
    if (didChange) {
        [self.tableView reloadData];
    }
    
}

- (void)toggleColumn:(id)sender
{
    NSTableColumn *col = [sender representedObject];
    [col setHidden:![col isHidden]];
}

- (void)menuWillOpen:(SRMenu *)menu
{
    if (self.tableView.headerView.menu == menu) {
        for (NSMenuItem *mi in menu.itemArray) {
            NSTableColumn *col = [mi representedObject];
            [mi setState:col.isHidden ? NSOffState : NSOnState];
        }
    }
}

- (void)_removeAllTableColumns
{
    NSArray<NSTableColumn *> *columns = [[self.tableView tableColumns] copy];
    [columns enumerateObjectsUsingBlock:^(NSTableColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
        //if (![column.identifier isEqualToString:@"Title"]) {
            [self.tableView removeTableColumn:column];
        //}
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.layoutMode = [NSUserDefaults layoutModePreference];
    
    self.fullSyncRepoSet = [NSMutableSet new];
    self.headerContainerView.allowMouseToMoveWindow = false;
    self.sortByButton.hidden = YES;
    self.sortByLabel.hidden = YES;
    self.sortByButton.font = self.sortByLabel.font;
    self.sortByButton.disableThemeObserver = true;
    
    _numberOfIssuesLabel.stringValue = @"";
    
    [_scrollView setAutohidesScrollers:YES];
    [_scrollView setScrollerStyle:NSScrollerStyleOverlay];
    
    [self _setupTableView];
    [self _setupCreateIssueButton];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:[NSUserDefaults layoutModeKeyPath] options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:self.scrollView.contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_openNewIssuesNotification:) name:kOpenNewIssueDetailsWindowNotification object:nil];
    
    
    __weak QIssuesViewController *weakSelf = self;
    [SRThemeObserverController.sharedInstance addThemeObserver:self block:^(SRThemeMode mode) {
        QIssuesViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        NSMutableParagraphStyle *pstyle = [NSMutableParagraphStyle new];
        pstyle.alignment = NSTextAlignmentCenter;
        
        if (mode == SRThemeModeLight) {
            strongSelf.issueNumberAndSortSeparatorLabel.textColor = [SRLightModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.createIssueCircleImageView.borderColor = [SRLightModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.createImageView.image = [[NSImage imageNamed:NSImageNameAddTemplate] imageWithTintColor:[SRLightModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.createIssueLabel.textColor = [SRLightModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.numberOfIssuesLabel.textColor = [SRLightModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.sortByLabel.textColor = [SRLightModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.sortByButton.textColor = [SRDarkModeColor.sharedInstance foregroundTertiaryColor];
            strongSelf.progressIndicator.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            
        } else if (mode == SRThemeModeDark) {
            strongSelf.issueNumberAndSortSeparatorLabel.textColor = [SRDarkModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.createIssueCircleImageView.borderColor = [SRDarkModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.createImageView.image = [[NSImage imageNamed:NSImageNameAddTemplate] imageWithTintColor:[SRDarkModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.createIssueLabel.textColor = [SRDarkModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.numberOfIssuesLabel.textColor = [SRDarkModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.sortByLabel.textColor = [SRDarkModeColor.sharedInstance foregroundSecondaryColor];
            strongSelf.sortByButton.textColor = [SRDarkModeColor.sharedInstance foregroundTertiaryColor];
            strongSelf.progressIndicator.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        }
        
        //[strongSelf.sortByButton updateChevronImage];
        strongSelf.sortByButton.chevronImageView.image = [strongSelf.sortByButton chevronImage:strongSelf.sortByButton.textColor];
        strongSelf.sortByButton.backgroundColor = [NSColor clearColor];
        
        self.tableView.gridColor = [SRCashewColor separatorColor];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:[NSUserDefaults layoutModeKeyPath]]) {
        self.layoutMode = [NSUserDefaults layoutModePreference];
        [self.tableView reloadData];
    }
}

- (void)scrollViewDidScroll:(NSNotification *)notification
{
    if (CGRectGetMaxY([_scrollView documentVisibleRect]) >= CGRectGetMaxY([_tableView frame]) *.99) {
        [self.nextPageCoalescer executeBlock:^{
            if (CGRectGetMaxY([_scrollView documentVisibleRect]) >= CGRectGetMaxY([_tableView frame]) *.99) {
                [_dataSource nextPage];
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "Total issues => %@", @([_dataSource numberOfIssues]));
            }
        }];
    }
}


- (void)focus;
{
    [self.view.window makeFirstResponder:_tableView];
    [self _selectFirstIssue];
}

- (void)reloadContextIssueSelection
{
    NSMutableArray<QIssue *> *issues = [NSMutableArray new];
    NSUInteger totalRecords = [_dataSource numberOfIssues];
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < totalRecords) {
            [issues addObject:[_dataSource issueAtIndex:idx]];
        }
    }];
    [QContext sharedContext].currentIssues = issues;
}


- (void)keyUp:(NSEvent *)theEvent
{
    if (theEvent.keyCode == 123) {
        [_delegate issuesViewController:self keyUp:theEvent];
    }
}

- (void)setFilter:(QIssueFilter *)filter
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // dispatch_sync(_tableViewInsertionSerialQueue, ^{
        if (_filter != filter) {
            _filter = filter;
            
            NSString *filterSortKey = _filter.sortKey;
            NSString *selectedTitle = nil;
            
            if ([filterSortKey isEqualToString:kQIssueUpdatedDateSortKey]) {
                selectedTitle = kQUpdatedDateKey;
                
            } else if ([filterSortKey isEqualToString:kQIssueClosedDateSortKey]) {
                selectedTitle = kQClosedDateKey;
                
            } else if ([filterSortKey isEqualToString:kQIssueCreatedDateSortKey]) {
                selectedTitle = kQCreatedDateKey;
                
            } else if ([filterSortKey isEqualToString:kQIssueIssueNumberSortKey]) {
                selectedTitle = kQIssueNumberKey;
                
            } else if ([filterSortKey isEqualToString:kQIssueIssueStateSortKey]) {
                selectedTitle = kQIssueStateKey;
                
            } else if ([filterSortKey isEqualToString:kQIssueTitleSortKey]) {
                selectedTitle = kQTitleKey;
                
            } else if ([filterSortKey isEqualToString:kQIssueAssigneeSortKey]) {
                selectedTitle = kQAssigneeKey;
            } else {
                NSParameterAssert("invalid key");
            }
            
            [self _updateSortButtonWithTitle:selectedTitle];
            [[_scrollView documentView] scrollPoint:NSZeroPoint];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                [_dataSource fetchIssuesWithFilter:_filter];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSParameterAssert([NSThread mainThread]);
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    [self.tableView sizeLastColumnToFit];
                    [self.tableView beginUpdates];
                    [self.tableView reloadData];
                    [self.tableView endUpdates];
                    [CATransaction commit];
                    [[_scrollView documentView] scrollPoint:NSZeroPoint];
                    [self _updateCountLabel];
                    [self _selectFirstIssue];
                });
            });
        }
        //});
    });
}

- (void)_updateCountLabel {
//    DDLogDebug(@"QIssuesVC updateCountLabel");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self.filter.account == nil) {
            return;
        }
        NSInteger count = [QIssueStore countForIssuesWithFilter:self.filter];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.filter) {
                self.numberOfIssuesLabel.hidden = true;
                return;
            } else {
                self.numberOfIssuesLabel.hidden = false;
            }
            
            if (self.fullSyncRepoSet.count > 0 ) {
                if (self.progressIndicator.hidden == YES) {
                    self.progressIndicator.hidden = NO;
                    [self.progressIndicator startAnimation:nil];
                }
                
                if (self.fullSyncRepoSet.count > 0) {
                    self.numberOfIssuesLabel.stringValue = [NSString stringWithFormat:@"SYNCING %@ REPO%@", @(self.fullSyncRepoSet.count), self.fullSyncRepoSet.count > 1 ? @"S" : @""];
                    SRThemeMode themeMode = [NSUserDefaults themeMode];
                    if (themeMode == SRThemeModeLight) {
                        self.numberOfIssuesLabel.textColor = [SRLightModeColor.sharedInstance foregroundSecondaryColor];
                        
                    } else if (themeMode == SRThemeModeDark) {
                        self.numberOfIssuesLabel.textColor = [SRDarkModeColor.sharedInstance foregroundSecondaryColor];
                    }
                }
            } else {
                if (self.progressIndicator.hidden == NO) {
                    self.progressIndicator.hidden = YES;
                    [self.progressIndicator stopAnimation:nil];
                }
                
                
                if (count == 0) {
                    self.numberOfIssuesLabel.textColor = [NSColor colorFromHexadecimalValue:@"#E6560D"];
                    self.numberOfIssuesLabel.stringValue = @"NO ISSUES FOUND";
                } else {
                    NSNumberFormatter *formatter = [NSNumberFormatter new];
                    formatter.numberStyle = NSNumberFormatterDecimalStyle;
                    SRThemeMode themeMode = [NSUserDefaults themeMode];
                    if (themeMode == SRThemeModeLight) {
                        self.numberOfIssuesLabel.textColor = [SRLightModeColor.sharedInstance foregroundSecondaryColor];
                        
                    } else if (themeMode == SRThemeModeDark) {
                        self.numberOfIssuesLabel.textColor = [SRDarkModeColor.sharedInstance foregroundSecondaryColor];
                    }
                    self.numberOfIssuesLabel.stringValue = [NSString stringWithFormat:@"%@ ISSUE%@", [formatter stringFromNumber:@(count)], count == 1 ? @"" : @"S"];
                }
            }
        });
    });
}

- (void)_selectFirstIssue
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_dataSource numberOfIssues] > 0) {
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            [QContext sharedContext].currentIssues = @[[_dataSource issueAtIndex:0]];
        } else {
            [_delegate issuesViewController:self didSelectIssue:nil];
        }
        if (![self.view.window.firstResponder isKindOfClass:NSTextView.class]) {
            [self.view.window makeFirstResponder:_tableView];
        }
    });
    
}

#pragma mark - General Setup

- (void)_setupCreateIssueButton
{
    [@[self.createIssueContainerView, self.createIssueLabel, self.createIssueCircleImageView] enumerateObjectsUsingBlock:^(NSView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_didClickNewIssue:)];
        
        recognizer.numberOfClicksRequired = 1;
        [view addGestureRecognizer:recognizer];
    }];
}

- (void)_didClickNewIssue:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kQCreateIssueNotification object:nil];
}

- (void)_setupTableView
{
    [_tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
    [_tableView setIntercellSpacing:NSMakeSize(0, 0)];
    [_tableView setDoubleAction:@selector(_didDoubleClick:)];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    [self reloadContextIssueSelection];
    
    if (menuItem.submenu.itemArray.count > 0) {
        return YES;
    }
    
    //DDLogDebug(@"menuItem-> %@", NSStringFromSelector(menuItem.action));
    if (menuItem.action == @selector(onSortSelectionChange:) || menuItem.action == @selector(_sortAscending) || menuItem.action == @selector(_sortDescending) || menuItem.action == @selector(_didClickNewIssue:)) {
        return true;
    }
    __block NSUInteger openIssues = 0;
    __block NSUInteger closedIssues = 0;
    __block BOOL isCollaborator = true;
    
    NSArray<QIssue *> *currentIssues = [QContext sharedContext].currentIssues;
    [currentIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([issue.state isEqualToString:@"closed"]) {
            closedIssues++;
        } else {
            openIssues++;
        }
        
        if (![QAccount isCurrentUserCollaboratorOfRepository:issue.repository]) {
            *stop = true;
            isCollaborator = false;
            return;
        }
    }];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    if (!isCollaborator && menuItem.action != @selector(_openNewWindowMenuItem:) && ( (menuItem.action == @selector(_addToMilestone:)) || (menuItem.action == @selector(_addLabels:)) || (menuItem.action == @selector(_assignIssues:)) || (menuItem.action == @selector(_assignIssues:)))) {
        return false;
    }
    
    NSUInteger issueCount = currentIssues.count;
    
    
    if (menuItem.action == @selector(sr_closeIssues:) || menuItem.action == @selector(sr_reopenIssues:)) {
        [SRMenuUtilities setupCloseOrOpenIssueMenuItem:menuItem openIssuesCount:openIssues closedIssuesCount:closedIssues];
    }
    
    else if (menuItem.action == @selector(_assignIssues:)) {
        if (issueCount > 1) {
            menuItem.title = @"Assign Issues to…";
        } else {
            menuItem.title = @"Assign Issue to…";
        }
    }
    
    else if (menuItem.action == @selector(_assignIssues:)) {
        if (issueCount > 1) {
            menuItem.title = @"Assign Issues to…";
        } else {
            menuItem.title = @"Assign Issue to…";
        }
    }
    
    else if (menuItem.action == @selector(_openNewWindowMenuItem:)) {
        if (issueCount != 1) {
            return NO;
        }
    }
    
#pragma clang diagnostic pop
    
    return YES;
}


- (void)_didDoubleClick:(id)sender
{
    if (self.tableView.selectedRow == -1) {
        return;
    }
    QIssue *issue = [_dataSource issueAtIndex:self.tableView.selectedRow];
    [self _openNewIssueDetailsWindowForIssue:issue];
}

- (void)_openNewIssuesNotification:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:QIssue.class]) {
        [self _openNewIssueDetailsWindowForIssue:notification.object];
    }
}

- (void)_openNewIssueDetailsWindowForIssue:(QIssue *)issue
{
    NSParameterAssert(issue);
    
    NSString *contentId = [NSString stringWithFormat:@"%@/%@", issue.repository.fullName, issue.number];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!self.issueDetailControllers) {
            self.issueDetailControllers = [NSMutableSet new];
        }
        
        __block BaseModalWindowController *windowController = nil;
        __block QIssueDetailsViewController *detailViewController = nil;
        
        
        [self.issueDetailControllers enumerateObjectsUsingBlock:^(BaseModalWindowController * _Nonnull aWindowController, BOOL * _Nonnull stop) {
            if ([aWindowController.viewController isKindOfClass:QIssueDetailsViewController.class]) {
                QIssueDetailsViewController *controller = (QIssueDetailsViewController *)aWindowController.viewController;
                if ([controller.issue isEqualToIssue:issue]) {
                    detailViewController = controller;
                    windowController = aWindowController;
                    *stop = YES;
                }
            }
        }];
        
        if (!detailViewController) {
            detailViewController = [QIssueDetailsViewController new];
            
            windowController = [[BaseModalWindowController alloc] initWithWindowNibName:@"BaseModalWindowController"];
            windowController.darkModeOverrideBackgroundColor = [[SRDarkModeColor sharedInstance] backgroundColor];
            windowController.windowTitle = [NSString stringWithFormat:@"%@ - #%@", issue.repository.fullName, issue.number];
            windowController.viewController = detailViewController;
            windowController.baseModalWindowControllerDelegate = self;
            windowController.window.frameAutosaveName = NSStringFromClass(QIssueDetailsViewController.class);
            windowController.showMiniaturizeButton = true;
            windowController.showZoomButton = true;
            
            NSWindow *mainAppWindow = NSApp.windows[0];
            NSSize windowSize = NSMakeSize(800, self.view.window.frame.size.height);
            CGFloat windowLeft = mainAppWindow.frame.origin.x + mainAppWindow.frame.size.width/2.0 - windowSize.width/2.0;
            CGFloat windowTop = mainAppWindow.frame.origin.y + mainAppWindow.frame.size.height/2.0 - windowSize.height/2.0;
            [windowController.window setFrame:NSMakeRect(windowLeft + self.issueDetailControllers.count * 20, windowTop - self.issueDetailControllers.count * 20, windowSize.width, windowSize.height) display:YES animate:NO];
            
            
            [self.issueDetailControllers addObject:windowController];
        }
        
        [windowController.window makeKeyAndOrderFront:self];
        windowController.window.minSize = NSMakeSize(400, 500);
        detailViewController.issue = issue;
        
        if ([NSApp activationPolicy] == NSApplicationActivationPolicyAccessory) {
            [self.view.window orderOut:self];
        }
    });
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSUInteger row = [self.tableView rowAtPoint:[self.tableView convertPoint:[theEvent locationInWindow] fromView:nil]];
    
    if (row == -1) {
        return;
    }
    if (![self.tableView.selectedRowIndexes containsIndex:row]) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    
    
    [self reloadContextIssueSelection];
    
    SRMenu *menu = [[SRMenu alloc] init];
    
    NSMenuItem *newWindowMenuItem = [[NSMenuItem alloc] initWithTitle:@"New Window" action:@selector(_openNewWindowMenuItem:) keyEquivalent:@""];
    [menu addItem:newWindowMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSMenuItem *favoriteIssuesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Favorite Issue(s)" action:@selector(sr_favoriteIssues:) keyEquivalent:@""];
    favoriteIssuesMenuItem.target = [AppDelegate sharedCashewAppDelegate];
    [menu addItem:favoriteIssuesMenuItem];
    
    NSMenuItem *closeIssuesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Close Issue(s)" action:@selector(sr_closeIssues:) keyEquivalent:@""];
    closeIssuesMenuItem.target = [AppDelegate sharedCashewAppDelegate];
    [menu addItem:closeIssuesMenuItem];
#pragma clang diagnostic pop
    
    NSMenuItem *assignIssuesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Assign Issue(s) to..." action:@selector(_assignIssues:) keyEquivalent:@""];
    [menu addItem:assignIssuesMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *addLabelsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Add Label..." action:@selector(_addLabels:) keyEquivalent:@""];
    [menu addItem:addLabelsMenuItem];
    
    NSMenuItem *addToMilestone = [[NSMenuItem alloc] initWithTitle:@"Add to Milestone..." action:@selector(_addToMilestone:) keyEquivalent:@""];
    [menu addItem:addToMilestone];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSMenuItem *extensionsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Extensions" action:nil keyEquivalent:@""];
    [SRMenuUtilities setupExtensionMenuItem:extensionsMenuItem];
    [menu addItem:extensionsMenuItem];
    
    NSMenuItem *issueShareMenuItem = [[NSMenuItem alloc] initWithTitle:@"Share" action:nil keyEquivalent:@""];
    [SRMenuUtilities setupShareMenuItem:issueShareMenuItem];
    [menu addItem:issueShareMenuItem];
#pragma clang diagnostic pop
    
    [SRMenu popUpContextMenu:menu withEvent:theEvent forView:self.tableView];
}

- (void)_openNewWindowMenuItem:(id)sender
{
    if (self.tableView.selectedRow == -1) {
        return;
    }
    
    QIssue *issue = [_dataSource issueAtIndex:self.tableView.selectedRow];
    [self _openNewIssueDetailsWindowForIssue:issue];
}


- (void)_assignIssues:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kQShowAssigneePickerNotification object:nil];
}

- (void)_applyLabelToIssues:(id)sender
{
    
}

- (void)_addLabels:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kQShowLabelPickerNotification object:nil];
}

- (void)_addToMilestone:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kQShowMilestonePickerNotification object:nil];
}

#pragma mark - Actions
- (IBAction)onSortSelectionChange:(NSMenuItem *)sender {
    
    NSString *selectedTitle = [sender title];
    NSMutableArray<NSString *> *items = _sortItems.mutableCopy;
    NSInteger index = [items indexOfObject:selectedTitle];
    if (index != NSNotFound) {
        [self _updateSortButtonWithTitle:selectedTitle];
        
        QIssueFilter *newFilter = [_filter copy];
        if (newFilter) {
            if ([selectedTitle.lowercaseString isEqualToString:kQUpdatedDateKey.lowercaseString]) {
                newFilter.sortKey = kQIssueUpdatedDateSortKey;
                
            } else if ([selectedTitle.lowercaseString isEqualToString:kQClosedDateKey.lowercaseString]) {
                newFilter.sortKey = kQIssueClosedDateSortKey;
                
            } else if ([selectedTitle.lowercaseString isEqualToString:kQCreatedDateKey.lowercaseString]) {
                newFilter.sortKey = kQIssueCreatedDateSortKey;
                
            } else if ([selectedTitle.lowercaseString isEqualToString:kQIssueNumberKey.lowercaseString]) {
                newFilter.sortKey = kQIssueIssueNumberSortKey;
                
            } else if ([selectedTitle.lowercaseString isEqualToString:kQIssueStateKey.lowercaseString]) {
                newFilter.sortKey = kQIssueIssueStateSortKey;
                
            } else if ([selectedTitle.lowercaseString isEqualToString:kQTitleKey.lowercaseString]) {
                newFilter.sortKey = kQIssueTitleSortKey;
                
            } else if ([selectedTitle.lowercaseString isEqualToString:kQAssigneeKey.lowercaseString]) {
                newFilter.sortKey = kQIssueAssigneeSortKey;
            } else {
                NSParameterAssert("invalid key");
            }
            
            [[QContext sharedContext] setCurrentFilter:newFilter];
        }
    }
}

- (void)_updateSortButtonWithTitle:(NSString *)selectedTitle
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sortByButton.hidden = NO;
        self.sortByLabel.hidden = NO;
        self.sortByButton.stringValue = [selectedTitle uppercaseString];
        NSMutableArray<NSString *> *items = _sortItems.mutableCopy;
        NSInteger index = [items indexOfObject:selectedTitle];
        if (index != NSNotFound) {
            NSString *oldSelection = items[0];
            items[0] = selectedTitle;
            items[index] = oldSelection;
            
            NSMutableArray<NSMenuItem *> *menu = [NSMutableArray new];
            
            for (NSString *title in self.sortItems) {
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(onSortSelectionChange:) keyEquivalent:@""];
                [menu addObject:menuItem];
            }
            
            [menu addObject:[NSMenuItem separatorItem]];
            NSMenuItem *ascending = [[NSMenuItem alloc] initWithTitle:@"Ascending" action:@selector(_sortAscending) keyEquivalent:@""];
            [ascending setState:_filter.ascending?NSOnState:NSOffState];
            [ascending setEnabled:YES];
            [ascending setTarget:self];
            [menu addObject:ascending];
            
            NSMenuItem *descending = [[NSMenuItem alloc] initWithTitle:@"Descending" action:@selector(_sortDescending) keyEquivalent:@""];
            [descending setState:_filter.ascending?NSOffState:NSOnState];
            [descending setEnabled:YES];
            [descending setTarget:self];
            
            [menu addObject:descending];
            
            self.sortByButton.menuItems = menu;
            [self.sortByButton invalidateIntrinsicContentSize];
        }
        
    });
}

- (void)_sortAscending
{
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "sort ascending");
    if (_filter.ascending == NO) {
        QIssueFilter *newFilter = [_filter copy];
        newFilter.ascending = YES;
        [[QContext sharedContext] setCurrentFilter:newFilter];
    }
}

- (void)_sortDescending
{
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "sort descending");
    if (_filter.ascending == YES) {
        QIssueFilter *newFilter = [_filter copy];
        newFilter.ascending = NO;
        [[QContext sharedContext] setCurrentFilter:newFilter];
    }
}


#pragma mark - NSTableViewDelegate

+ (NSDateFormatter *)_dateFormatter
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy HH:mm aa"];
        formatter = dateFormatter;
    });
    return formatter;
}


- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row NS_AVAILABLE_MAC(10_7);
{
    
    if (row > [_dataSource numberOfIssues] - 1) {
        return nil;
    }
    
    if (row == -1) {
        return nil;
    }
    
    if (self.layoutMode == SRLayoutPreferenceClassic) {
        QIssue *issue = [_dataSource issueAtIndex:row];
        
        if ([tableColumn.identifier isEqualToString:@"•"]) {
            SRDotIssueCellView *cellView = [self.tableView makeViewWithIdentifier:@"DotIssueCellView" owner:self];
            if (cellView == nil) {
                cellView = [[SRDotIssueCellView alloc] init];
                cellView.identifier = @"DotIssueCellView";
            }
            cellView.issue = issue;
            return cellView;
        }
    
        SRIssueCellView *cellView = [self.tableView makeViewWithIdentifier:@"IssueViewNSTableCellView" owner:self];
        
        if (cellView == nil) {
            cellView = [[SRIssueCellView alloc] init];
        
            cellView.identifier = @"IssueViewNSTableCellView";
        }
        
        NSTextField *textField = cellView.label;

        
        if ([tableColumn.identifier isEqualToString:@"Title"]) {
            textField.stringValue = issue.title;
            
        } else if ([tableColumn.identifier isEqualToString:@"Assignee"]) {
            textField.stringValue = issue.assignee.login ?: @"Unassigned";
            
        } else if ([tableColumn.identifier isEqualToString:@"Author"]) {
            textField.stringValue = issue.author.login;
            
        } else if ([tableColumn.identifier isEqualToString:@"Milestone"]) {
            textField.stringValue = issue.milestone.title ?: @"No Milestone";
            
        } else if ([tableColumn.identifier isEqualToString:@"State"]) {
            textField.stringValue = issue.state.capitalizedString;
            
        } else if ([tableColumn.identifier isEqualToString:@"Modified"]) {
            NSDate *updatedAt = issue.updatedAt ?: issue.createdAt;
            textField.stringValue =  [[QIssuesViewController _dateFormatter] stringFromDate:updatedAt];
            
        } else if ([tableColumn.identifier isEqualToString:@"Created"]) {
            textField.stringValue =  [[QIssuesViewController _dateFormatter] stringFromDate:issue.createdAt];
            
        } else if ([tableColumn.identifier isEqualToString:@"#"]) {
            textField.stringValue = [NSString stringWithFormat:@"%@", issue.number];
        
        } else if ([tableColumn.identifier isEqualToString:@"Repository"]) {
            textField.stringValue = issue.repository.name;
        }

        return cellView;
    } else {
        return nil;
    }
}

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    QIssue *issue = [_dataSource issueAtIndex:row];
//    NSTableCellView *cellView = [self.tableView makeViewWithIdentifier:@"IssueViewCell" owner:self];
//    
//    if ([tableColumn.identifier isEqualToString:@"Title"]) {
//        return issue.title;
//        
//    } else if ([tableColumn.identifier isEqualToString:@"Assignee"]) {
//        return issue.assignee.login ?: @"Unassigned";
//        
//    } else if ([tableColumn.identifier isEqualToString:@"Author"]) {
//        return issue.author.login;
//        
//    } else if ([tableColumn.identifier isEqualToString:@"Milestone"]) {
//        return issue.milestone.title ?: @"No Milestone";
//        
//    } else if ([tableColumn.identifier isEqualToString:@"State"]) {
//        return issue.state.capitalizedString;
//        
//    } else if ([tableColumn.identifier isEqualToString:@"Modified"]) {
//        NSDate *updatedAt = issue.updatedAt ?: issue.createdAt;
//        return [[QIssuesViewController _dateFormatter] stringFromDate:updatedAt];
//        
//    } else if ([tableColumn.identifier isEqualToString:@"Created"]) {
//        return [[QIssuesViewController _dateFormatter] stringFromDate:issue.createdAt];
//    }
//    
//    return nil;
//}

//- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//{
//    [(NSTableCellView *)cell layer].backgroundColor = NSColor.yellowColor.CGColor;
//}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    if (!NSThread.isMainThread) {
        return nil;
    }
    
    if (row > [_dataSource numberOfIssues] - 1) {
        return nil;
    }
    
    if (row == -1) {
        return nil;
    }
    
    
    if (self.layoutMode == SRLayoutPreferenceClassic) {
        return nil;
    } else {
        QIssue *issue = [_dataSource issueAtIndex:row];
        
        if (issue == nil) {
            return nil;
        }
        
        // [tableColumn setWidth:CGRectGetWidth(self.tableView.frame)];
        QIssueTableViewCell *view = [self.tableView makeViewWithIdentifier:@"QIssueTableViewCell" owner:self];
        if (view == nil) {
            view = [QIssueTableViewCell instantiateFromNib];
            view.identifier = @"QIssueTableViewCell";
        } else {
            // DDLogDebug(@"QIssueTableViewCell reused...");
        }
        NSParameterAssert(view);
        [view setIssue:issue];
        view.selected = [_tableView.selectedRowIndexes containsIndex:row];
        
        return view;
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row;
{
    if (self.layoutMode == SRLayoutPreferenceClassic) {
        return 20;
    } else {
        return [QIssueTableViewCell suggestedHeight];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
    NSUInteger row = _tableView.selectedRowIndexes.firstIndex;
    if (row == -1) {
        return;
    }
    // DDLogDebug(@"selected row = %@", @(row));
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_dataSource numberOfIssues] > 0 && row != NSNotFound) {
            QIssue *newSelectedIssue = [_dataSource issueAtIndex:row];
            [_delegate issuesViewController:self didSelectIssue:newSelectedIssue];
        }
        [self _updateSelectedState];
    });
    
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self _updateSelectedState];
}

- (void)_updateSelectedState
{
    NSScrollView *scrollView = [self.tableView enclosingScrollView];
    CGRect visibleRect = scrollView.contentView.visibleRect;
    NSRange range = [self.tableView rowsInRect:visibleRect];
    
    NSIndexSet *selectedRowIndexes = _tableView.selectedRowIndexes;
    for (NSUInteger idx = range.location; idx < NSMaxRange(range); idx++ ){
        QIssueTableViewCell *cell = [_tableView rowViewAtRow:idx makeIfNecessary:YES];  //viewAtColumn:0 row:idx makeIfNecessary:false];
        cell.selected = [selectedRowIndexes containsIndex:idx];
    }
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    NSMutableArray<QIssue *> *issues = [NSMutableArray new];
    [proposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [issues addObject:[_dataSource issueAtIndex:idx]];
    }];
    [QContext sharedContext].currentIssues = issues;
    return proposedSelectionIndexes;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return [_dataSource numberOfIssues];
}

//- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)column row:(int)row {
// return @"poo";
//}

#pragma mark - QIssuesViewDataSourceDelegate

- (void)dataSource:(QIssuesViewDataSource *)dataSource didInsertIndexSet:(NSIndexSet *)indexSet forFilter:(QIssueFilter *)issueFilter;
{
    dispatch_block_t block = ^{
        // dispatch_sync(_tableViewInsertionSerialQueue, ^{
        QIssueFilter *currentFilter = [QContext sharedContext].currentFilter;
        if ([currentFilter isEqualToIssueFilter:issueFilter]) {
            NSParameterAssert([NSThread mainThread]);
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            [self.tableView beginUpdates];
            // DDLogDebug(@"About to insert %@", indexSet);
            [self.tableView insertRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationEffectNone];
            [self.tableView endUpdates];
            [self _updateCountLabel];
            [CATransaction commit];
        }
        // });
    };
    
    dispatch_async(dispatch_get_main_queue(), block);
}

- (void)dataSource:(QIssuesViewDataSource *)dataSource didDeleteIndexSet:(NSIndexSet *)indexSet forFilter:(QIssueFilter *)issueFilter
{
    dispatch_block_t block = ^{
        //dispatch_sync(_tableViewInsertionSerialQueue, ^{
        QIssueFilter *currentFilter = [QContext sharedContext].currentFilter;
        if ([currentFilter isEqualToIssueFilter:issueFilter]) {
            NSParameterAssert([NSThread mainThread]);
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            [self.tableView beginUpdates];
            // DDLogDebug(@"About to insert %@", indexSet);
            [self.tableView removeRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationEffectNone];
            [self.tableView endUpdates];
            [self _updateCountLabel];
            [CATransaction commit];
        }
        //});
    };
    
    dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark - BaseModalWindowControllerDelegate
- (void)willCloseBaseModalWindowController:(BaseModalWindowController * _Nonnull)baseWindowController;
{
    if (!self.issueDetailControllers) {
        return;
    }
    
    [self.issueDetailControllers removeObject:baseWindowController];
}


#pragma mark - Notifications

- (void)_willStartSync:(NSNotification *)notification {
//    DDLogDebug(@"QIssuesVC willStartSync");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.object) {
            if ([notification.userInfo[@"isFullSync"] boolValue]) {
                [self.fullSyncRepoSet addObject:notification.object];
            }
        }
        [self _updateCountLabel];
    });
}

- (void)_didEndSync:(NSNotification *)notification {
//    DDLogDebug(@"QIssuesVC didEndSync");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.object) {
            if ([notification.userInfo[@"isFullSync"] boolValue]) {
                [self.fullSyncRepoSet removeObject:notification.object];
            }
        }
        [self _updateCountLabel];
    });
}

#pragma mark - QStoreObserver
- (void)store:(Class)store didInsertRecord:(id)record; { }
- (void)store:(Class)store didUpdateRecord:(id)record; {
    if (store == QIssueStore.class) {
        [self reloadContextIssueSelection];
//        NSInteger indx = [_dataSource indexOfIssue:record];
//        if (indx != NSNotFound && self.layoutMode == SRLayoutPreferenceClassic) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.tableView beginUpdates];
//                [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:indx] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.tableColumns.count-1)]];
//                [self.tableView endUpdates];
//            });
//        }
    }
    
    
}
- (void)store:(Class)store didRemoveRecord:(id)record; { }

@end
