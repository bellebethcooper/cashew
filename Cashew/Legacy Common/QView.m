//
//  QView.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QView.h"
#import "Cashew-Swift.h"

@implementation QView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)dealloc
{
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)keyUp:(NSEvent *)theEvent
{
    if (_viewDelegate) {
        [_viewDelegate view:self keyUpEvent:theEvent];
    } else {
        [super keyUp:theEvent];
    }
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self.layer setBackgroundColor:_backgroundColor.CGColor];
        [CATransaction commit];
    }
}

- (BOOL)mouseDownCanMoveWindow
{
    return true;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _setup];
}


- (void)setDisableThemeObserver:(BOOL)disableThemeObserver
{
    _disableThemeObserver = disableThemeObserver;
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
}

#pragma mark - General Setup
- (void)_setup {
    [self setWantsLayer:YES];
    self.canDrawConcurrently = true;
    
    
    __weak QView *weakSelf = self;
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        QView *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (strongSelf.disableThemeObserver) {
            [[SRThemeObserverController sharedInstance] removeThemeObserver:strongSelf];
            return;
        }
        if (mode == SRThemeModeLight) {
            [strongSelf setBackgroundColor:[SRLightModeColor.sharedInstance backgroundColor]];
        } else if (mode == SRThemeModeDark) {
            [strongSelf setBackgroundColor:[SRDarkModeColor.sharedInstance backgroundColor]];
        }
    }];
}

@end
