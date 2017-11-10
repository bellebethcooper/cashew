//
//  QIssueDetailsViewController.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueDetailsViewController.h"
#import "NSDate+TimeAgo.h"
#import "QMilestoneStore.h"
#import "Cashew-Swift.h"
#import "QIssueCommentStore.h"
#import "QIssueCommentInfo.h"
#import "QIssueEventStore.h"
#import "QIssueSync.h"
#import "QIssueMarkdownWebView.h"
#import "QOwnerStore.h"
#import "QIssueCommentDraftStore.h"
#import "QIssueFavoriteStore.h"
#import "SRMenuUtilities.h"

@interface QIssueDetailsViewController () <NSTableViewDataSource, NSTableViewDelegate, QStoreObserver, NSTextFieldDelegate, NSPopoverDelegate>

@property (weak) IBOutlet BaseView *toolbarContainerView;

@property (nonatomic) IBOutlet NSButton *assigneeButton;
@property (nonatomic) IBOutlet NSButton *milestoneButton;
@property (weak) IBOutlet NSButton *extensionButton;


@property (weak) IBOutlet SRBaseScrollView *activityScrollView;
@property (weak) IBOutlet NSTableView *activityTableView;

@property (weak) IBOutlet BaseView *titleContainerView;
@property (nonatomic) SRBaseTextField *titleTextField;

@property (nonatomic) NSCache *editableFieldsCache;

@property (weak) IBOutlet CommentEditorView *commentEditorView;
@property (weak) IBOutlet BaseView *commentEditorContainerView;
@property (weak) IBOutlet BaseView *titleSeparatorView;

//@property (nonatomic) SRCoalescer *setIssueCoalescer;

@property (nonatomic) SRIssueStateBadgeView *issueStateBadgeView;

@property (nonatomic) NSPopover *assigneePopover;
@property (nonatomic) NSPopover *milestonePopover;
@property (nonatomic) QIssueDetailsDataSource *dataSource;

@property (nonatomic) SRIssueDetailLabelsTableViewCell *labelsTableViewCell;
@property (strong) IBOutlet BaseView *noIssueSelectedView;
@property (weak) IBOutlet NSButton *favoriteButton;
@property (weak) IBOutlet IssueTableViewCellTextField *headerSubtitleTextField;
@property (weak) IBOutlet NSButton *menuButton;

@end

@implementation QIssueDetailsViewController



- (void)dealloc {
    self.dataSource.onRowInsert = nil;
    self.dataSource.onRowUpdate = nil;
    self.dataSource.onRowDeletion = nil;
    self.dataSource = nil;
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [QIssueStore removeObserver:self];
    [QIssueFavoriteStore removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [QIssueStore addObserver:self];
    [QIssueFavoriteStore addObserver:self];
    
    //self.setIssueCoalescer = [[SRCoalescer alloc] initWithInterval:0.05 name: @"co.cashewapp.Coalescer.accessQueue.QIssueDetailsViewController.setIssue" executionQueue:dispatch_get_main_queue()];
    
    self.editableFieldsCache = [NSCache new];
    
    self.dataSource = [QIssueDetailsDataSource new];
    __weak QIssueDetailsViewController *weakSelf = self;
    
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^( SRThemeMode mode) {
        QIssueDetailsViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.titleTextField.textColor = [SRCashewColor foregroundColor];
        strongSelf.commentEditorView.backgroundColor = [SRCashewColor currentLineBackgroundColor];
        [strongSelf.editableFieldsCache removeAllObjects];
        [strongSelf.activityTableView reloadData];
        
        if (mode == SRThemeModeDark) {
            strongSelf.titleTextField.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        } else {
            strongSelf.titleTextField.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        }
        [strongSelf _updateFavoriteButtonState];
    }];
    
    
    [self.dataSource setOnRowUpdate:^(NSInteger row) {
        QIssueDetailsViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        id item = [strongSelf.dataSource itemAtIndex:row];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.editableFieldsCache removeObjectForKey:item];
            [strongSelf.activityTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        });
    }];
    
    [self.dataSource setOnRowDeletion:^(NSInteger row) {
        QIssueDetailsViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.activityTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationEffectNone];
        });
    }];
    
    [self.dataSource setOnRowInsert:^(NSInteger row) {
        QIssueDetailsViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.activityTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationEffectNone];
            
            //            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //                NSRect rowRect = [strongSelf.activityTableView rectOfRow:row];
            //                [strongSelf.activityTableView scrollRectToVisible:rowRect];
            //            });
        });
    }];
    
    self.titleSeparatorView.hidden = true;
    [_activityScrollView setAutohidesScrollers:YES];
    [_activityScrollView setScrollerStyle:NSScrollerStyleOverlay];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidEndLiveResizeNotification:) name:kQWindowDidEndLiveNotificationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:self.activityScrollView.contentView];
  
    [self _setupToolbarView];
    [self _setupTitleLabels];
    [self _setupActivityTableView];
    [self _setupCommentEditorView];
    [self _setupLabelsContainerView];
    
    [self.view addSubview:self.headerSubtitleTextField]; // make sure  header subtitle is above label container view
}

