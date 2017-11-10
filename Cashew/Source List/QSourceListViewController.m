//
//  QrepositoriesViewController.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QSourceListViewController.h"
#import "QView.h"
#import "QRepository.h"
#import "QSourceListDataSource.h"
#import "QSourceListChildViewCell.h"
#import "QSourceListParentViewCell.h"
#import "QContext.h"
#import "QAccountStore.h"
#import "QIssueSync.h"
#import "QIssueFilter.h"
#import "Cashew-Swift.h"
#import "QUserQueryStore.h"
#import "QRepositoryStore.h"
#import "QRepositoryStore.h"
#import "QIssueCommentDraftStore.h"
#import "QIssueNotificationStore.h"

@interface _SRFilterTextField: NSTextField
@end

@implementation _SRFilterTextField

- (BOOL)allowsVibrancy
{
    return false;
}

@end

@interface _SRFilterProgressIndicator: NSProgressIndicator
@end

@implementation _SRFilterProgressIndicator

- (BOOL)allowsVibrancy
{
    return false;
}

@end

@interface _FilterFieldCell : NSTextFieldCell

@end

@implementation _FilterFieldCell


- (NSRect)drawingRectForBounds:(NSRect)rect {
    
    NSRect rectInset = NSMakeRect(rect.origin.x + 5.0f, rect.origin.y + 2, rect.size.width - 20.0f, rect.size.height);
    return [super drawingRectForBounds:rectInset];
    
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(nullable id)anObject start:(NSInteger)selStart length:(NSInteger)selLength;
{
    aRect = [self drawingRectForBounds:aRect];
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    aRect = [self drawingRectForBounds:aRect];
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}
@end

@interface _QSourceListView : NSVisualEffectView
@property (nonatomic) BOOL shouldAllowVibrancy;
@end

@implementation _QSourceListView

- (BOOL)mouseDownCanMoveWindow
{
    return false;
}

- (BOOL)allowsVibrancy
{
    return self.shouldAllowVibrancy;
}

@end

@interface QSourceListViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, QBasicHeaderSourceListViewCellDelegate, QSourceListChildViewCellDelegate, QSourceListDataSourceDelegate, QStoreObserver, NSTextFieldDelegate> {
}
@property (weak) IBOutlet NSButton *syncButton;
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *minusButton;
@property (nonatomic) NSMutableSet<QRepository *> *partialSyncRepoSet;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet SRBaseOutlineView *sourceListView;
@property (weak) IBOutlet SRBaseScrollView *scrollView;
@property (weak) IBOutlet SRBaseClipView *clipView;
@property (nonatomic) QSourceListDataSource *dataSource;
@property (nonatomic) SRCoalescer *reloadCoalescer;
@property (nonatomic) QSourceListChildViewCell *notificationCell;
@property (nonatomic) QSourceListChildViewCell *draftsCell;
@property (nonatomic) SRCoalescer *notificationCellCountCoalescer;
@property (nonatomic) SRCoalescer *draftsCellCountCoalescer;;
@property (weak) IBOutlet _SRFilterTextField *filterField;
@property (weak) IBOutlet BaseView *headerContainerView;
@property (weak) IBOutlet BaseView *footerContainerView;
@property (weak) IBOutlet SRBaseScroller *verticalScroller;
@property (weak) IBOutlet SRBaseScroller *horizontalScroller;

@end

@implementation QSourceListViewController {
    QSourceListNode *_selectedNode;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [QIssueCommentDraftStore removeObserver:self];
    [QIssueNotificationStore removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.notificationCellCountCoalescer = [[SRCoalescer alloc] initWithInterval:0.1 name:@"co.cashewapp.QSourceListViewController.notificationCellCountCoalescer" executionQueue:dispatch_get_main_queue()];
    self.draftsCellCountCoalescer = [[SRCoalescer alloc] initWithInterval:0.1 name:@"co.cashewapp.QSourceListViewController.draftsCellCountCoalescer" executionQueue:dispatch_get_main_queue()];
    
    [QIssueCommentDraftStore addObserver:self];
    [QIssueNotificationStore addObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didChangeContext:) name:kQContextChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_willStartSync:) name:kWillStartSynchingRepositoryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndSync:) name:kDidFinishSynchingRepositoryNotification object:nil];
    
    self.view.layer.masksToBounds = true;
    
    [self _setupDataSource];
    [self _setupSourceList];
    [self _setupFilterField];
    
    self.reloadCoalescer = [[SRCoalescer alloc] initWithInterval:0.1 name:@"co.cashewapp.Coalescer.accessQueue.reloadCoalescer" executionQueue:dispatch_get_main_queue()];
    self.partialSyncRepoSet = [NSMutableSet new];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    __weak QSourceListViewController *weakSelf = self;
    
    //[(_QSourceListView *)self.view setDisableThemeObserver:true];
    [self.footerContainerView setDisableThemeObserver:true];
    [self.headerContainerView setDisableThemeObserver:true];
    [self.sourceListView setDisableThemeObserver:true];
    self.verticalScroller.shouldAllowVibrancy = false;
    self.horizontalScroller.shouldAllowVibrancy = false;
    self.clipView.disableThemeObserver = true;
    self.scrollView.disableThemeObserver = true;
    self.view.wantsLayer = true;
    
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        QSourceListViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        NSColor *bgColor = [NSColor clearColor]; //[SRCashewColor sidebarBackgroundColor];
        if (mode == SRThemeModeLight) {
            strongSelf.minusButton.image = [[NSImage imageNamed:NSImageNameRemoveTemplate] imageWithTintColor:[SRLightModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.addButton.image = [[NSImage imageNamed:NSImageNameAddTemplate] imageWithTintColor:[SRLightModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.syncButton.image = [[NSImage imageNamed:@"sync"] imageWithTintColor:[SRLightModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.progressIndicator.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            strongSelf.filterField.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            [(_QSourceListView *)strongSelf.view setShouldAllowVibrancy:YES];
            strongSelf.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            strongSelf.verticalScroller.shouldAllowVibrancy = true;
            strongSelf.horizontalScroller.shouldAllowVibrancy = true;
        } else if (mode == SRThemeModeDark) {
            strongSelf.minusButton.image = [[NSImage imageNamed:NSImageNameRemoveTemplate] imageWithTintColor:[SRDarkModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.addButton.image = [[NSImage imageNamed:NSImageNameAddTemplate] imageWithTintColor:[SRDarkModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.syncButton.image = [[NSImage imageNamed:@"sync"] imageWithTintColor:[SRDarkModeColor.sharedInstance foregroundSecondaryColor]];
            strongSelf.progressIndicator.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
            strongSelf.filterField.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
            bgColor = [SRCashewColor sidebarBackgroundColor];
            [(_QSourceListView *)strongSelf.view setShouldAllowVibrancy:NO];
            strongSelf.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            strongSelf.verticalScroller.shouldAllowVibrancy = false;
            strongSelf.horizontalScroller.shouldAllowVibrancy = false;
          //  strongSelf.verticalScroller.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
          //  strongSelf.horizontalScroller.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        }

       // strongSelf.verticalScroller.layer.backgroundColor = bgColor.CGColor;
       // strongSelf.horizontalScroller.layer.backgroundColor = bgColor.CGColor;
//        strongSelf.filterField.backgroundColor = [NSColor yellowColor]; //;
        strongSelf.filterField.layer.borderColor = [SRCashewColor separatorColor].CGColor;
        strongSelf.filterField.backgroundColor = [SRCashewColor backgroundColor];
        
        
       //[(_QSourceListView *)strongSelf.view setBackgroundColor:bgColor];
        strongSelf.headerContainerView.backgroundColor = bgColor;
        strongSelf.footerContainerView.backgroundColor = bgColor;
        strongSelf.sourceListView.backgroundColor = bgColor;
        strongSelf.view.layer.backgroundColor = bgColor.CGColor;
        
        strongSelf.clipView.backgroundColor = [NSColor blackColor];
        
        strongSelf.headerContainerView.appearance = strongSelf.view.appearance;
        strongSelf.footerContainerView.appearance = strongSelf.view.appearance;
        strongSelf.sourceListView.backgroundColor = bgColor;
    }];
}

- (void)_setupDataSource
{
    if (!self.dataSource) {
        self.dataSource = [QSourceListDataSource dataSource];
        self.dataSource.delegate = self;
    }
}

- (void)_didChangeContext:(NSNotification *)notification
{
    QAccount *newAccount = [QContext sharedContext].currentFilter.account;
    if (!self.dataSource.account || ![newAccount isEqualToAccount:self.dataSource.account]) {
        [self _fetchDataOnCompletion:^{
            //  [self _selectFirstItem];
        }];
    }
}

- (void)_willStartSync:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.object) {
            if (![notification.userInfo[@"isFullSync"] boolValue]) {
                [self.partialSyncRepoSet addObject:notification.object];
            }
        }
        
        if ( self.partialSyncRepoSet.count > 0 ) {
            if (self.progressIndicator.hidden == YES) {
                self.progressIndicator.hidden = NO;
                [self.progressIndicator startAnimation:nil];
                self.syncButton.hidden = YES;
            }
        }
//        NSMutableArray<NSString *> *strings = [NSMutableArray new];
//        [self.partialSyncRepoSet enumerateObjectsUsingBlock:^(QRepository * _Nonnull obj, BOOL * _Nonnull stop) {
//            [strings addObject:obj.fullName];
//        }];
//        DDLogDebug(@"+ repository notification.object = %@ all = %@", [notification.object fullName], [strings componentsJoinedByString:@","] );
    });
}

- (void)_didEndSync:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.object) {
            if (![notification.userInfo[@"isFullSync"] boolValue]) {
                [self.partialSyncRepoSet removeObject:notification.object];
            }
        }
        
        if ( self.partialSyncRepoSet.count == 0 ) {
            if (self.progressIndicator.hidden == NO) {
                self.progressIndicator.hidden = YES;
                [self.progressIndicator stopAnimation:nil];
                self.syncButton.hidden = NO;
            }
        }
//        NSMutableArray<NSString *> *strings = [NSMutableArray new];
//        [self.partialSyncRepoSet enumerateObjectsUsingBlock:^(QRepository * _Nonnull obj, BOOL * _Nonnull stop) {
//            [strings addObject:obj.fullName];
//        }];
//        DDLogDebug(@"- repository notification.object = %@ all = %@", [notification.object fullName], [strings componentsJoinedByString:@","] );
    });
}

