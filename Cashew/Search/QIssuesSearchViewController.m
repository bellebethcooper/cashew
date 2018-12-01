//
//  QIssuesSearchViewController.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssuesSearchViewController.h"
#import "QView.h"
#import "QContext.h"
#import "QOwnerStore.h"
#import "QRepositoryStore.h"
#import "QOwnerStore.h"
#import "QMilestoneStore.h"
#import "QLabelStore.h"
#import "NSColor+Hex.h"
#import "QUserQueryStore.h"
#import "SRUserQueryNameViewController.h"
#import "Cashew-Swift.h"


@interface QIssuesSearchViewController () <NSTokenFieldDelegate, SRUserQueryNameViewControllerDelegate, NSPopoverDelegate, NSWindowDelegate>

@property (strong, readwrite) IBOutlet SRIssuesSearchTokenField *searchField;
@property (weak) IBOutlet QView *searchFieldContainerView;
@property (strong) NSPopover *userQueryNamePopover;
@property (weak) IBOutlet NSButton *saveSearchButton;
@property (nonatomic) SRCoalescer *saveSearchButtonCoalescer;
@property (nonatomic) SearchSuggestionWindowController *suggestionWindowController;
@property (nonatomic) SRCoalescer *suggestionCoalescer;
@property (nonatomic) SRCoalescer *tokenFieldCoalescer;
@property (nonatomic) NSString *representedObjectForEditingString;

@end

@implementation QIssuesSearchViewController {
    //NSArray<NSString *> *_mostRecentTokenList;
}

- (void)focus;
{
    [self.view.window makeFirstResponder:_searchField];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    BaseView *view  = (BaseView *)self.view;
    view.backgroundColor = [NSColor clearColor];
    view.cornerRadius = 4.0;
    
    self.saveSearchButton.hidden = true;
    self.saveSearchButtonCoalescer = [[SRCoalescer alloc] initWithInterval:0.1 name:@"co.cashewapp.Coalescer.accessQueue.QIssueSearchViewController.saveSearchButtonCoalescer" executionQueue:dispatch_get_main_queue()];
    self.suggestionCoalescer = [[SRCoalescer alloc] initWithInterval:0.05 name:@"co.cashewapp.Coalescer.accessQueue.QIssueSearchViewController.suggestionCoalescer" executionQueue:dispatch_get_main_queue()];
    self.tokenFieldCoalescer = [[SRCoalescer alloc] initWithInterval:0.3 name:@"co.cashewapp.Coalescer.accessQueue.QIssueSearchViewController.tokenFieldCoalescer" executionQueue:dispatch_get_main_queue()];
    
    [self _setupDataSource];
    [self _setupSearchFieldContainerView];
    [self _setupSearchField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didContextIssueFilterChange:) name:kQContextChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didClickShowSaveSearchDisplayPopoverNotification:) name:kShowSaveSearchDisplayNamePopoverNotification object:nil];
    
    __weak QIssuesSearchViewController *weakSelf = self;
    
    self.searchFieldContainerView.disableThemeObserver = true;
    view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    self.searchField.appearance = view.appearance;
    self.searchField.drawsBackground = true;
    
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        [weakSelf dismissSuggestionWindowController];
        
        NSAppearance *appearance = nil;
       // NSColor *placeholderColor = [NSColor colorWithCalibratedWhite:174/255.0 alpha:1];
        if (mode == SRThemeModeDark) {
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
            weakSelf.searchField.backgroundColor = [NSColor colorWithCalibratedWhite:42/255.0 alpha:1];
            view.borderColor = [NSColor colorWithCalibratedWhite:67/255.0 alpha:1];
            weakSelf.searchField.textColor = [SRCashewColor foregroundColor];
        } else {
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
            weakSelf.searchField.backgroundColor = [NSColor whiteColor];
            view.borderColor = [NSColor colorWithCalibratedWhite:195/255.0 alpha:1];
            weakSelf.searchField.textColor = [SRCashewColor foregroundSecondaryColor];
        }
        
        weakSelf.searchFieldContainerView.appearance = appearance;
        weakSelf.searchField.appearance = appearance;
        weakSelf.searchFieldContainerView.backgroundColor = weakSelf.searchField.backgroundColor;
    }];
    
}