- (void)_setupLabelsContainerView
{
    self.labelsTableViewCell = [SRIssueDetailLabelsTableViewCell instanceFromNib];
    [self.view addSubview:self.labelsTableViewCell];
    self.labelsTableViewCell.translatesAutoresizingMaskIntoConstraints = false;
    [self.labelsTableViewCell.leftAnchor constraintEqualToAnchor:self.toolbarContainerView.leftAnchor].active = true;
    [self.labelsTableViewCell.rightAnchor constraintEqualToAnchor:self.toolbarContainerView.rightAnchor].active = true;
    [self.labelsTableViewCell.topAnchor constraintEqualToAnchor:self.headerSubtitleTextField.bottomAnchor constant:-3].active = true;
    [self.labelsTableViewCell.heightAnchor constraintEqualToConstant:[SRIssueDetailLabelsTableViewCell suggestedHeight]].active = true;
    
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    if (self.commentEditorView.activateTextViewConstraints == false) {
        self.commentEditorView.activateTextViewConstraints = true;
    }
}

- (void)setIssue:(QIssue *)issue
{
    BOOL sameIssue = [_issue isEqualToIssue:issue];
    
    __weak QIssueDetailsViewController *weakSelf = self;
    //  [self.setIssueCoalescer executeBlock:^{
    [self _updateIssue:issue];
    if (issue && !sameIssue) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            QIssueDetailsViewController *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [[QIssueSync sharedIssueSync] refreshIssueEventsAndCommentsForIssueNumber:issue.number repository:issue.repository skipIssueCheck:true];
        });
    }
    //  }];
}

- (void)_updateFavoriteButtonState
{
    if (!self.issue) {
        self.favoriteButton.toolTip = nil;
        return;
    }
    BOOL isFavorited = [QIssueFavoriteStore isFavoritedIssue:self.issue];
    if (isFavorited) {
        NSImage *image = [NSImage imageNamed:@"filled_star"];
        self.favoriteButton.toolTip = @"Click to unfavorite issue";
        self.favoriteButton.image = [image imageWithTintColor:[SRCashewColor yellowColor]];
    } else {
        NSImage *image = [NSImage imageNamed:@"unfilled_star"];
        self.favoriteButton.toolTip = @"Click to favorite issue";
        self.favoriteButton.image = [image imageWithTintColor:[SRCashewColor foregroundSecondaryColor]];
    }
    
    if (self.favoriteButton.hidden) {
        self.favoriteButton.hidden = false;
    }
}

- (void)_updateIssue:(QIssue *)issue
{
    NSParameterAssert([NSThread mainThread]);
    
    
    if (!issue) {
        _issue = nil;
        self.commentEditorContainerView.hidden = true;
        if (!self.noIssueSelectedView.superview) {
            [self.view addSubview:self.noIssueSelectedView];
            [self.noIssueSelectedView pinAnchorsToSuperview];
        }
        
        return;
    }
    
    self.commentEditorContainerView.hidden = false;
    
    BOOL sameIssue = [_issue isEqualToIssue:issue];
    BOOL sameIssueWithUpdatedContent = sameIssue && ![_issue.updatedAt isEqualToDate:issue.updatedAt];
    
    if (!sameIssue) {
        NSString *contentId = [NSString stringWithFormat:@"%@/%@", issue.repository.fullName, issue.number];
        [SRAnalytics logContentViewWithName:NSStringFromClass(QIssueDetailsViewController.class) contentType:@"" contentId:contentId customAttributes:nil];
        [self.commentEditorView clearText];
    }
    
    if (!sameIssue || sameIssueWithUpdatedContent) {
        _issue = issue;
        [self.editableFieldsCache removeAllObjects];
        
        QAccount *currentAccount = [QContext sharedContext].currentAccount;
        QOwner *currentUser = [QOwnerStore ownerForAccountId:currentAccount.identifier identifier:currentAccount.userId];
        BOOL isCollaborator = [QAccount isCurrentUserCollaboratorOfRepository:issue.repository];
        BOOL isAuthor = [currentUser isEqual:issue.user];
        
        [self.titleTextField setEditable:isCollaborator || isAuthor];
        [self.titleTextField setStringValue:_issue.title];
        self.assigneeButton.title = issue.assignee.login ?: @"Unassigned";
        self.milestoneButton.title = issue.milestone.title ?: @"No milestone";
        self.headerSubtitleTextField.stringValue = [NSString stringWithFormat:@"#%@ • %@ • Opened %@ by %@", issue.number, issue.repository.fullName, [issue.createdAt timeAgo], issue.user.login ?: @""];
        //Opened \(anIssue.createdAt.timeAgo()) by \(anIssue.user.login)
        if ([_issue.state isEqualToString:@"open"]) {
            self.issueStateBadgeView.open = true;
            self.issueStateBadgeView.toolTip = @"Click to close issue";
        } else {
            self.issueStateBadgeView.open = false;
            self.issueStateBadgeView.toolTip = @"Click to open issue";
        }
        self.issueStateBadgeView.needsLayout = true;
        [self.issueStateBadgeView layoutSubtreeIfNeeded];
        
        self.labelsTableViewCell.viewModel = [[SRIssueDetailLabelsTableViewModel alloc] initWithIssue:issue];
        
        [self _updateFavoriteButtonState];
        

        self.issueStateBadgeView.hidden = false;
        
        //self.commentEditorView.enabled = isCollaborator;
        self.milestoneButton.enabled = isCollaborator;
        self.assigneeButton.enabled = isCollaborator;
        self.issueStateBadgeView.enabled = isCollaborator || isAuthor;
        self.labelsTableViewCell.enabled = isCollaborator;
        self.extensionButton.enabled = isCollaborator;
        
        SRIssueDetailLabelsTableViewCell *cell = self.labelsTableViewCell;
        if (cell) {
            [cell setViewModel:[[SRIssueDetailLabelsTableViewModel alloc] initWithIssue:issue]];
        }
        
        if (!sameIssueWithUpdatedContent) {
            self.dataSource.issue = issue;
            // dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityScrollView.contentView scrollToPoint:NSZeroPoint];
            if ([issue isEqualToIssue:self.issue]) {
                [self.activityTableView reloadData];
                SRIssueCommentDraft *draft = [self.dataSource issueCommentDraftForCurrentIssue];
                if (draft && !self.commentEditorView.isFirstResponder) {
                    //[self.view.window makeFirstResponder:self.commentEditorView.textView];
                    self.commentEditorView.text = draft.body;
                }
                //[self _preloadTableViewCells];
                
            }
        }
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        QIssue *issueNotification = [QIssueNotificationStore issueWithNotificationForAccountId:issue.account.identifier repositoryId:issue.repository.identifier issueNumber:issue.number];
        if (issueNotification && issueNotification.notification && issueNotification.notification.read == false) {
            SRNotificationService *service = [SRNotificationService serviceForAccount:issueNotification.account];
            [service markNotificationAsReadForIssue:issueNotification onCompletion:^(id  _Nullable obj, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
                [QIssueNotificationStore saveIssueNotificationWithAccountId:issueNotification.account.identifier
                                                               repositoryId:issueNotification.repository.identifier
                                                                issueNumber:issueNotification.number
                                                                   threadId:issueNotification.notification.threadId
                                                                     reason:issueNotification.notification.reason
                                                                       read:true
                                                                  updatedAt:issueNotification.notification.updatedAt];
            }];
        }
    });
}