- (void)_selectFirstItem
{
    QSourceListNode *parentNode = [self.dataSource childNodeAtIndex:0 forItem:nil];
    QSourceListNode *firstNode = [self.dataSource childNodeAtIndex:0 forItem:parentNode];
    [self _selectItem:firstNode];
}

- (void)showNotification
{
    QSourceListNode *notificationNode = [self.dataSource notificationNode];
    if (notificationNode) {
        [self _selectItem:notificationNode];
    }
}

- (void)showFavorites
{
    QSourceListNode *notificationNode = [self.dataSource favoritesNode];
    if (notificationNode) {
        [self _selectItem:notificationNode];
    }
}

- (void)_fetchDataOnCompletion:(dispatch_block_t)onCompletion
{
    //dispatch_async(dispatch_get_main_queue(), ^{
    _selectedNode = nil;
    QAccount *newAccount = [QContext sharedContext].currentFilter.account;
    [self.dataSource fetchItemsForAccount:newAccount onCompletion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.sourceListView reloadData];
            
            NSInteger numberOfParents = [self.dataSource numberOfSections];
            for (int i = 0; i < numberOfParents; i++) {
                QSourceListNode *parentNode = [self.dataSource childNodeAtIndex:i forItem:nil];
                NSParameterAssert(parentNode);
                NSInteger row = [_sourceListView rowForItem:parentNode];
                NSParameterAssert(row >= 0);
                QSourceListParentViewCell *cell = (QSourceListParentViewCell *)[_sourceListView viewAtColumn:0 row:row makeIfNecessary:YES];
                [_sourceListView expandItem:cell.node expandChildren:NO];
            }
            
            if (onCompletion) {
                onCompletion();
            }
        });
    }];
    
    // });
}


