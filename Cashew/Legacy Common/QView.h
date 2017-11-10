//
//  QView.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class QView;

@protocol QViewDelegate <NSObject>

- (void)view:(QView *)view keyUpEvent:(NSEvent *)theEvent;

@end

@interface QView : NSView

@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, weak) id<QViewDelegate> viewDelegate;
@property (nonatomic) BOOL disableThemeObserver;

@end