- (void)_preloadTableViewCells
{
    __weak QIssueDetailsViewController *weakSelf = self;
    NSUInteger counter = 0;
    for (NSUInteger i = 0; i < self.dataSource.numberOfItems; i++) {
        NSObject *obj = [self.dataSource itemAtIndex:i];
        if (![obj conformsToProtocol:@protocol(QIssueCommentInfo)]) {
            continue;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * counter * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[weakSelf activityTableView] rowViewAtRow:i makeIfNecessary:YES]; // DO NOT FORCE STRONG REFERENCE HERE
        });
        counter++;
    }
}

#pragma mark - General Setup

- (void)_setupToolbarView
{
    self.milestoneButton.image.template = true;
    self.assigneeButton.image.template = true;
    self.extensionButton.image.size = NSMakeSize(12, 12);
    self.extensionButton.image.template = true;
    self.menuButton.image.template = true;

    self.milestoneButton.toolTip = @"Click to change milestone";
    self.assigneeButton.toolTip = @"Click to change assignee";
    

    self.issueStateBadgeView = [[SRIssueStateBadgeView alloc] initWithOpen:false];
    [self.toolbarContainerView addSubview:self.issueStateBadgeView];
    self.issueStateBadgeView.translatesAutoresizingMaskIntoConstraints = false;
    
    [self.issueStateBadgeView.leftAnchor constraintEqualToAnchor:self.toolbarContainerView.leftAnchor constant:4.0].active = true;
    [self.issueStateBadgeView.centerYAnchor constraintEqualToAnchor:self.toolbarContainerView.centerYAnchor].active = true;
    [self.issueStateBadgeView setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.issueStateBadgeView setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    self.issueStateBadgeView.hidden = true;
    
    self.assigneeButton.translatesAutoresizingMaskIntoConstraints = false;
    self.milestoneButton.translatesAutoresizingMaskIntoConstraints = false;
    
    [self.assigneeButton.leftAnchor constraintEqualToAnchor:self.issueStateBadgeView.rightAnchor constant:4.0].active = true;
    [self.milestoneButton.leftAnchor constraintEqualToAnchor:self.assigneeButton.rightAnchor constant:4.0].active = true;
    
    [self.extensionButton.leftAnchor constraintEqualToAnchor:self.milestoneButton.rightAnchor constant:4.0].active = true;
    [self.extensionButton.rightAnchor constraintLessThanOrEqualToAnchor:self.menuButton.leftAnchor constant:-12.0].active = true;
    
    __weak QIssueDetailsViewController *weakSelf = self;
    self.issueStateBadgeView.onClick = ^{
        [weakSelf _didClickBadge];
    };
}

- (void)_didClickBadge
{
    QAccount *currentAccount = [QContext sharedContext].currentAccount;
    QOwner *currentUser = [QOwnerStore ownerForAccountId:currentAccount.identifier identifier:currentAccount.userId];
    BOOL isCollaborator = [QAccount isCurrentUserCollaboratorOfRepository:self.issue.repository];
    BOOL isAuthor = [currentUser isEqual:self.issue.user];
    if (!isCollaborator && !isAuthor) {
        return;
    }
    
    BOOL isOpen = [_issue.state isEqualToString:@"open"] ? true : false;
    QAccount *account = [QContext sharedContext].currentAccount;
    __weak QIssueDetailsViewController *weakSelf = self;
    
    if (isOpen) {
        
        dispatch_block_t block = ^{
            QIssueDetailsViewController *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            QIssuesService *service = [QIssuesService serviceForAccount:account];
            [service closeIssueForRepository:strongSelf.issue.repository number:strongSelf.issue.number onCompletion:^(QIssue *newIssue, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
                if (newIssue && !error) {
                    [strongSelf _syncIssueEventsForCurrentIssueUsingSinceDate:strongSelf.issue.updatedAt];
                    [QIssueStore saveIssue:newIssue];
                }
            }];
        };
        
        if (![NSUserDefaults shouldShowIssueCloseWarning]) {
            block();
        } else {
            [NSAlert showWarningMessage:@"Are you sure you want to close this issue?" onConfirmation:block];
        }
        
    } else {
        [NSAlert showWarningMessage:@"Are you sure you want to reopen this issue?" onConfirmation:^{
            QIssueDetailsViewController *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            QIssuesService *service = [QIssuesService serviceForAccount:account];
            [service reopenIssueForRepository:strongSelf.issue.repository number:strongSelf.issue.number onCompletion:^(QIssue *newIssue, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
                if (newIssue && !error) {
                    [strongSelf _syncIssueEventsForCurrentIssueUsingSinceDate:strongSelf.issue.updatedAt];
                    [QIssueStore saveIssue:newIssue];
                }
            }];
        }];
    }
    
}

- (IBAction)_didClickToolbarButton:(id)sender
{
    BOOL isCollaborator = [QAccount isCurrentUserCollaboratorOfRepository:self.issue.repository];
    if (!isCollaborator) {
        return;
    }
    
    
    if (sender == self.assigneeButton) {
        [SRAnalytics logCustomEventWithName:@"Clicked Assignee on Issue Details" customAttributes:nil];
        SRAssigneeSearchablePickerViewController *assigneeSearchablePicker = [[SRAssigneeSearchablePickerViewController alloc] init];
        assigneeSearchablePicker.sourceIssue = self.issue;
        
        NSSize size = NSMakeSize(320.0f, 420.0f);
        
        assigneeSearchablePicker.view.frame = NSMakeRect(0, 0, size.width, size.height);
        
        NSPopover *popover = [[NSPopover alloc] init];
        
        self.assigneePopover = popover;
        
        [popover setDelegate:self];
        [popover setContentSize:size];
        [popover setContentViewController:assigneeSearchablePicker];
        [popover setAnimates:YES];
        
        if ([NSUserDefaults themeMode] == SRThemeModeDark) {
            NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            popover.appearance = appearance;
        } else {
            NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            popover.appearance = appearance;
        }
        [self.view.window makeFirstResponder:self.view];
        [popover setBehavior:NSPopoverBehaviorTransient];
        [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSRectEdgeMaxY];
        assigneeSearchablePicker.popover = popover;
        
    } else if (sender == self.milestoneButton) {
        [SRAnalytics logCustomEventWithName:@"Clicked Milestone on Issue Details" customAttributes:nil];
        SRMilestoneSearchablePickerViewController *milestonePickerController = [[SRMilestoneSearchablePickerViewController alloc] init];
        milestonePickerController.sourceIssue = self.issue;
        NSSize size = NSMakeSize(320.0f, 420.0f);
        
        milestonePickerController.view.frame = NSMakeRect(0, 0, size.width, size.height);
        
        NSPopover *popover = [[NSPopover alloc] init];
        
        self.milestonePopover = popover;
        
        [popover setDelegate:self];
        [popover setContentSize:size];
        [popover setContentViewController:milestonePickerController];
        [popover setAnimates:YES];
        
        if ([NSUserDefaults themeMode] == SRThemeModeDark) {
            NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            popover.appearance = appearance;
        } else {
            NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            popover.appearance = appearance;
        }
        
        [self.view.window makeFirstResponder:self.view];
        [popover setBehavior:NSPopoverBehaviorTransient];
        [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSRectEdgeMaxY];
        milestonePickerController.popover = popover;
        
    } else if (sender == self.extensionButton) {

        
        NSMenu *menu = [SRMenuUtilities menuForExtensions];
        NSPoint pointInWindow = [self.extensionButton convertPoint:CGPointZero toView:nil];
        NSPoint point = NSMakePoint(pointInWindow.x, pointInWindow.y - self.extensionButton.frame.size.height);
        NSEvent *popupEvent = [NSEvent mouseEventWithType:NSLeftMouseUp location:point modifierFlags:[NSApp currentEvent].modifierFlags timestamp:0 windowNumber:self.view.window.windowNumber context:nil eventNumber:0 clickCount:0 pressure:0];
        
        [SRMenu popUpContextMenu:menu withEvent:popupEvent forView:self.extensionButton];
        
    }
}

- (void)_setupCommentEditorView
{
    __weak QIssueDetailsViewController *weakSelf = self;
    self.commentEditorView.onTextChange = ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            QIssueDetailsViewController *strongSelf = weakSelf;
            
            if (!strongSelf) {
                return;
            }
            
            NSString *currentText = strongSelf.commentEditorView.text.trimmedString ?: @"";
            
            SRIssueCommentDraft *draft = [[SRIssueCommentDraft alloc] initWithAccount:strongSelf.issue.account
                                                                           repository:strongSelf.issue.repository
                                                                       issueCommentId:nil
                                                                          issueNumber:strongSelf.issue.number
                                                                                 body:currentText
                                                                                 type:SRIssueCommentDraftTypeComment];
            if (draft.body.length > 0) {
                [QIssueCommentDraftStore saveIssueCommentDraft:draft];
                [strongSelf.dataSource addIssueCommentDraft:draft];
            } else if (strongSelf.commentEditorView.isFirstResponder) {
                SRIssueCommentDraft *draft = [strongSelf.dataSource issueCommentDraftForCurrentIssue];
                if (draft) {
                    [strongSelf _deleteNewDraftComment];
                }
            }
        });
    };
    
    self.commentEditorView.onDiscard = ^{
        QIssueDetailsViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (strongSelf.commentEditorView.text.trimmedString.length == 0) {
            [strongSelf.view.window makeFirstResponder:nil];
            return;
        }
        
        [NSAlert showWarningMessage:@"Are you sure you want to discard the comment?" onConfirmation:^{
            [strongSelf.view.window makeFirstResponder:nil];
            [strongSelf.commentEditorView clearText];
            [strongSelf _deleteNewDraftComment];
        }];
    };
    
    self.commentEditorView.onSubmit = ^{
        QIssueDetailsViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        NSString *adjustedBody = [strongSelf.commentEditorView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (adjustedBody && adjustedBody.length > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.commentEditorView.loading = true;
            });
            [[QIssuesService serviceForAccount:strongSelf.issue.account] createCommentForRepository:strongSelf.issue.repository issueNumber:strongSelf.issue.number body:adjustedBody onCompletion:^(QIssueComment *comment, QServiceResponseContext *context, NSError *error) {
                if (!error) {
                    [strongSelf _deleteNewDraftComment];
                    [QIssueCommentStore saveIssueComment:comment];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.commentEditorView clearText];
                        [strongSelf.commentEditorView clearPreviewModeIfNecessary];
                        [strongSelf.view.window makeFirstResponder:nil];
                    });
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.commentEditorView.loading = false;
                });
            }];
        }
    };
}