#pragma mark - General Setup

- (void)_setupFilterField
{
    self.filterField.wantsLayer = true;
    self.filterField.bordered = false;
    self.filterField.layer.borderWidth = 1;
    self.filterField.drawsBackground = true;
    self.filterField.delegate = self;
    self.filterField.layer.cornerRadius = 3.0;
    //[self.filterField setCell:[NSSearchFieldCell new]];
    
    _FilterFieldCell *newCell = [[_FilterFieldCell alloc] init];
    [newCell setBordered:NO]; // so background color shows up
    [newCell setBezeled:NO];
    [newCell setEditable:YES];
    [newCell setFocusRingType:NSFocusRingTypeNone];
    [newCell setTitle:@""];
    [newCell setPlaceholderString:@"Filter"];
    [self.filterField setCell:newCell];
}

- (void)_setupSourceList
{
    [_scrollView setAutohidesScrollers:YES];
    [_scrollView setScrollerStyle:NSScrollerStyleOverlay];
    
    [self.sourceListView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [self.sourceListView setDataSource:self];
    [self.sourceListView setDelegate:self];
    [self.sourceListView setWantsLayer:YES];
    [self.sourceListView setIndentationPerLevel:7];
    [self.sourceListView setIntercellSpacing:NSMakeSize(0, 0)];
    [self.sourceListView setAllowsMultipleSelection:NO];
    [self.sourceListView setupThemeObserver];
}


#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item;
{
    if (item == nil) {
        return [self.dataSource numberOfSections];
    }
    
    return [[(QSourceListNode *)item children] count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item;
{
    return [self.dataSource childNodeAtIndex:index forItem:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
{
    return [(QSourceListNode *)item children].count > 0;
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return [(QSourceListNode *)item children].count > 0;
}

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
    
    
    QSourceListNode *node = (QSourceListNode *)item;
    if (node.children > 0 && node.nodeType != QSourceListNodeType_Repository) {
        
        NSString *identifier =  @"ParentLabel";
        
        QSourceListParentViewCell *cell = [outlineView makeViewWithIdentifier:identifier owner:self];
        if (cell == nil) {
            NSNib *nib = [[NSNib alloc] initWithNibNamed:@"QSourceListParentViewCell" bundle:nil];
            NSArray *topLevelObjects;
            [nib instantiateWithOwner:self topLevelObjects:&topLevelObjects];
            
            for (id topLevelObject in topLevelObjects) {
                if ([topLevelObject isKindOfClass:[QSourceListParentViewCell class]]) {
                    cell = topLevelObject;
                    break;
                }
            }
            cell.identifier = identifier;
            cell.delegate = self;
        }
        [cell setNode:node];
        [cell setStringValue:node.title];
        [cell setHideBottomLine:YES];
        [cell setHideMenuButton:NO];
        //[cell setExpanded:[self.sourceListView isItemExpanded:node]];
        return cell;
        
    } else {
        
        if (node.nodeType == QSourceListNodeType_Notifications) {
            if (!self.notificationCell) {
                NSString *identifier =  @"NotificationCell";
                self.notificationCell = [[QSourceListChildViewCell alloc] init];
                [self.notificationCell setSourceListChildDelegate:self];
                self.notificationCell.identifier = identifier;
            }
            [self.notificationCell setNode:node];
            [self.notificationCell setSelected: node == _selectedNode];
            [self _updateNotificationsCellCount];
            return self.notificationCell;
        } else if (node.nodeType == QSourceListNodeType_Drafts) {
            if (!self.draftsCell) {
                NSString *identifier =  @"DraftsCell";
                self.draftsCell = [[QSourceListChildViewCell alloc] init];
                [self.draftsCell setSourceListChildDelegate:self];
                self.draftsCell.identifier = identifier;
            }
            [self.draftsCell setNode:node];
            [self.draftsCell setSelected: node == _selectedNode];
            [self _updateDraftsCellCount];
            return self.draftsCell;
        } else {
            
            NSString *identifier =  @"ChildLabel";
            QSourceListChildViewCell *childCell = [outlineView makeViewWithIdentifier:identifier owner:self];
            
            if (childCell == nil) {
                childCell = [[QSourceListChildViewCell alloc] init];
                [childCell setSourceListChildDelegate:self];
                childCell.identifier = identifier;
            }
            
            [childCell setNode:node];
            [childCell setSelected: node == _selectedNode];
            //[childCell setExpanded:[self.sourceListView isItemExpanded:node]];
            //   [childCell setLevel:QSourceListNodeType_Milestone == node.nodeType ? 2 : 1];
            
            //DDLogDebug(@"node => %@ isExpanded: %@", node.title, @([self.sourceListView isExpandable:node]));
            return childCell;
        }
    }
    
    return nil;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item;
{
    return 26.0;
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
    if (notification.object == self.sourceListView) {
        [notification.userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (![obj isKindOfClass:QSourceListNode.class]) {
                return;
            }
            QSourceListNode *node = (QSourceListNode *)obj;
            NSInteger row = [self.sourceListView rowForItem:node];
            if (row == NSNotFound) {
                return;
            }
            
            NSView *view = [self.sourceListView viewAtColumn:0 row:row makeIfNecessary:YES];
            if ([view isKindOfClass:QSourceListChildViewCell.class]) {
                QSourceListChildViewCell *cell = (QSourceListChildViewCell *)view;
                cell.expanded = true;
            } else if ([view isKindOfClass:QSourceListParentViewCell.class]) {
                QSourceListParentViewCell *cell = (QSourceListParentViewCell *)view;
                cell.expanded = true;
            }
        }];
    }
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
    if (notification.object == self.sourceListView) {
        [notification.userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (![obj isKindOfClass:QSourceListNode.class]) {
                return;
            }
            QSourceListNode *node = (QSourceListNode *)obj;
            NSInteger row = [self.sourceListView rowForItem:node];
            if (row == NSNotFound) {
                return;
            }
            
            NSView *view = [self.sourceListView viewAtColumn:0 row:row makeIfNecessary:YES];
            if ([view isKindOfClass:QSourceListChildViewCell.class]) {
                QSourceListChildViewCell *cell = (QSourceListChildViewCell *)view;
                cell.expanded = false;
            } else if ([view isKindOfClass:QSourceListParentViewCell.class]) {
                QSourceListParentViewCell *cell = (QSourceListParentViewCell *)view;
                cell.expanded = false;
            }
        }];
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    BOOL shouldSelect = [self _selectItem:item];
    QSourceListNode *node = (QSourceListNode *)item;
    
    if (node.children.count > 0 && node.nodeType != QSourceListNodeType_Repository) {
        [SRAnalytics logCustomEventWithName:@"SourceListParentSelection" customAttributes:@{@"childrenCount": @(node.children.count), @"Name": node.title, @"didSelect": @(shouldSelect) }];
    } else {
        [SRAnalytics logCustomEventWithName:@"SourceListChildSelection" customAttributes:@{@"searchQuery": node.userQuery.query ?: @"", @"Name": node.userQuery.displayName ?: @"", @"didSelect": @(shouldSelect)}];
    }
    
    return shouldSelect;
}

- (BOOL)_selectItem:(id)item
{
    NSParameterAssert([NSThread mainThread]);
    QSourceListNode *node = (QSourceListNode *)item;
    if(node.children.count > 0 && node.nodeType != QSourceListNodeType_Repository) {
        return NO;
    }
    
    NSInteger row = [_sourceListView rowForItem:item];
    
    if (row ==  -1) {
        return NO;
    }
    
    if (_selectedNode) {
        NSInteger selectedRow = [_sourceListView rowForItem:_selectedNode];
        if (selectedRow > -1) {
            QSourceListChildViewCell *selectedNodeCell = (QSourceListChildViewCell *)[_sourceListView viewAtColumn:0 row:selectedRow makeIfNecessary:YES];
            [selectedNodeCell setSelected:NO];
        }
    }
    
    NSView *cell = [_sourceListView viewAtColumn:0 row:row makeIfNecessary:YES];
    QSourceListChildViewCell *view = (QSourceListChildViewCell *)cell;
    [view setSelected:YES];
    
    _selectedNode = node;
    
    if (node.issueFilter) {
        QIssueFilter *filter = [node.issueFilter copy];
        QIssueFilter *currentFilter = [QContext sharedContext].currentFilter;
        if (currentFilter) {
            filter.sortKey = currentFilter.sortKey;
            filter.ascending = currentFilter.ascending;
        }
        
        if (node.nodeType == QSourceListNodeType_Milestone && NSUserDefaults.shouldShowOnlyOpenInMilestoneSearch) {
            filter.states = [NSOrderedSet orderedSetWithObject:@(IssueStoreIssueState_Open)];
        } else if (node.nodeType == QSourceListNodeType_Repository && NSUserDefaults.shouldShowOnlyOpenInRepositorySearch) {
            filter.states = [NSOrderedSet orderedSetWithObject:@(IssueStoreIssueState_Open)];
        }
        // NSUserDefaults.shouldShowBothOpenAndClosedInRepositorySearch
        // NSUserDefaults.shouldShowBothOpenAndClosedInMilestoneSearch
        
        [[QContext sharedContext] setCurrentFilter:filter sender:self];
    }
    
    return YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = self.sourceListView.selectedRow;
    if (selectedRow >= 0) {
        id selectedNodeObj = [self.sourceListView itemAtRow:selectedRow];
        if ([selectedNodeObj isKindOfClass:QSourceListNode.class]) {
            QSourceListNode *selectedNode = (QSourceListNode *)selectedNodeObj;
            self.minusButton.enabled = selectedNode.nodeType == QSourceListNodeType_CustomFilter || selectedNode.nodeType == QSourceListNodeType_Repository;
        }
    } else {
        self.minusButton.enabled = false;
    }
    
}

#pragma mark - QBasicHeaderSourceListViewCellDelegate <NSObject>

- (void)headerSourceListViewCell:(QSourceListParentViewCell *)cell didExpand:(BOOL)expand;
{
    if (expand) {
        //cell.expanded = YES;
        [[_sourceListView animator] expandItem:cell.node];
    } else {
        //cell.expanded = NO;
        [[_sourceListView animator] collapseItem:cell.node];
    }
}

#pragma mark - Actions

- (IBAction)didClickMinusButton:(id)sender
{
    NSInteger selectedRow = self.sourceListView.selectedRow;
    if (selectedRow < 0) {
        return;
    }
    
    id selectedNodeObj = [self.sourceListView itemAtRow:selectedRow];
    if (![selectedNodeObj isKindOfClass:QSourceListNode.class]) {
        return;
    }
    
    QSourceListNode *selectedNode = (QSourceListNode *)selectedNodeObj;
    
    [NSAlert showWarningMessage:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", selectedNode.title] onConfirmation:^{
        [self _deleteNode:selectedNode];
    }];
}

- (void)_deleteNode:(QSourceListNode *)node
{
    // delete repository if repo
    if (node.nodeType == QSourceListNodeType_Repository) {
        QRepository *repo = (QRepository *)node.representedObject;
        NSParameterAssert(repo);
        [QRepositoryStore deleteRepository:repo];
    }
    
    else if (node.nodeType == QSourceListNodeType_CustomFilter) {
        QUserQuery *userQuery = (QUserQuery *)node.representedObject;
        NSParameterAssert(userQuery);
        [QUserQueryStore deleteUserQuery:userQuery];
    }
}

- (IBAction)didClickAddButton:(id)sender
{
    SRMenu *menu = [[SRMenu alloc] init];
    
    [menu addItemWithTitle:@"Account" action:@selector(_didClickAddAccount:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Repository" action:@selector(_didClickAddRepository:) keyEquivalent:@""];
    //[menu addItemWithTitle:@"Milestone" action:@selector(_didClickAddMilestone:) keyEquivalent:@""];
    //[menu addItemWithTitle:@"Label" action:@selector(_didClickAddLabel:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Save Current Search" action:@selector(_didClickSaveCurrentSearch:) keyEquivalent:@""];
    
    NSWindow *window = self.view.window;
    [SRMenu popUpContextMenu:menu withEvent:[NSEvent mouseEventWithType:NSLeftMouseUp
                                                               location:NSMakePoint(self.addButton.frame.origin.x, self.addButton.frame.origin.y+menu.size.height+ _addButton.frame.size.height)
                                                          modifierFlags:0
                                                              timestamp:0
                                                           windowNumber:[window windowNumber]
                                                                context:nil
                                                            eventNumber:0
                                                             clickCount:0
                                                               pressure:0]
                     forView:sender];
}


- (void)_didClickSaveCurrentSearch:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowSaveSearchDisplayNamePopoverNotification object:nil];
}

- (void)_didClickAddRepository:(id)sender
{
    [_delegate didClickAddRepositoryInSourceListViewController:self];
}

//- (void)_didClickAddMilestone:(id)sender
//{
//   // [_delegate didClickAddMilestoneInSourceListViewController:self];
//}

- (void)_didClickAddAccount:(id)sender
{
    [_delegate didClickAddAccountInSourceListViewController:self];
}


- (void)_didClickAddLabel:(id)sender
{
    [_delegate didClickAddLabelInSourceListViewController:self];
}

- (IBAction)didClickReloadButton:(id)sender {
    [[AppDelegate sharedCashewAppDelegate] syncForced:true];
}

#pragma mark - Keyboard Shortcuts

//- (void)keyUp:(NSEvent *)theEvent
//{
//    //DDLogDebug(@"right = %@", @(theEvent.keyCode));
//
//    NSInteger row = [self.sourceListView rowForItem:_selectedNode];
//    if (row == NSNotFound) {
//        [_delegate sourceListViewController:self keyUp:theEvent];
//        return;
//    }
//
//    NSView *view = [self.sourceListView viewAtColumn:0 row:row makeIfNecessary:YES];
//    if ([view isKindOfClass:QSourceListChildViewCell.class]) {
//        QSourceListChildViewCell *cell = (QSourceListChildViewCell *)view;
//        if ([_selectedNode.children count] == 0 && cell.expanded) {
//            [_delegate sourceListViewController:self keyUp:theEvent];
//        }
//    } else {
//        [_delegate sourceListViewController:self keyUp:theEvent];
//    }
//}

- (void)focus;
{
    [self.view.window makeFirstResponder:_sourceListView];
}

#pragma mark - QSourceListChildViewCellDelegate
- (void)didSelectSourceListChildViewCell:(QSourceListChildViewCell *)cell
{
    [self _selectItem:cell.node];
}

- (void)didConfirmDeleteSourceListChildViewCell:(QSourceListChildViewCell *)cell;
{
    [self _deleteNode:cell.node];
}

- (void)didConfirmCloseMilestoneInSourceListChildViewCell:(QSourceListChildViewCell *)cell
{
    QMilestone *milestone = (QMilestone *)cell.node.representedObject;
    if (!milestone || ![milestone isKindOfClass:QMilestone.class]) {
        return;
    }
    
    QIssuesService *service = [QIssuesService serviceForAccount:cell.node.issueFilter.account];
    [service closeMilestone:milestone onCompletion:^(QMilestone *updated, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
        if (!error && updated) {
            [QMilestoneStore saveMilestone:updated];
        }
    }];
}

- (void)didClickRenameInSourceListChildViewCell:(QSourceListChildViewCell *)cell;
{
    
}

- (void)childSourceListViewCell:(QSourceListChildViewCell *)cell didExpand:(BOOL)expand
{
    if (expand) {
        //cell.expanded = YES;
        [[_sourceListView animator] expandItem:cell.node];
    } else {
        //cell.expanded = NO;
        [[_sourceListView animator] collapseItem:cell.node];
    }
}

#pragma mark - QSourceListDataSourceDelegate

- (void)reloadTableUsingSourceListDataSource:(QSourceListDataSource *)dataSource;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sourceListView reloadData];
        
        NSInteger numberOfParents = [self.dataSource numberOfSections];
        for (int i = 0; i < numberOfParents; i++) {
            QSourceListNode *parentNode = [self.dataSource childNodeAtIndex:i forItem:nil];
            NSParameterAssert(parentNode);
            NSInteger row = [self.sourceListView rowForItem:parentNode];
            if(row >= 0) {
                QSourceListParentViewCell *cell = (QSourceListParentViewCell *)[self.sourceListView viewAtColumn:0 row:row makeIfNecessary:YES];
                [self.sourceListView expandItem:cell.node expandChildren:NO];
            }
        }
    });
}

