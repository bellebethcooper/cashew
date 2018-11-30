//
//  QRepositoryTableViewCell.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QSourceListChildViewCell.h"
#import "NSImage+Common.h"
#import "QUserQueryStore.h"
#import "Cashew-Swift.h"

@interface _QSourceListChildTextField : NSTextField
//@property (nonatomic) BOOL shouldAllowVibrancy;
@end

@implementation _QSourceListChildTextField

- (BOOL)allowsVibrancy
{
    return true;
}

@end

@interface _QSourceListImageView : NSImageView

@end

@implementation _QSourceListImageView

- (BOOL)allowsVibrancy
{
    return true;
}

@end

@interface QSourceListChildViewCell ()<NSTextFieldDelegate>
@property (nonatomic) NSString *imageNamed;
//@property (nonatomic) NSImageView *expanderImageView;
@property (nonatomic) NSLayoutConstraint *imageViewCenterYConstraint;
@property (nonatomic) NSLayoutConstraint *imageViewLeftConstraint;
@property (nonatomic) _QSourceListChildTextField *label;
//@property (nonatomic) BOOL shouldAllowVibrancy;
@property (nonatomic) _QSourceListChildTextField *countLabel;
@property (nonatomic) _QSourceListImageView *imageView;
@end

@implementation QSourceListChildViewCell

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupCell];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _setupCell];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _setupCell];
    }
    return self;
}

- (BOOL)allowsVibrancy
{
    return true;
}



- (void)_setupCell
{
    [self _setupImageView];
    [self _setupLabel];
    
    __weak QSourceListChildViewCell *weakSelf = self;
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        QSourceListChildViewCell *strongSelf = weakSelf;
        if (!strongSelf || strongSelf.node == nil) {
            return;
        }
        strongSelf.selected = strongSelf.selected;
        [strongSelf setImageNamed:strongSelf.imageNamed];
        [strongSelf setExpanded:self.expanded];
//        if (mode == SRThemeModeDark) {
//            strongSelf.label.shouldAllowVibrancy = false;
//            strongSelf.countLabel.shouldAllowVibrancy = false;
//            strongSelf.shouldAllowVibrancy = false;
//        } else {
//            strongSelf.label.shouldAllowVibrancy = true;
//            strongSelf.countLabel.shouldAllowVibrancy = true;
//            strongSelf.shouldAllowVibrancy = true;
//        }
//        if (mode == SRThemeModeDark) {
//            strongSelf.label.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
//        } else {
//            strongSelf.label.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
//        }
    }];
    
}

- (void)dealloc
{
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
}

- (void)setStringValue:(NSString *)stringValue
{
    [_label setStringValue:stringValue];
}



- (void)setSelected:(BOOL)selected
{
    NSParameterAssert(self.node);
    _selected = selected;
    
    if (selected) {
        [self setBackgroundColor:[SRCashewColor currentLineBackgroundColor]];
    } else {
        [self setBackgroundColor:[NSColor clearColor]];
    }
    
    [_label setTextColor: [SRCashewColor foregroundSecondaryColor]];
}

- (void)setNode:(QSourceListNode *)node
{
    _node = node;
    
    NSString *imageName = nil;
    
    switch (node.nodeType) {
        case QSourceListNodeType_Repository:
            _countLabel.hidden = true;
            imageName = @"repo";
            break;
            
        case QSourceListNodeType_AssignedToMe:
            _countLabel.hidden = true;
            imageName = @"assigned_to_me";
            break;
            
        case QSourceListNodeType_ReportedByMe:
            _countLabel.hidden = true;
            imageName = @"reported_by_me";
            break;
            
        case QSourceListNodeType_MentionsMe:
            _countLabel.hidden = true;
            imageName = @"mentions";
            break;
            
        case QSourceListNodeType_CustomFilter:
            _countLabel.hidden = true;
            imageName = @"custom_search";
            break;
            
        case QSourceListNodeType_Milestone:
            _countLabel.hidden = true;
            imageName = @"milestone";
            break;
            
        case QSourceListNodeType_Notifications:
            _countLabel.hidden = false;
            imageName = @"notifications";
            break;
            
        case QSourceListNodeType_Drafts:
            _countLabel.hidden = false;
            imageName = @"drafts";
            break;
            
        case QSourceListNodeType_Favorites:
            _countLabel.hidden = false;
            imageName = @"unfilled_star";
            break;
            
        case QSourceListNodeType_All:
            _countLabel.hidden = false;
            imageName = @"issue-opened";
            break;
            
        default:
            break;
    }
    
    
    [self setImageNamed:imageName];
    [self setStringValue:node.title];
}