- (void)_deleteNewDraftComment
{
    SRIssueCommentDraft *draft = [[SRIssueCommentDraft alloc] initWithAccount:self.issue.account
                                                                   repository:self.issue.repository
                                                               issueCommentId:nil
                                                                  issueNumber:self.issue.number
                                                                         body:@""
                                                                         type:SRIssueCommentDraftTypeComment];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [QIssueCommentDraftStore deleteIssueCommentDraft:draft];
        [self.dataSource removeIssueCommentDraft:draft];
    });
}

- (void)_setupActivityTableView
{
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"IssueCommentTableViewCell" bundle:nil];
    [self.activityTableView registerNib:nib forIdentifier:@"IssueCommentTableViewCell"];
    
    nib = [[NSNib alloc] initWithNibNamed:@"IssueEventTableViewCell" bundle:nil];
    [self.activityTableView registerNib:nib forIdentifier:@"IssueEventTableViewCell"];
    
//    nib = [[NSNib alloc] initWithNibNamed:@"IssueDetailLabelsTableViewCell" bundle:nil];
//    [self.activityTableView registerNib:nib forIdentifier:@"IssueDetailLabelsTableViewCell"];
    
    self.activityTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
}

- (void)_setupTitleLabels
{
    SRBaseTextField *(^createAndAddQTextFieldToView)(BaseView *) = ^SRBaseTextField *(BaseView *parentView) {
        SRBaseTextField *view = [[SRBaseTextField alloc] init];
        
        view.drawsBackground = false;
        view.bordered = false;
        view.cell.wraps = NO;
        view.lineBreakMode = NSLineBreakByTruncatingTail;
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [parentView addSubview:view];
        
        [view.leftAnchor constraintEqualToAnchor:parentView.leftAnchor].active = YES;
        [view.rightAnchor constraintEqualToAnchor:parentView.rightAnchor].active = YES;
        
        [view.topAnchor constraintEqualToAnchor:parentView.topAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor].active = YES;
        
        return view;
    };
    
    self.titleTextField = createAndAddQTextFieldToView(_titleContainerView);
    self.titleTextField.textColor = [SRCashewColor foregroundColor];
    self.titleTextField.delegate = self;
    [self.titleTextField setFont:[NSFont systemFontOfSize:26]];
    [self.titleTextField setEditable:NO];
    self.titleTextField.usesSingleLineMode = true;
    [(NSTextFieldCell *)self.titleTextField.cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [self.titleTextField setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    
//    self.numberTextField = createAndAddQTextFieldToView(_numberContainerView);
//    [self.numberTextField setEditable:NO];
//    [self.numberTextField setFont:[NSFont systemFontOfSize:26 weight:NSFontWeightLight]];
//    [self.numberTextField setTextColor:[NSColor colorWithWhite:154/255. alpha:1]];
//    
//    [self.numberTextField setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
//    [self.numberTextField setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
//    [self.numberTextField setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
//    [self.numberTextField setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
//    
//    NSClickGestureRecognizer *clickGesture = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_openURLForCurrentIssue:)];
//    clickGesture.numberOfClicksRequired = 1;
//    [self.numberTextField addGestureRecognizer:clickGesture];
    
    
}

- (IBAction)_openURLForCurrentIssue:(id)sender
{
    if (_issue) {
        SRMenu *menu = [SRMenu new];
        
        NSMenuItem *copyIssueNumberAndTitleMenuItem = [[NSMenuItem alloc] initWithTitle:@"Copy Issue number and Title" action:@selector(_copyIssueNumberAndTitle:) keyEquivalent:@""];
        [menu addItem:copyIssueNumberAndTitleMenuItem];
        
        NSMenuItem *copyIssueNumberMenuItem = [[NSMenuItem alloc] initWithTitle:@"Copy Issue number" action:@selector(_copyIssueNumber:) keyEquivalent:@""];
        [menu addItem:copyIssueNumberMenuItem];
        
        NSMenuItem *copyURLMenuItem = [[NSMenuItem alloc] initWithTitle:@"Copy URL" action:@selector(_copyURL:) keyEquivalent:@""];
        [menu addItem:copyURLMenuItem];
        
        NSMenuItem *createIssueMenuItem = [[NSMenuItem alloc] initWithTitle:@"Go to Github" action:@selector(_openGithub:) keyEquivalent:@""];
        [menu addItem:createIssueMenuItem];
        
        self.menuButton.menu = menu;
        

        NSPoint pointInWindow = [self.menuButton convertPoint:CGPointZero toView:nil];
        NSPoint point = NSMakePoint(pointInWindow.x + self.menuButton.frame.size.width, pointInWindow.y - self.menuButton.frame.size.height);
        NSEvent *popupEvent = [NSEvent mouseEventWithType:NSLeftMouseUp location:point modifierFlags:[NSApp currentEvent].modifierFlags timestamp:0 windowNumber:self.view.window.windowNumber context:nil eventNumber:0 clickCount:0 pressure:0];
        

        [SRMenu popUpContextMenu:menu withEvent:popupEvent forView:self.menuButton];
        
    }
}

- (void)_openGithub:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://www.github.com/%@/issues/%@", _issue.repository.fullName, _issue.number];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void)_copyURL:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://www.github.com/%@/issues/%@", _issue.repository.fullName, _issue.number];
    [self _writeToPasteBoard:url];
}

- (void)_copyIssueNumber:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"#%@", self.issue.number];
    [self _writeToPasteBoard:url];
}