- (void)sourceListDataSource:(QSourceListDataSource *)dataSource didInsertNode:(QSourceListNode *)node atIndex:(NSUInteger)index;
{
    NSParameterAssert([node isKindOfClass:QSourceListNode.class]);
    if (index == NSNotFound) {
        return;
    }
    
    dispatch_block_t block = ^{
        [self.sourceListView beginUpdates];
        [self.sourceListView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:node.parentNode withAnimation:NSTableViewAnimationEffectNone];
        [self.sourceListView endUpdates];
        
        if (node.parentNode == nil) {
            [self.sourceListView expandItem:node];
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)sourceListDataSource:(QSourceListDataSource *)dataSource didRemoveNode:(QSourceListNode *)node atIndex:(NSUInteger)index;
{
    NSParameterAssert([node isKindOfClass:QSourceListNode.class]);
    if (index == NSNotFound) {
        return;
    }
    
    dispatch_block_t block = ^{
        [self.sourceListView beginUpdates];
        [self.sourceListView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:node.parentNode withAnimation:NSTableViewAnimationEffectNone];
        [self.sourceListView endUpdates];
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)sourceListDataSource:(QSourceListDataSource *)dataSource didUpdateNode:(QSourceListNode *)node;
{
    NSParameterAssert([node isKindOfClass:QSourceListNode.class]);
    if (!node) {
        return;
    }
    
    dispatch_block_t block = ^{
        [self.sourceListView beginUpdates];
        [self.sourceListView reloadItem:node.parentNode reloadChildren:YES];
        [self.sourceListView endUpdates];
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

#pragma mark - QStoreObserver <NSObject>

- (void)store:(Class)store didInsertRecord:(id)record;
{
    if ([record isKindOfClass:QIssue.class]) {
        QIssue *issue = (QIssue *)record;
        if (issue.notification) {
            [self _updateNotificationsCellCount];
        }
    } else if ([record isKindOfClass:SRIssueCommentDraft.class]) {
        [self _updateDraftsCellCount];
    }
}

- (void)store:(Class)store didUpdateRecord:(id)record;
{
    if ([record isKindOfClass:QIssue.class]) {
        QIssue *issue = (QIssue *)record;
        if (issue.notification) {
            [self _updateNotificationsCellCount];
        }
    }
}

- (void)store:(Class)store didRemoveRecord:(id)record;
{
    if ([record isKindOfClass:QIssue.class]) {
        QIssue *issue = (QIssue *)record;
        if (issue.notification) {
            [self _updateNotificationsCellCount];
        }
    } else if ([record isKindOfClass:SRIssueCommentDraft.class]) {
        [self _updateDraftsCellCount];
    }
}


- (void)_updateNotificationsCellCount
{
    [self.notificationCellCountCoalescer executeBlock:^{
        NSNumber *accountId = [QContext sharedContext].currentAccount.identifier;
        NSInteger count = [QIssueNotificationStore totalUnreadIssueNotificationsForAccountId:accountId];
        [self.notificationCell setCountValue:count];
    }];
}

- (void)_updateDraftsCellCount
{
    [self.draftsCellCountCoalescer executeBlock:^{
        NSNumber *accountId = [QContext sharedContext].currentAccount.identifier;
        NSInteger count = [QIssueCommentDraftStore totalIssueCommentDraftsForAccountId:accountId];
        [self.draftsCell setCountValue:count];
    }];
}

#pragma mark - NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
    if (self.filterField == obj.object) {
        [self.dataSource filterNodesUsingText:self.filterField.stringValue onCompletion:^(NSError *error) {
            [self.sourceListView reloadData];
            
            NSInteger numberOfParents = [self.dataSource numberOfSections];
            for (int i = 0; i < numberOfParents; i++) {
                QSourceListNode *parentNode = [self.dataSource childNodeAtIndex:i forItem:nil];
                NSParameterAssert(parentNode);
                NSInteger row = [_sourceListView rowForItem:parentNode];
                NSParameterAssert(row >= 0);
                QSourceListParentViewCell *cell = (QSourceListParentViewCell *)[_sourceListView viewAtColumn:0 row:row makeIfNecessary:YES];
                [_sourceListView expandItem:cell.node expandChildren:NO];
            }
            
        }];
    }
}


@end
