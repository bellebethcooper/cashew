//
//  SRClassicModeSplitView.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRClassicModeSplitView.h"
#import "Cashew-Swift.h"

@implementation SRClassicModeSplitView

//- (void) drawRect:(NSRect)dirtyRect
//{
//    [super drawRect:dirtyRect];
//    id topView = [[self subviews] objectAtIndex:0];
//    NSRect topViewFrameRect = [topView frame];
//    [self drawDividerInRect:NSMakeRect(topViewFrameRect.origin.x, topViewFrameRect.size.height, topViewFrameRect.size.width, [self dividerThickness] )];
//}

- (NSColor *)dividerColor
{
    return [SRCashewColor separatorColor]; // NSUserDefaults.themeMode ==  SRThemeModeDark ? [SRCashewColor redColor] : [SRCashewColor greenColor];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _setup];
}

- (void)dealloc
{
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
}

- (void)_setup
{
    __weak SRClassicModeSplitView *weakSelf = self;
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        SRClassicModeSplitView *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
//        strongSelf.dividerStyle = NSSplitViewDividerStyleThin;
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            
//            strongSelf.dividerStyle = NSSplitViewDividerStylePaneSplitter;
//            
//                    [strongSelf setNeedsDisplay:YES];
//                    [strongSelf setNeedsLayout:YES];
//        });
//        

        
    }];
}

//-(void) drawDividerInRect:(NSRect)aRect
//{
//    [[SRCashewColor separatorColor] set];
//    NSRectFill(aRect);
//}

@end
