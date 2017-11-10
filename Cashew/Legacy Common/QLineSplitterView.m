//
//  QLineSplitterView.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QLineSplitterView.h"


@implementation QLineSplitterView {
    NSTrackingArea *_trackingArea;
    BOOL _mouseIsDown;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _setupLineSplitter];
}

- (BOOL)mouseDownCanMoveWindow
{
    return false;
}


- (void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    [[NSCursor resizeLeftRightCursor] set];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    // [super mouseExited:theEvent];
    if (!_mouseIsDown) {
        [[NSCursor arrowCursor] set];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    //[super mouseDown:theEvent];
    _mouseIsDown = YES;
    [[NSCursor resizeLeftRightCursor] set];
    [[self window] disableCursorRects];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    //[super mouseUp:theEvent];
    _mouseIsDown = NO;
    [[NSCursor arrowCursor] set];
    [[self window] enableCursorRects];
}

- (void)cursorUpdate:(NSEvent *)event
{
    //[[NSCursor resizeLeftRightCursor] set];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    //[super mouseDragged:theEvent];
    [[NSCursor resizeLeftRightCursor] set];
    //DDLogDebug(@"dragged %@", NSStringFromPoint(theEvent.locationInWindow));
    [_delegate lineSplitterView:self didMoveToPoint:theEvent.locationInWindow];
}

-(void)updateTrackingAreas
{
    if(_trackingArea != nil) {
        [self removeTrackingArea:_trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways);
    _trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                  options:opts
                                                    owner:self
                                                 userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [self updateTrackingAreas];
}



- (void)_setupLineSplitter
{
    self.disableThemeObserver = true;
    [self setBackgroundColor:[NSColor clearColor]];
}


@end
