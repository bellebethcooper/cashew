//
//  QRepositoriesDataSource.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QAccount.h"
#import "Cashew-Swift.h"
#import "QSourceListNode.h"

@class QSourceListDataSource;

typedef void (^QRepositiesFetchDataCompletion)(NSError *error);

@protocol QSourceListDataSourceDelegate <NSObject>

- (void)sourceListDataSource:(QSourceListDataSource *)dataSource didInsertNode:(QSourceListNode *)node atIndex:(NSUInteger)index;
- (void)sourceListDataSource:(QSourceListDataSource *)dataSource didRemoveNode:(QSourceListNode *)node atIndex:(NSUInteger)index;
- (void)sourceListDataSource:(QSourceListDataSource *)dataSource didUpdateNode:(QSourceListNode *)node;
- (void)reloadTableUsingSourceListDataSource:(QSourceListDataSource *)dataSource;
@end

@interface QSourceListDataSource : NSObject

+ (instancetype)dataSource;

@property (nonatomic, readonly) QAccount *account;
@property (nonatomic, weak) id<QSourceListDataSourceDelegate> delegate;

- (void)fetchItemsForAccount:(QAccount *)account onCompletion:(QRepositiesFetchDataCompletion)completion;
- (void)filterNodesUsingText:(NSString *)filterText onCompletion:(QRepositiesFetchDataCompletion)completion;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (QSourceListNode *)childNodeAtIndex:(NSInteger)row forItem:(QSourceListNode *)node;
- (QSourceListNode *)notificationNode;
- (QSourceListNode *)favoritesNode;

@end
