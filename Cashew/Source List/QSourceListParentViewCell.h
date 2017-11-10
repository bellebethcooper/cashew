//
//  QBasicHeaderSourceListViewCell.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QView.h"
#import "QSourceListNode.h"

@class QSourceListParentViewCell;

@protocol QBasicHeaderSourceListViewCellDelegate <NSObject>

- (void)headerSourceListViewCell:(QSourceListParentViewCell *)cell didExpand:(BOOL)expand;
//- (void)headerSourceListViewCell:(QSourceListParentViewCell *)cell didDeleteObjectValue:(NSObject *)objectValue;

@end

@interface QSourceListParentViewCell : QView

@property (nonatomic, weak) id<QBasicHeaderSourceListViewCellDelegate> delegate;
@property (nonatomic) NSString *stringValue;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic) QSourceListNode *node;
@property (nonatomic, assign) BOOL hideMenuButton;
@property (nonatomic, assign) BOOL hideBottomLine;

@end
