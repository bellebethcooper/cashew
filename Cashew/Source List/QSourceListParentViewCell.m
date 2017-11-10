//
//  QBasicHeaderSourceListViewCell.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QSourceListParentViewCell.h"

@interface QSourceListParentViewCell ()
@property (weak) IBOutlet NSTextField *headerLabel;
@property (weak) IBOutlet NSButton *toggleButton;
@property (weak) IBOutlet NSButton *menuButton;
@property (weak) IBOutlet QView *bottomLineView;

@end

@implementation QSourceListParentViewCell {
    NSTrackingArea *_trackingArea;
}




- (void)awakeFromNib
{
    [_bottomLineView setBackgroundColor:[NSColor colorWithWhite:209/255. alpha:1]];
    
    [self _setToggleButtonTitle:@"Show"];
    [self.toggleButton setHidden:YES];
    [self.headerLabel setFont:[NSFont boldSystemFontOfSize:10]];
    
    __weak QSourceListParentViewCell *weakSelf = self;
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        QSourceListParentViewCell *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        id<SRThemeColor> color = nil;
        
        if (mode == SRThemeModeLight) {
            color = [SRLightModeColor sharedInstance];
        } else if (mode == SRThemeModeDark) {
            color = [SRDarkModeColor sharedInstance];
        }
        
        if (color) {
            [strongSelf setBackgroundColor:[NSColor clearColor]]; //[color backgroundColor]];
            [strongSelf.headerLabel setTextColor:[color foregroundSecondaryColor]];
            
            NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[strongSelf.menuButton attributedTitle]];
            NSRange titleRange = NSMakeRange(0, [colorTitle length]);
            [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
            [strongSelf.menuButton setAttributedTitle:colorTitle];
            [strongSelf.menuButton setHidden:YES];
        }
    }];
    
}

- (void)setHideBottomLine:(BOOL)hideBottomLine
{
    _hideBottomLine = hideBottomLine;
    [_bottomLineView setHidden:hideBottomLine];
}

- (IBAction)didClickMenuButton:(id)sender {
    
    SRMenu *menu = [[SRMenu alloc] init];
    
    NSMenuItem *deleteMenuItem = [[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(a_deleteAccount:) keyEquivalent:@""];
    [menu addItem:deleteMenuItem];
    
    NSMenuItem *renameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Rename" action:@selector(a_renameAccount:) keyEquivalent:@""];
    [menu addItem:renameMenuItem];
    
    [SRMenu popUpContextMenu:menu withEvent:[NSApp  currentEvent] forView:_toggleButton];
}

- (void)a_deleteAccount:(id)sender
{
    DDLogDebug(@"did delete account");
    //  [_delegate headerSourceListViewCell:self didDeleteObjectValue:_node];
}

- (void)a_renameAccount:(id)sender
{
    DDLogDebug(@"did rename account");
}

- (void)setSelected:(BOOL)selected
{
    NSParameterAssert(self.node);
    if (_selected != selected) {
        _selected = selected;
        
        if (selected) {
            [self setBackgroundColor:[NSColor colorWithWhite:239/255. alpha:1]];
        } else {
            [self setBackgroundColor:[NSColor clearColor]];
        }
    }
}

- (void)setStringValue:(NSString *)stringValue
{
    if ([_stringValue isEqualToString:stringValue] == NO) {
        _stringValue = stringValue;
        [_headerLabel setStringValue:[stringValue uppercaseString]];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [_toggleButton setHidden:NO];
    if (_hideMenuButton) {
        [_menuButton setHidden:NO];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [_toggleButton setHidden:YES];
    [_menuButton setHidden:YES];
}

-(void)updateTrackingAreas
{
    if(_trackingArea != nil) {
        [self removeTrackingArea:_trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways);
    _trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds] options:opts owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)_setToggleButtonTitle:(NSString *)title
{
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithString:title];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithWhite:159/255. alpha:1] range:titleRange];
    [colorTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:10] range:titleRange];
    [_toggleButton setAttributedTitle:colorTitle];
}

- (IBAction)didClickToggleButton:(id)sender
{
    if ([sender isKindOfClass:NSClickGestureRecognizer.class]) {
        NSClickGestureRecognizer *recognizer = (NSClickGestureRecognizer *)sender;
        
        recognizer.numberOfClicksRequired = 1;
        if ([recognizer.view isKindOfClass:NSButton.class]) {
            
        }
    } else {
        [self _toggleExpandState];
    }
}

- (void)setExpanded:(BOOL)expanded
{
    NSParameterAssert(self.node);
    if (_expanded != expanded) {
        _expanded = expanded;
        if (_expanded) {
            [self _setToggleButtonTitle:@"Hide"];
        } else {
            [self _setToggleButtonTitle:@"Show"];
        }
    }
}

- (void)_toggleExpandState
{
    if (_expanded) {
        [_delegate headerSourceListViewCell:self didExpand:NO];
        [self setExpanded:NO];
    } else {
        [_delegate headerSourceListViewCell:self didExpand:YES];
        [self setExpanded:YES];
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [self updateTrackingAreas];
}


@end
