//
//  QUserQueryStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/31/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"


@class QUserQuery;
@class QAccount;

@interface QUserQueryStore : QBaseStore

//+ (void)saveSourceListSnapShot:(NSArray<QUserQuery *> *)snapshot forAccountId:(NSNumber *)accountID onCompletion:(dispatch_block_t)onCompletion;
+ (NSMutableArray<QUserQuery *> *)fetchUserQueriesForAccount:(QAccount *)account;
+ (void)saveUserQueryWithQuery:(NSString *)query account:(QAccount *)account name:(NSString *)name externalId:(NSString *)externalId updatedAt:(NSDate *)updatedAt;
+ (void)deleteUserQuery:(NSObject *)userQuery;
+ (void)renameUserQuery:(QUserQuery *)userQuery toDisplayName:(NSString *)displayName;
+ (NSObject *)fetchUserQueryForAccount:(QAccount *)account name:(NSString *)name;

@end
