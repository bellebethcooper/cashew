//
//  QRepositoryTableViewCell.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QView.h"
#import "QSourceListNode.h"

@class QSourceListChildViewCell;

@protocol QSourceListChildViewCellDelegate <NSObject>

- (void)didSelectSourceListChildViewCell:(QSourceListChildViewCell *)cell;
- (void)didConfirmDeleteSourceListChildViewCell:(QSourceListChildViewCell *)cell;
- (void)didClickRenameInSourceListChildViewCell:(QSourceListChildViewCell *)cell;
- (void)childSourceListViewCell:(QSourceListChildViewCell *)cell didExpand:(BOOL)expand;
- (void)didConfirmCloseMilestoneInSourceListChildViewCell:(QSourceListChildViewCell *)cell;

@end

@interface QSourceListChildViewCell : QView

@property (nonatomic, assign) NSInteger countValue;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic) QSourceListNode *node;
@property (nonatomic, weak) id<QSourceListChildViewCellDelegate> sourceListChildDelegate;
//@property (nonatomic) NSUInteger level;

@end