- (void)_copyIssueNumberAndTitle:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"%@ - #%@", self.issue.title.trimmedString, self.issue.number];
    [self _writeToPasteBoard:url];
}

- (BOOL)_writeToPasteBoard:(NSString *)stringToWrite
{
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    return [[NSPasteboard generalPasteboard] setString:stringToWrite forType:NSStringPboardType];
}

- (void)_windowDidEndLiveResizeNotification:(NSNotification *)notification
{
    if (notification.object != self.view.window) {
        return;
    }
    NSRect visibleRect = [_activityScrollView.contentView visibleRect];
    
    // find first row fully visible
    NSInteger firstRow = NSNotFound;
    CGFloat delta = 0;
    for (NSInteger i = 0; i < self.dataSource.numberOfItems; i++) {
        NSRect rowRect = [_activityTableView rectOfRow:i];
        if (rowRect.origin.y >= visibleRect.origin.y) {
            firstRow = i;
            delta = rowRect.origin.y - visibleRect.origin.y;
            break;
        }
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        [context setDuration:0];
        [_activityTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.dataSource.numberOfItems)]];
        
        NSRect firstRowRect = [_activityTableView rectOfRow:firstRow];
        NSPoint scrollToPoint = NSMakePoint(firstRowRect.origin.x, firstRowRect.origin.y - delta);
        [_activityTableView scrollPoint:scrollToPoint];
    } completionHandler:^{
        NSRect firstRowRect = [_activityTableView rectOfRow:firstRow];
        NSPoint scrollToPoint = NSMakePoint(firstRowRect.origin.x, firstRowRect.origin.y - delta);
        [_activityTableView scrollPoint:scrollToPoint];
    }];
}