- (void)_didContextIssueFilterChange:(NSNotification *)notification
{
    if (notification.object != self) {
        QIssueFilter *filter = [[QContext sharedContext] currentFilter];
        [_searchField setObjectValue:filter.searchTokensArray];
    }
}


- (void)_fireSearch:(id)sender
{
    NSArray *currentTokens = [_searchField objectValue];
    //NSArray *previousTokens = _mostRecentTokenList;
    // if ([currentTokens isEqualToArray:previousTokens] == NO) {
    //DDLogDebug(@"%@ -> [%@]", NSStringFromSelector(_cmd), [currentTokens componentsJoinedByString:@" "]);
  //  _mostRecentTokenList = currentTokens;
    
    QIssueFilter *currentFilter = [[QContext sharedContext] currentFilter];
    QIssueFilter *filter = [QIssueFilter filterWithSearchTokensArray:currentTokens];
    [filter setAccount:currentFilter.account];
    
    
    if (currentFilter) {
        //filter.filterType = currentFilter.filterType;
        [filter setSortKey:currentFilter.sortKey];
        [filter setAscending:currentFilter.ascending];
    }
    
    if ([currentTokens count] > 0) {
        NSString *q = [self _parseTextString:currentTokens];
        if (q.length > 0) {
            [filter setQuery:q];
        }
        
    }
    
    [[QContext sharedContext] setCurrentFilter:filter sender:self];
    //  }
}


