//
//  QrepositoriesViewController.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QRepository.h"
#import "QIssueFilter.h"
#import "QSourceListNode.h"


@class QSourceListViewController;

@protocol QSourceListViewControllerDelegate <NSObject>

- (void)didClickAddLabelInSourceListViewController:(QSourceListViewController *)controller;
- (void)didClickAddAccountInSourceListViewController:(QSourceListViewController *)controller;
- (void)didClickAddRepositoryInSourceListViewController:(QSourceListViewController *)controller;
- (void)sourceListViewController:(QSourceListViewController *)controller keyUp:(NSEvent *)theEvent;

@end

@interface QSourceListViewController : NSViewController

@property (nonatomic, weak) id<QSourceListViewControllerDelegate> delegate;
@property (nonatomic) QSourceListNode *node;

//- (void)reloadDataOnCompletion:(dispatch_block_t)onCompletion;
- (void)focus;
- (void)showNotification;
- (void)showFavorites;

@end