- (void)_syncIssueEventsForCurrentIssueUsingSinceDate:(NSDate *)sinceDate
{
    QIssuesService *service = [QIssuesService serviceForAccount:self.issue.account];
    [service fetchAllIssuesEventsForRepository:self.issue.repository issueNumber:self.issue.number pageNumber:1 since:sinceDate onCompletion:^(NSArray<QIssueEvent *> *events, QServiceResponseContext *context, NSError *error) {
        [events enumerateObjectsUsingBlock:^(QIssueEvent * event, NSUInteger idx, BOOL * _Nonnull stop) {
            [QIssueEventStore saveIssueEvent:event];
        }];
    }];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row >= self.dataSource.numberOfItems) {
        return nil;
    }
    
    NSParameterAssert([NSThread isMainThread]);
    [tableColumn setWidth:CGRectGetWidth(_activityTableView.frame)];
    
    id item = [self.dataSource itemAtIndex:row]; //_items[row];
    __weak QIssueDetailsViewController *weakSelf = self;
    
    if ([item conformsToProtocol:@protocol(SRIssueEventInfo)]) { //([item isKindOfClass:[QIssueEvent class]]) {
        IssueEventTableViewCell *view = [_activityTableView makeViewWithIdentifier:@"IssueEventTableViewCell" owner:self];
        view.issueEvent = item;
        
        view.onHeightChanged = ^{
            QIssueDetailsViewController *strongSelf = weakSelf;
            if (strongSelf) {
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                    [context setDuration:0];
                    [strongSelf.activityTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, 1)]];
                } completionHandler:nil];
            };
        };
        return view;
        
