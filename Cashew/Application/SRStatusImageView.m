//
//  SRStatusImageView.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/24/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRStatusImageView.h"
#import "Cashew-Swift.h"

@interface SRStatusImageView ()
@end

@implementation SRStatusImageView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
        self.wantsLayer = true;
        self.image = [self _statusBarIcon];
    }
    return self;
}



- (void)setShowNotificationDot:(BOOL)showNotificationDot
{
    _showNotificationDot = showNotificationDot;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (self.showNotificationDot) {
        static CGFloat edge = 6.0;
        NSBezierPath *path = [NSBezierPath bezierPath];
        CGFloat y = 2; //CGRectGetHeight(self.bounds) / 2.0 - edge / 2.0;
        NSRect rectangle = NSMakeRect(CGRectGetWidth(self.bounds) - edge, y, edge, edge);
        [path appendBezierPathWithOvalInRect:rectangle];
        [[SRCashewColor notificationDotColor] setFill];
        [path fill];
    }
}

- (NSImage *)_statusBarIcon
{
    NSImage *img = [NSImage imageNamed:@"status_bar_icon"];
    img.template = true;
    img.size = NSMakeSize(20, 20);
    //imgView.image = img;
    return img;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSMenu *menu = [super menu];
    [self.statusItem popUpStatusItemMenu:menu];
    [NSApp sendAction:self.action to:self.target from:self];
    //self.layer.backgroundColor = NSColor.blueColor.CGColor;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    //    self.layer.borderColor = NSColor.greenColor.CGColor;
    //    self.layer.borderWidth = 1;
    self.layer.backgroundColor = NSColor.blueColor.CGColor;
    return NSDragOperationCopy;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    // self.layer.borderWidth = 0;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
    self.image = [self _statusBarIcon];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    if ([pasteboard.types containsObject:NSFilenamesPboardType]) {
        NSArray<NSString *> *paths = [[sender draggingPasteboard] propertyListForType:@"NSFilenamesPboardType"];
        
        if (paths && paths.count > 0) {
            [self.statusImageImageViewDelegate statusItemImageView:self didPastePaths:paths];
        }
    }
    
    return YES;
}

@end