- (void)setCountValue:(NSInteger)countValue
{
    _countValue = countValue;
    if (countValue == 0) {
        _countLabel.stringValue = @"";
    } else {
        _countLabel.stringValue = [NSString stringWithFormat:@"%ld", countValue];
    }
}

- (void)setExpanded:(BOOL)expanded
{
    _expanded = expanded;
    
    NSImage *img = nil;
    if (expanded) {
        img = [[NSImage imageNamed:@"collapser"] imageWithTintColor:SRCashewColor.foregroundColor];
    } else {
        img = [[NSImage imageNamed:@"expander"] imageWithTintColor:SRCashewColor.foregroundColor];
    }
}

#pragma mark - General Setup

- (void)_setupImageView
{
    if (_imageView) {
        return;
    }
    
    _imageView = [[_QSourceListImageView alloc] init];
    [_imageView setWantsLayer:YES];
    [_imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:_imageView];
    
    [_imageView setImageAlignment:NSImageAlignCenter];
    [_imageView setImageScaling:NSImageScaleProportionallyDown];
    
    self.imageViewLeftConstraint = [_imageView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:2];
    self.imageViewLeftConstraint.active = YES;
    self.imageViewCenterYConstraint = [_imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
    self.imageViewCenterYConstraint.active = true;
    static CGFloat edge = 16;
    [_imageView.heightAnchor constraintEqualToConstant:edge].active = true;
    [_imageView.widthAnchor constraintEqualToConstant:edge].active = true;
    
//    _imageView.layer.borderWidth = 1;
//    _imageView.layer.borderColor = NSColor.redColor.CGColor;
//
//    self.layer.borderWidth = 1;
//    self.layer.borderColor = NSColor.greenColor.CGColor;
}

- (void)didClickExpander
{
    [self.sourceListChildDelegate childSourceListViewCell:self didExpand:!self.expanded];
}

- (void)setImageNamed:(NSString *)imageNamed
{
    _imageNamed = imageNamed;
    
    if ([@"repo" isEqualToString:imageNamed]) {
        self.imageViewCenterYConstraint.constant = 1;
    } else {
        self.imageViewCenterYConstraint.constant = 0;
    }
    
    NSImage *img = [NSImage imageNamed:_imageNamed];
    
    
    SRThemeMode mode = [NSUserDefaults themeMode];
    if (mode == SRThemeModeDark) {
        img = [img imageWithTintColor:[SRDarkModeColor.sharedInstance foregroundColor]];
    } else {
        img = [img imageWithTintColor:[SRLightModeColor.sharedInstance foregroundColor]];
    }
    
    if ([@"notifications" isEqualToString:_imageNamed] || [@"drafts" isEqualToString:_imageNamed]) {
        img.size = NSMakeSize(12, 12);
    }
    
    [_imageView setImage:img];
}

- (void)layout
{
    [super layout];
}

- (void)_setupLabel
{
    if (_label) {
        return;
    }
    _QSourceListChildTextField *nameLabel = [[_QSourceListChildTextField alloc] init];
    _QSourceListChildTextField *countLabel = [[_QSourceListChildTextField alloc] init];
    
    [@[nameLabel, countLabel] enumerateObjectsUsingBlock:^(NSTextField *label, NSUInteger idx, BOOL * _Nonnull stop) {
        [label setEditable:NO];
        [label setBezeled:NO];
        [label setDrawsBackground:NO];
        [label setSelectable:NO];
        [label.cell setUsesSingleLineMode:YES];
        [label.cell setLineBreakMode:NSLineBreakByTruncatingTail];
        [label setTranslatesAutoresizingMaskIntoConstraints:NO];
        [label setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
        [label setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
        
        [self addSubview:label];
    }];
    
    
    [countLabel setFont:[NSFont boldSystemFontOfSize:countLabel.font.pointSize]];
    [countLabel setTextColor:[NSColor colorWithWhite:122/255. alpha:1]];
    [countLabel setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [countLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [countLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-10].active = YES;
    [countLabel.leftAnchor constraintEqualToAnchor:nameLabel.rightAnchor].active = YES;
    [countLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
    
    [nameLabel.leftAnchor constraintEqualToAnchor:_imageView.rightAnchor constant:2].active = YES;
    [nameLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0].active = YES;
    
    _countLabel = countLabel;
    _label = nameLabel;
    [_label setFont:[NSFont systemFontOfSize:13]];
    
}

#pragma mark - mouse handling
- (void)rightMouseDown:(NSEvent *)theEvent
{
    //    [super rightMouseDown:theEvent];
    NSParameterAssert(_sourceListChildDelegate);
    
    if (self.node.nodeType == QSourceListNodeType_Notifications || self.node.nodeType == QSourceListNodeType_Drafts || self.node.nodeType == QSourceListNodeType_Favorites || self.node.nodeType == QSourceListNodeType_All) {
        return;
    }
    
    [_sourceListChildDelegate didSelectSourceListChildViewCell:self];
    SRMenu *menu = [[SRMenu alloc] init];
    
    NSMenuItem *newIssue = [[NSMenuItem alloc] initWithTitle:@"New Issue…" action:@selector(newIssue:) keyEquivalent:@""];
    [menu addItem:newIssue];
    [menu addItem:[NSMenuItem separatorItem]];
    
    if (self.node.nodeType == QSourceListNodeType_Milestone) {
        NSMenuItem *closeMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Close \"%@\"", _label.stringValue] action:@selector(_closeMilestone:) keyEquivalent:@""];
        [menu addItem:closeMenuItem];
    } else {
        NSMenuItem *deleteMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Remove \"%@\"", _label.stringValue] action:@selector(_deleteNode:) keyEquivalent:@""];
        [menu addItem:deleteMenuItem];
    }
    
    if (self.node.nodeType == QSourceListNodeType_CustomFilter) {
        NSMenuItem *renameMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Rename \"%@\"", _label.stringValue] action:@selector(_renameNode:) keyEquivalent:@""];
        [menu addItem:renameMenuItem];
    }
    //
    //    NSMenuItem *syncMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Synchronize \"%@\"", _label.stringValue] action:@selector(_syncNode:) keyEquivalent:@""];
    //    [menu addItem:syncMenuItem];
    //
    //    [menu addItem:[NSMenuItem separatorItem]];
    //
    //    NSMenuItem *markAllIssuesAsReadMenuItem = [[NSMenuItem alloc] initWithTitle:@"Mark All Issues as Read" action:@selector(_markAllIssuesAsRead:) keyEquivalent:@""];
    //    [menu addItem:markAllIssuesAsReadMenuItem];
    
    [SRMenu popUpContextMenu:menu withEvent:theEvent forView:self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (theEvent.clickCount > 1 && self.node.nodeType == QSourceListNodeType_CustomFilter) {
        [self _renameNode:nil];
    } else {
        [super mouseDown:theEvent];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (self.node.nodeType == QSourceListNodeType_Repository || self.node.nodeType == QSourceListNodeType_CustomFilter) {
        return true;
    }
    
    
    if ( self.node.nodeType == QSourceListNodeType_Milestone && [QAccount isCurrentUserCollaboratorOfRepository:[(QMilestone *)self.node.representedObject repository]]) {
        return true;
    }
    
    if (menuItem.action == @selector(newIssue:)) {
        return true;
    }
                                                                
    return false;
}

- (void)_syncNode:(id)sender
{
    
}

- (void)_markAllIssuesAsRead:(id)sender
{
    
}

- (void)_closeMilestone:(id)sender
{
    [NSAlert showWarningMessage:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", _label.stringValue] onConfirmation:^{
        [_sourceListChildDelegate didConfirmCloseMilestoneInSourceListChildViewCell:self];
    }];
}

- (void)newIssue:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kQShowCreateNewIssueNotification object:nil userInfo:@{@"issueFilter": self.node.issueFilter, @"representedObject": self.node.representedObject}];
}

- (void)_deleteNode:(id)sender
{
    [NSAlert showWarningMessage:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", _label.stringValue] onConfirmation:^{
        [_sourceListChildDelegate didConfirmDeleteSourceListChildViewCell:self];
    }];
}

- (void)_renameNode:(id)sender
{
    [self.label setTextColor:[NSColor blackColor]];
    self.label.editable = true;
    self.label.delegate = self;
    [self.window makeFirstResponder:self.label];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)notification;
{
    [self.label setTextColor:[SRCashewColor foregroundColor]];
    if (notification.object == _label && self.node.nodeType == QSourceListNodeType_CustomFilter && _label.stringValue.trimmedString.length > 0 && ![_label.stringValue isEqualToString:self.node.userQuery.displayName]) {
        [QUserQueryStore renameUserQuery:self.node.userQuery toDisplayName:_label.stringValue];
    }
    self.label.editable = false;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    if (command == @selector(cancelOperation:))  { // || (command==@selector(insertBacktab:)))
        [self.label setTextColor:[NSColor blackColor]];
        self.label.editable = true;
        [self.window makeFirstResponder:nil];
        return YES;
    }
    return NO;
}

@end