//    } else if ([item isKindOfClass:SRIssueDetailLabelsTableViewModel.class]) {
//        SRIssueDetailLabelsTableViewCell *view = [_activityTableView makeViewWithIdentifier:@"IssueDetailLabelsTableViewCell" owner:self];
//        self.labelsTableViewCell = view;
//        view.viewModel = (SRIssueDetailLabelsTableViewModel *)item;
//        return view;
//        
    } else {
        
        id<QIssueCommentInfo> issueInfo = (id<QIssueCommentInfo>)item;
        
        IssueCommentTableViewCell *view = [self.editableFieldsCache objectForKey:issueInfo];
        //strongSelf.editing = true
        
        if (!view || ![issueInfo.commentBody isEqualToString:view.commentInfo.commentBody]) { //![issueInfo.commentUpdatedAt isEqualToDate:view.commentInfo.commentUpdatedAt]) {
            
            view = [IssueCommentTableViewCell instantiateFromNib]; //[_activityTableView makeViewWithIdentifier:@"IssueCommentTableViewCell" owner:self];
            [self.editableFieldsCache setObject:view forKey:issueInfo];
            __weak IssueCommentTableViewCell *weakView = view;
            view.onHeightChanged = ^{
                QIssueDetailsViewController *strongSelf = weakSelf;
                IssueCommentTableViewCell *strongView = weakView;
                
                if (strongView.intrinsicContentSize.height == [strongSelf.dataSource webViewLayoutCacheForRow:row]) {
                    return;
                }
                
                if (strongSelf) {
                    //DDLogDebug(@"rect.size.height-> %@", @(rect.size.height));
                    [strongSelf.dataSource updateWebViewLayoutCache:strongView.intrinsicContentSize.height forRow:row];
                    
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                        [context setDuration:0];
                        [strongSelf.activityTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, 1)]];
                    } completionHandler:nil];
                };
            };
            
            view.onTextChange = ^{
                QIssueDetailsViewController *strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                NSString *currentText = weakView.text.trimmedString ?: @"";
                //                if ([issueInfo.commentBody.trimmedString isEqualToString:currentText]) {
                //                    return;
                //                }
                
                if ([issueInfo isKindOfClass:QIssue.class]) {
                    SRIssueCommentDraft *draft = [[SRIssueCommentDraft alloc] initWithAccount:strongSelf.issue.account
                                                                                   repository:strongSelf.issue.repository
                                                                               issueCommentId:nil
                                                                                  issueNumber:strongSelf.issue.number
                                                                                         body:currentText
                                                                                         type:SRIssueCommentDraftTypeIssue];
                    
                    if (draft.body.length > 0) {
                        if ([currentText isEqualToString:issueInfo.commentBody]) {
                            SRIssueCommentDraft *deletableDraft = [strongSelf.dataSource issueCommentDraftForIssueComment:issueInfo];
                            if (deletableDraft) {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                    [QIssueCommentDraftStore deleteIssueCommentDraft:deletableDraft];
                                });
                            }
                            
                        } else {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                [QIssueCommentDraftStore saveIssueCommentDraft:draft];
                            });
                            [strongSelf.dataSource addIssueCommentDraft:draft];
                        }
                    } else {
                        SRIssueCommentDraft *deletableDraft = [strongSelf.dataSource issueCommentDraftForIssueComment:issueInfo];
                        if (deletableDraft) {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                [QIssueCommentDraftStore deleteIssueCommentDraft:deletableDraft];
                            });
                        }
                    }
                    
                } else if ([issueInfo isKindOfClass:QIssueComment.class]) {
                    QIssueComment *comment = (QIssueComment *)issueInfo;
                    
                    SRIssueCommentDraft *draft = [[SRIssueCommentDraft alloc] initWithAccount:strongSelf.issue.account
                                                                                   repository:strongSelf.issue.repository
                                                                               issueCommentId:comment.identifier
                                                                                  issueNumber:strongSelf.issue.number
                                                                                         body:currentText
                                                                                         type:SRIssueCommentDraftTypeComment];
                    if (draft.body.length > 0) {
                        if ([currentText isEqualToString:issueInfo.commentBody]) {
                            SRIssueCommentDraft *deletableDraft = [strongSelf.dataSource issueCommentDraftForIssueComment:issueInfo];
                            if (deletableDraft) {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                    [QIssueCommentDraftStore deleteIssueCommentDraft:deletableDraft];
                                });
                            }
                            
                        } else {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                [QIssueCommentDraftStore saveIssueCommentDraft:draft];
                            });
                            [strongSelf.dataSource addIssueCommentDraft:draft];
                        }
                    } else {
                        SRIssueCommentDraft *deletableDraft = [strongSelf.dataSource issueCommentDraftForIssueComment:issueInfo];
                        if (deletableDraft) {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                [QIssueCommentDraftStore deleteIssueCommentDraft:deletableDraft];
                            });
                        }
                    }
                }
                
            };
            
            view.onCommentDiscard = ^{
                QIssueDetailsViewController *strongSelf = weakSelf;
                if ([issueInfo isKindOfClass:QIssue.class]) {
                    SRIssueCommentDraft *draft = [[SRIssueCommentDraft alloc] initWithAccount:strongSelf.issue.account
                                                                                   repository:strongSelf.issue.repository
                                                                               issueCommentId:nil
                                                                                  issueNumber:strongSelf.issue.number
                                                                                         body:@""
                                                                                         type:SRIssueCommentDraftTypeIssue];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [QIssueCommentDraftStore deleteIssueCommentDraft:draft];
                    });
                    [strongSelf.dataSource removeIssueCommentDraft:draft];
                    
                } else if ([issueInfo isKindOfClass:QIssueComment.class]) {
                    QIssueComment *comment = (QIssueComment *)issueInfo;
                    
                    SRIssueCommentDraft *draft = [[SRIssueCommentDraft alloc] initWithAccount:strongSelf.issue.account
                                                                                   repository:strongSelf.issue.repository
                                                                               issueCommentId:comment.identifier
                                                                                  issueNumber:strongSelf.issue.number
                                                                                         body:@""
                                                                                         type:SRIssueCommentDraftTypeComment];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [QIssueCommentDraftStore deleteIssueCommentDraft:draft];
                    });
                    [strongSelf.dataSource removeIssueCommentDraft:draft];
                }
                
            };
            
            [view setCommentInfo:issueInfo];
            view.draft = [self.dataSource issueCommentDraftForIssueComment:issueInfo];
        }
        
        view.didClickImageBlock = ^(NSURL *url){
            [weakSelf _didClickImageWithURL:url];
        };
        return view;
    }
}