- (NSString *)_parseTextString:(NSArray *)currentTokens
{
    __block NSMutableString *searchToken = [NSMutableString new];
    [currentTokens enumerateObjectsUsingBlock:^(NSString * _Nonnull token, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *trimmedToken = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSError *error = NULL;
        NSString *pattern = @"(^|\\s+)(\\#(\\d+))";
        NSRange range = NSMakeRange(0, trimmedToken.length);
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regex matchesInString:trimmedToken options:0 range:range];
        
        BOOL queryToken = matches.count == 0 && ([trimmedToken rangeOfString:@":"].location == NSNotFound);
        if (queryToken) {
            [searchToken appendString:[token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            [searchToken appendString:@" "];
        }
    }];
    
    NSString *q = [searchToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return q;
}

#pragma mark - DataSource

- (void)_setupDataSource {
    
}



#pragma mark - Setup


- (void)_setupSearchField
{
    [_searchField setBezeled:NO];
    [_searchField.cell setFocusRingType:NSFocusRingTypeNone];
    [_searchField setDelegate:self];
    //[_searchField setCompletionDelay:0.3];
    _searchField.tokenStyle = NSTokenStyleSquared;
    
    __weak QIssuesSearchViewController *weakSelf = self;
    _searchField.didBecomeFirstResponderBlock = ^{
        [[weakSelf saveSearchButtonCoalescer] executeBlock:^{
            [weakSelf saveSearchButton].hidden = false;
        }];
    };
    
//    _SRIssueSearchTokeFieldCell *newCell = [[_SRIssueSearchTokeFieldCell alloc] init];
//    [newCell setBordered:NO]; // so background color shows up
//    [newCell setBezeled:NO];
//    [newCell setEditable:YES];
//    [newCell setFocusRingType:NSFocusRingTypeNone];
//    [newCell setTitle:@""];
//    [newCell setPlaceholderString:@"Issue Search"];
//    [self.searchField setCell:newCell];
}

- (void)_setupSearchFieldContainerView
{
    self.searchFieldContainerView.disableThemeObserver = true;
    [self.searchFieldContainerView setBackgroundColor:[NSColor whiteColor]];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.searchFieldContainerView.layer setBorderColor:[NSColor colorWithWhite:.97 alpha:1].CGColor];
    [self.searchFieldContainerView.layer setBorderWidth:1];
    [self.searchFieldContainerView.layer setCornerRadius:3.0];
    [CATransaction commit];
}

#pragma mark - NSTokenFieldDelegate

- (void)controlTextDidBeginEditing:(NSNotification *)obj;
{
    [self.saveSearchButtonCoalescer executeBlock:^{
        self.saveSearchButton.hidden = false;
    }];
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        if (self.suggestionWindowController) {
    //            [self.suggestionWindowController showWindow:self];
    //            return;
    //        }
    //    });
}

- (void)controlTextDidEndEditing:(NSNotification *)obj;
{
    [self.saveSearchButtonCoalescer executeBlock:^{
        if (!self.userQueryNamePopover) {
            self.saveSearchButton.hidden = true;
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.suggestionWindowController) {
            return;
        }
        
        [self dismissSuggestionWindowController];
        
    });
}

- (void)_moveSuggestionWindowIfShowing
{
    SearchSuggestionViewController *suggestionViewController = self.suggestionWindowController.suggestionViewController;
    if (suggestionViewController) {
        
        if (self.representedObjectForEditingString) {
            NSMutableArray *objects = [self.searchField.objectValue mutableCopy];
            __block NSUInteger indexOfEditingObject = NSNotFound;
            [objects enumerateObjectsUsingBlock:^(NSString  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([self.representedObjectForEditingString isEqualToString:obj]) {
                    indexOfEditingObject = idx;
                    *stop = YES;
                }
            }];
            if (indexOfEditingObject == NSNotFound) {
                [self dismissSuggestionWindowController];
                return;
            }
        }
        
        NSTextView *fieldEditor = (NSTextView *)[self.view.window fieldEditor:NO forObject:self.searchField];
        if (fieldEditor) {
            NSRange cursorRange = [[[fieldEditor selectedRanges] objectAtIndex:0] rangeValue];
            NSRect rect = [fieldEditor firstRectForCharacterRange:cursorRange actualRange:nil];
            NSRect mainWindowFrame = self.view.window.frame;
            CGFloat windowHeight = suggestionViewController.calculatedHeight;
            CGFloat windowLeft = rect.origin.x - 15;
            NSRect suggestionWindowFrame = NSMakeRect(0, 0, 300, windowHeight);
            [self.suggestionWindowController.window setFrame:suggestionWindowFrame display:YES];
            [self.suggestionWindowController.window setFrameTopLeftPoint:CGPointMake(windowLeft, mainWindowFrame.origin.y + mainWindowFrame.size.height - self.view.frame.size.height)];
        }
    }
}

- (void)controlTextDidChange:(NSNotification *)obj;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // move suggestion window if showing
        [self _moveSuggestionWindowIfShowing];
        //
        //        if (_tokenFieldCoalescerTimer) {
        //            [_tokenFieldCoalescerTimer invalidate];
        //        }
        //        _tokenFieldCoalescerTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_fireSearch:) userInfo:nil repeats:NO];
        //
        [self.tokenFieldCoalescer executeBlock:^{
            [self _fireSearch:nil];
        }];
    });
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
    
    NSArray<NSString *> *pieces = [[representedObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@":"];
    
    if (pieces.count > 2) {
        NSMutableString *str = [NSMutableString new];
        [pieces enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx != 0) {
                [str appendString:obj];
                
                if (idx != pieces.count-1) {
                    [str appendString:@":"];
                }
            }
        }];
        pieces = @[pieces[0], str.copy];
    }
    
    
    if (pieces.count == 2) {
        NSString *key = [pieces[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *val = [pieces[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        //if ([val rangeOfString:@" "].location != NSNotFound) {
        if ( [@[ @"is",@"assignee", @"author", @"mentions",@"milestone", @"repo", @"label", @"-assignee", @"-author", @"-mentions",@"-milestone", @"-repo", @"-label"] containsObject:key]) {
            if ([val rangeOfString:@" "].location != NSNotFound) {
                if (![val hasPrefix:@"\""]) {
                    val = [NSString stringWithFormat:@"\"%@", val];
                }
                if (![val hasSuffix:@"\""]) {
                    val = [NSString stringWithFormat:@"%@\"", val];
                }
            }
            // }
        }
        
        return [NSString stringWithFormat:@"%@:%@", key, val];
    }
    
    return representedObject;
}


- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)idx
{
    //DDLogDebug(@"cmd = %@", NSStringFromSelector(_cmd));
    
    NSMutableString *query = [NSMutableString new];
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
    
    [tokens enumerateObjectsUsingBlock:^(NSString *  _Nonnull token, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isQueryToken = ([token rangeOfString:@":"].location == NSNotFound);
        if (isQueryToken) {
            
            NSString *adjusted = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [query appendString:adjusted];
            [query appendString:@" "];
        } else {
            [set addObject:token];
        }
    }];
    
    if (query.length > 0) {
        [set addObject:[query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    
    return [set array];
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    //DDLogDebug(@"cmd = %@", NSStringFromSelector(_cmd));
    return representedObject;
    
}

- (nullable SRMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject;
{
    SRMenu *menu = [[SRMenu alloc] init];
    
    [menu addItemWithTitle:@"Author" action:@selector(_changeToAuthor:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Assignee" action:@selector(_changeToAssignee:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Mentions" action:@selector(_changeToMentions:) keyEquivalent:@""];
    
    return menu;
}

- (void)_changeToAssignee:(id)sender
{
    NSTextView *fieldEditor = (NSTextView *)[self.view.window fieldEditor:NO forObject:self.searchField];
    if (fieldEditor) {
        NSRange selectionRange = [[[fieldEditor selectedRanges] objectAtIndex:0] rangeValue];
        NSMutableArray *objects = [[self.searchField objectValue] mutableCopy];
        NSString *object = [objects objectAtIndex:selectionRange.location];
        if ([object hasPrefix:@"assignee:"]) {
            return;
        } else if ([object hasPrefix:@"mentions:"]) {
            objects[selectionRange.location] = [NSString stringWithFormat:@"assignee:%@", [object substringFromIndex:9]];
        }  else if ([object hasPrefix:@"author:"]) {
            objects[selectionRange.location] = [NSString stringWithFormat:@"assignee:%@", [object substringFromIndex:7]];
        }
        self.searchField.objectValue = objects;
        [self _fireSearch:nil];
        //DDLogDebug(@"%@", [objects objectAtIndex:selectionRange.location]);
    }
}

- (void)_changeToAuthor:(id)sender
{
    NSTextView *fieldEditor = (NSTextView *)[self.view.window fieldEditor:NO forObject:self.searchField];
    if (fieldEditor) {
        NSRange selectionRange = [[[fieldEditor selectedRanges] objectAtIndex:0] rangeValue];
        NSMutableArray *objects = [[self.searchField objectValue] mutableCopy];
        NSString *object = [objects objectAtIndex:selectionRange.location];
        if ([object hasPrefix:@"author:"]) {
            return;
        } else if ([object hasPrefix:@"mentions:"]) {
            objects[selectionRange.location] = [NSString stringWithFormat:@"author:%@", [object substringFromIndex:9]];
        }  else if ([object hasPrefix:@"assignee:"]) {
            objects[selectionRange.location] = [NSString stringWithFormat:@"author:%@", [object substringFromIndex:9]];
        }
        self.searchField.objectValue = objects;
        [self _fireSearch:nil];
        //DDLogDebug(@"%@", [objects objectAtIndex:selectionRange.location]);
    }
}


- (void)_changeToMentions:(id)sender
{
    NSTextView *fieldEditor = (NSTextView *)[self.view.window fieldEditor:NO forObject:self.searchField];
    if (fieldEditor) {
        NSRange selectionRange = [[[fieldEditor selectedRanges] objectAtIndex:0] rangeValue];
        NSMutableArray *objects = [[self.searchField objectValue] mutableCopy];
        NSString *object = [objects objectAtIndex:selectionRange.location];
        if ([object hasPrefix:@"mentions:"]) {
            return;
        } else if ([object hasPrefix:@"author:"]) {
            objects[selectionRange.location] = [NSString stringWithFormat:@"mentions:%@", [object substringFromIndex:7]];
        }  else if ([object hasPrefix:@"assignee:"]) {
            objects[selectionRange.location] = [NSString stringWithFormat:@"mentions:%@", [object substringFromIndex:9]];
        }
        self.searchField.objectValue = objects;
        [self _fireSearch:nil];
        //DDLogDebug(@"%@", [objects objectAtIndex:selectionRange.location]);
    }
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject;
{
    return [representedObject hasPrefix:@"assignee:"] || [representedObject hasPrefix:@"mentions:"] || [representedObject hasPrefix:@"author:"];
}


- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
    if ([self.representedObjectForEditingString isEqualToString:editingString]) {
        return editingString;
    }
    
    self.representedObjectForEditingString = editingString;
    //DDLogDebug(@"STARTING ----> representedObjectForEditingString: %@", editingString);
    
    __weak QIssuesSearchViewController *weakSelf = self;
    
    [self.suggestionCoalescer executeBlock:^{
        QIssuesSearchViewController *strongSelf = weakSelf;
        NSTextView *fieldEditor = (NSTextView *)[self.view.window fieldEditor:NO forObject:self.searchField];
        if (!strongSelf || strongSelf.view.window.firstResponder != fieldEditor) {
            return;
        }
        
        NSString *adjusted = [editingString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (adjusted && adjusted.length > 0) {
            CGFloat suggestionHeight = 0.0;
            NSRect suggestionRect = NSMakeRect(0, -suggestionHeight, 260, suggestionHeight);
            NSRect frameInWindow = [strongSelf.view convertRect:suggestionRect toView:nil];
            NSRect rect = [strongSelf.view.window convertRectToScreen:frameInWindow];
            
            if (!strongSelf.suggestionWindowController) {
                strongSelf.suggestionWindowController = [[SearchSuggestionWindowController alloc] initWithWindowNibName:@"SearchSuggestionWindowController"];
                [strongSelf.suggestionWindowController.window setFrame:rect display:NO];
                [strongSelf _moveSuggestionWindowIfShowing];
                strongSelf.suggestionWindowController.window.parentWindow = strongSelf.view.window;
                strongSelf.suggestionWindowController.window.delegate = strongSelf;
                
                SearchSuggestionViewController *searchSuggestionViewController = self.suggestionWindowController.suggestionViewController;
                searchSuggestionViewController.onSuggestionClick = ^{
                    [weakSelf _updateEditingStringWithCurrentSuggestionSelection];
                };
                searchSuggestionViewController.onDataReload = ^{
                    [weakSelf _moveSuggestionWindowIfShowing];
                };
            }
            
            
            SearchSuggestionViewController *suggestionViewController = strongSelf.suggestionWindowController.suggestionViewController;
            if (suggestionViewController) {
                suggestionViewController.searchQuery = adjusted;
            }
            [strongSelf.suggestionWindowController showWindow:self];
        } else if (strongSelf.suggestionWindowController) {
            [strongSelf dismissSuggestionWindowController];
        }
    }];
    
    return editingString;
}

- (void)dismissSuggestionWindowController
{
    DDLogDebug(@"Dismissing Suggestion Window Controller");
    [self.suggestionWindowController close];
    self.suggestionWindowController = nil;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    SearchSuggestionViewController *searchSuggestionViewController = self.suggestionWindowController.suggestionViewController;
    if( commandSelector == @selector(moveUp:) ){
        [searchSuggestionViewController moveUp];
        return YES; //self.suggestionWindowController.window.contentView.hidden == false;
    }
    
    if (commandSelector == @selector(moveDown:) ){
        [searchSuggestionViewController moveDown];
        return YES; //self.suggestionWindowController.window.contentView.hidden == false;
    }
    
    if (commandSelector == @selector(insertNewline:) && searchSuggestionViewController) {
        BOOL handled = [self _updateEditingStringWithCurrentSuggestionSelection];
        
        if (!handled) {
            [self dismissSuggestionWindowController];
        }
        
        return handled;
    }
    
    return NO;
}

- (BOOL)_updateEditingStringWithCurrentSuggestionSelection
{
    SearchSuggestionViewController *searchSuggestionViewController = self.suggestionWindowController.suggestionViewController;
    SRSearchSuggestionResultItemValue *resultSelection = [searchSuggestionViewController currentSearchResultSelection];
    if (resultSelection) {
        NSString *suggestSearchQuery = [self.suggestionWindowController.suggestionViewController searchQuery];
        [self dismissSuggestionWindowController];
        
        NSMutableArray *objects = [self.searchField.objectValue mutableCopy];
        __block NSUInteger indexOfEditingObject = NSNotFound;
        [objects enumerateObjectsUsingBlock:^(NSString  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self.representedObjectForEditingString isEqualToString:obj]) {
                indexOfEditingObject = idx;
                *stop = YES;
            }
        }];
        
        NSString *prefix = [suggestSearchQuery.trimmedString hasPrefix:@"-"] ? @"-" : @"";
        if (indexOfEditingObject != NSNotFound) {
            switch (resultSelection.type) {
                case SRSearchSuggestionResultTypeRepository:
                    objects[indexOfEditingObject] = [NSString stringWithFormat:@"%@repo:%@", prefix, resultSelection.title];
                    break;
                    
                case SRSearchSuggestionResultTypeMilestone:
                    objects[indexOfEditingObject] = [NSString stringWithFormat:@"%@milestone:%@", prefix, resultSelection.title];
                    break;
                    
                case SRSearchSuggestionResultTypeOwner:
                    if ([self.representedObjectForEditingString hasPrefix:@"author:"] || [self.representedObjectForEditingString hasPrefix:@"-author:"]) {
                        objects[indexOfEditingObject] = [NSString stringWithFormat:@"%@author:%@", prefix, resultSelection.title];
                        
                    } else if ([self.representedObjectForEditingString hasPrefix:@"mentions:"] || [self.representedObjectForEditingString hasPrefix:@"-mentions:"]) {
                        objects[indexOfEditingObject] = [NSString stringWithFormat:@"%@mentions:%@", prefix, resultSelection.title];
                        
                    } else {
                        objects[indexOfEditingObject] = [NSString stringWithFormat:@"%@assignee:%@", prefix, resultSelection.title];
                    }
                    break;
                    
                case SRSearchSuggestionResultTypeLabel:
                    objects[indexOfEditingObject] = [NSString stringWithFormat:@"%@label:%@", prefix, resultSelection.title];
                    break;
                    
                case SRSearchSuggestionResultTypeIssueState:
                    objects[indexOfEditingObject] = [NSString stringWithFormat:@"is:%@", resultSelection.title];
                    break;
                    
                case SRSearchSuggestionResultTypeUnspecified:
                    objects[indexOfEditingObject] = [NSString stringWithFormat:@"no:%@", resultSelection.title];
                    break;
                    
                default:
                    break;
            }
            
            [self.searchField setObjectValue:objects];
            [self _fireSearch:nil];
            self.representedObjectForEditingString = nil;
        }
        
        
        return (indexOfEditingObject != NSNotFound);
    }
    
    return NO;
}

#pragma mark - Actions

- (void)_didClickShowSaveSearchDisplayPopoverNotification:(id)notification
{
    self.saveSearchButton.hidden = false;
    [self didClickSaveSearch:self.saveSearchButton];
}

- (IBAction)didClickSaveSearch:(id)sender
{
    //    [self.saveSearchButtonCoalescer executeBlock:^{
    //        self.saveSearchButton.hidden = false;
    //    }];
    //
    QIssueFilter *filter = [QIssueFilter filterWithSearchTokensArray:[self.searchField objectValue]];
    SRUserQueryNameViewController *controller = [[SRUserQueryNameViewController alloc] initWithAccount:[QContext sharedContext].currentAccount query:filter.searchTokens];
    NSSize size = NSMakeSize(278.0f, 104.0f);
    
    controller.view.frame = NSMakeRect(0, 0, size.width, size.height);
    
    NSPopover *popover = [[NSPopover alloc] init];
    
    //    if (SRThemeModeDark == [NSUserDefaults themeMode]) {
    //        NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    //        popover.appearance = appearance;
    //    } else {
    //        NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    //        popover.appearance = appearance;
    //    }
    
    controller.delegate = self;
    self.userQueryNamePopover = popover;
    
    if ([NSUserDefaults themeMode] == SRThemeModeDark) {
        NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        popover.appearance = appearance;
    } else {
        NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        popover.appearance = appearance;
    }
    
    [popover setDelegate:self];
    [popover setContentSize:size];
    [popover setContentViewController:controller];
    [popover setAnimates:YES];
    [self.view.window makeFirstResponder:self.view];
    [popover setBehavior:NSPopoverBehaviorTransient];
    [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSRectEdgeMaxY];
}

#pragma mark - SRUserQueryNameViewControllerDelegate <NSObject>

- (void)didCloseUserQueryNameViewController:(SRUserQueryNameViewController *)controller;
{
    [self _dismissUserQueryNamePopover];
}

#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)notification;
{
    [self _dismissUserQueryNamePopover];
}

- (void)_dismissUserQueryNamePopover
{
    if (self.userQueryNamePopover) {
        [self.userQueryNamePopover close];
        self.userQueryNamePopover = nil;
        //        [self.saveSearchButtonCoalescer executeBlock:^{
        //            self.saveSearchButton.hidden = true;
        //        }];
    }
}

#pragma mark - NSWindowDelegate <NSObject>
- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification;
{
    self.suggestionWindowController = nil;
}

@end
