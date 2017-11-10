//
//  QLineSplitterView.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QView.h"

@class QLineSplitterView;
@protocol QLineSplitterViewDelegate <NSObject>

- (void)lineSplitterView:(QLineSplitterView *)lineSplitterView didMoveToPoint:(NSPoint)point;

@end

@interface QLineSplitterView : QView
@property (nonatomic, weak) id<QLineSplitterViewDelegate> delegate;
@end