- (void)_didClickImageWithURL:(NSURL *)url {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    NSMutableArray<NSURL *> *imageURLs = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < self.dataSource.numberOfItems; i++) {
        NSView *view = [self.activityTableView  viewAtColumn:0 row:i makeIfNecessary:YES];
        if ([view isKindOfClass:IssueCommentTableViewCell.class]) {
            IssueCommentTableViewCell *commentTableViewCell = (IssueCommentTableViewCell *)view;
            [imageURLs addObjectsFromArray:commentTableViewCell.imageURLs];
        }
    }
    
    if (url) {
        [userInfo setObject:url forKey:@"selectedURL"];
        NSUInteger index = [imageURLs indexOfObject:url];
        if (index != NSNotFound) {
            NSURL *firstURL = imageURLs.firstObject;
            imageURLs[index] = firstURL;
            imageURLs[0] = url;
        } else {
            [imageURLs insertObject:url atIndex:0];
        }
    }
    if (self.issue) {
        [userInfo setObject:self.issue forKey:@"issue"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSRShowImageViewerNotification object:imageURLs userInfo:userInfo];
    
}

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
    if ([responder isKindOfClass:[EditableMarkdownView class]]) {
        return YES;
    }
    
    if ([responder isKindOfClass:[IssueCommentTableViewCell class]]) {
        return YES;
    }
    
    if ([responder isKindOfClass:[BaseButton class]]) {
        return YES;
    }
    
    return [super validateProposedFirstResponder:responder forEvent:event];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row;
{
    if (row >= self.dataSource.numberOfItems) {
        return 1;
    }
    id item = [self.dataSource itemAtIndex:row];
    
    __block CGFloat height = 1;
    dispatch_block_t block = ^{
        if ([item isKindOfClass:[QIssueEvent class]] || [item isKindOfClass:[SRIssueEventViewModel class]]) {
            height = [IssueEventTableViewCell heightForIssueEvent:item width: self.activityTableView.frame.size.width];
            
//        } else if ([item isKindOfClass:SRIssueDetailLabelsTableViewModel.class]) {
//            height = [SRIssueDetailLabelsTableViewCell suggestedHeight];
//        } else {
//            
//        }
        } else {
            height = [self.dataSource webViewLayoutCacheForRow:row];
        }
        
        height = MAX(1, height);
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    
    NSParameterAssert(height > 0);
    return height;
    
    
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row;
{
    return NO;
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return self.dataSource.numberOfItems;
}


#pragma mark - Scroll View
- (void)scrollViewDidScroll:(NSNotification *)notification
{
    self.titleSeparatorView.hidden = (self.activityScrollView.documentVisibleRect.origin.y <= 0);
}

#pragma mark - QStoreObserver

- (void)store:(Class)store didInsertRecord:(id)record;
{
    if (store == QIssueFavoriteStore.class && [record isKindOfClass:QIssue.class]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _updateFavoriteButtonState];
        });
    }
}

- (void)store:(Class)store didUpdateRecord:(id)record;
{
    if (store == QIssueStore.class && [record isKindOfClass:QIssue.class]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            QIssue *updatedIssue = (QIssue *)record;
            if ([updatedIssue isEqualToIssue:self.issue]) {
                [self setIssue:updatedIssue];
            }
        });
    }
}

- (void)store:(Class)store didRemoveRecord:(id)record;
{
    if (store == QIssueFavoriteStore.class && [record isKindOfClass:QIssue.class]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _updateFavoriteButtonState];
        });
    }
}

- (IBAction)didClickFavoriteButton:(id)sender
{
    BOOL isFavorited = [QIssueFavoriteStore isFavoritedIssue:self.issue];
    if (isFavorited) {
        [QIssueFavoriteStore unfavoriteIssue:self.issue];
    } else {
        [QIssueFavoriteStore favoriteIssue:self.issue];
    }
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)notification;
{
    __weak QIssueDetailsViewController *weakSelf = self;
    
    if (self.titleTextField == notification.object) {
        self.titleTextField.editable = false;
        [self.titleTextField.window makeFirstResponder:nil];
        NSString *title = self.titleTextField.stringValue.trimmedString;
        if (title.length > 0) {
            if (![title isEqualToString:self.issue.title]) {
                QAccount *account = [QContext sharedContext].currentAccount;
                QIssuesService *service = [QIssuesService serviceForAccount:account];
                [service saveIssueTitle:title forRepository:self.issue.repository number:self.issue.number onCompletion:^(QIssue *issue, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
                    QIssueDetailsViewController *strongSelf = weakSelf;
                    if (!strongSelf) {
                        return;
                    }
                    
                    if (!error && issue) {
                        [strongSelf _syncIssueEventsForCurrentIssueUsingSinceDate:strongSelf.issue.updatedAt];
                        [QIssueStore saveIssue:issue];
                    }
                    strongSelf.titleTextField.editable = true;
                }];
            } else {
                self.titleTextField.editable = true;
            }
        } else {
            [NSAlert showOKWarningMessage:@"Issue Title cannot be empty" onCompletion:^{
                QIssueDetailsViewController *strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                
                strongSelf.titleTextField.stringValue = strongSelf.issue.title;
                strongSelf.titleTextField.editable = true;
            }];
        }
    }
}

#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)notification;
{
    if (notification.object == self.assigneePopover) {
        self.assigneePopover = nil;
    }
    
    else if (notification.object == self.milestonePopover) {
        self.milestonePopover = nil;
    }
}

@end
