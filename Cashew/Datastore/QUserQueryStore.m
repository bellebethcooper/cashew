//
//  QUserQueryStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/31/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QUserQueryStore.h"
#import "Cashew-Swift.h"

@implementation QUserQueryStore

+ (void)saveUserQueryWithQuery:(NSString *)query account:(QAccount *)account name:(NSString *)name externalId:(NSString *)externalId updatedAt:(NSDate *)updatedAt
{
    NSParameterAssert(query);
    NSParameterAssert(account.identifier);
    
    __block QUserQuery *record = nil;
    
    __block QUserQuery *deletedRecord = nil;
    __block QUserQuery *updatedRecord = nil;
    __block BOOL didNothing = false;
    [QUserQueryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM user_search_query WHERE display_name = ? COLLATE NOCASE AND account_id = ?", name, account.identifier];
        
        if ([rs next]) {
            if ([[rs stringForColumn:@"query"] isEqualToString:query] ) {
                [rs close];
                
                
                if ( (externalId && ![externalId isEqualToString:[rs stringForColumn:@"external_id"]]) || (updatedAt && ![updatedAt isEqualToDate:[rs dateForColumn:@"updated_at"]]) ) {
                    BOOL success = [db executeUpdate:@"update user_search_query set external_id = ?, updated_at = ? WHERE display_name = ? COLLATE NOCASE AND account_id = ?", externalId, updatedAt, name, account.identifier];
                    NSParameterAssert(success);
                }
                
                updatedRecord = [[QUserQuery alloc] initWithIdentifier:@([rs intForColumn:@"identifier"]) account:account displayName:[rs stringForColumn:@"display_name"] query:[rs stringForColumn:@"query"]];
                updatedRecord.updatedAt = updatedAt;
                updatedRecord.externalId = externalId;
                
                didNothing = true;
                return;
            }
            
            deletedRecord = [[QUserQuery alloc] initWithIdentifier:@([rs intForColumn:@"identifier"]) account:account displayName:[rs stringForColumn:@"display_name"] query:[rs stringForColumn:@"query"]];
            deletedRecord.updatedAt = [rs dateForColumn:@"updated_at"];
            deletedRecord.externalId = [rs stringForColumn:@"external_id"];
            [rs close];
            
            BOOL success = [db executeUpdate:@"DELETE FROM user_search_query WHERE identifier = ? AND account_id = ?", deletedRecord.identifier, deletedRecord.account.identifier];
            NSParameterAssert(success);
        }
        
        BOOL success = [db executeUpdate:@"INSERT INTO user_search_query (display_name, query, account_id, external_id, updated_at) VALUES (?, ?, ?, ?, ?)", name, query, account.identifier, externalId ?: (deletedRecord.externalId ?: NSNull.null), updatedAt ?: (deletedRecord.updatedAt ?: NSNull.null)];
        NSParameterAssert(success);
        
        long long int lastId = [db lastInsertRowId];
        record = [[QUserQuery alloc] initWithIdentifier:@(lastId) account:account displayName:name query:query];
    }];
    
    if (didNothing) {
        return;
    }
    
    if (updatedRecord) {
        [QUserQueryStore notifyUpdateObserversForStore:QUserQueryStore.class record:updatedAt];
    } else {
    
    if (deletedRecord) {
        [QUserQueryStore notifyDeletionObserversForStore:QUserQueryStore.class record:deletedRecord];
    }
    [QUserQueryStore notifyInsertObserversForStore:QUserQueryStore.class record:record];
    }
}

+ (void)renameUserQuery:(QUserQuery *)userQuery toDisplayName:(NSString *)displayName;
{
    NSParameterAssert(userQuery.identifier);
    NSParameterAssert(userQuery.account.identifier);
    NSParameterAssert(displayName.trimmedString.length > 0);
    
    __block QUserQuery *existingUserQuery = nil;
    [QUserQueryStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM user_search_query WHERE identifier = ? AND account_id = ?", userQuery.identifier, userQuery.account.identifier];
        if ([rs next]) {
            existingUserQuery = [[QUserQuery alloc] initWithIdentifier:@([rs intForColumn:@"identifier"]) account:userQuery.account displayName:[rs stringForColumn:@"display_name"] query:[rs stringForColumn:@"query"]];
        }
        [rs close];
    }];
    
    if (existingUserQuery) {
        if (![existingUserQuery.displayName isEqualToString:displayName]) {
            [QUserQueryStore deleteUserQuery:userQuery];
            [QUserQueryStore saveUserQueryWithQuery:userQuery.query account:userQuery.account name:displayName externalId:userQuery.externalId updatedAt:userQuery.updatedAt];
        }
    } else {
        [QUserQueryStore saveUserQueryWithQuery:userQuery.query account:userQuery.account name:userQuery.displayName externalId:userQuery.externalId updatedAt:userQuery.updatedAt];
    }
    
}

+ (void)deleteUserQuery:(NSObject *)userQueryObj;
{
    if (![userQueryObj isKindOfClass:QUserQuery.class]) {
        return;
    }
    
    QUserQuery *userQuery = (QUserQuery *)userQueryObj;
    NSParameterAssert(userQuery.identifier);
    NSParameterAssert(userQuery.account.identifier);
    
    [QUserQueryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM user_search_query WHERE identifier = ? AND account_id = ?", userQuery.identifier, userQuery.account.identifier];
        NSParameterAssert(success);
    }];
    [QUserQueryStore notifyDeletionObserversForStore:QUserQueryStore.class record:userQuery];
}

+ (NSMutableArray<QUserQuery *> *)fetchUserQueriesForAccount:(QAccount *)account // onCompletion:(QBaseStoreCompletion)onCompletion;
{
    NSParameterAssert(account);
   // NSParameterAssert(onCompletion);
    
    
    //[rs intForColumn:@"account_id"]
    // [QUserQueryStore dbDispatchAsync:^{
    
    NSMutableArray<QUserQuery *> *items = [NSMutableArray new];
    [QUserQueryStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM user_search_query WHERE account_id = ? ORDER BY display_name", account.identifier];
        while ([rs next]) {
            QUserQuery *item = [[QUserQuery alloc] initWithIdentifier:@([rs intForColumn:@"identifier"]) account:account displayName:[rs stringForColumn:@"display_name"] query:[rs stringForColumn:@"query"]];
            item.updatedAt = [rs dateForColumn:@"updated_at"];
            item.externalId = [rs stringForColumn:@"external_id"];
            [items addObject:item];
        }
        
        [rs close];
    }];
    
    return items;
}

+ (NSObject *)fetchUserQueryForAccount:(QAccount *)account name:(NSString *)name
{
    NSParameterAssert(account);
    // NSParameterAssert(onCompletion);
    
    
    //[rs intForColumn:@"account_id"]
    // [QUserQueryStore dbDispatchAsync:^{
    
    __block QUserQuery *item = nil;
    [QUserQueryStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM user_search_query WHERE account_id = ? AND display_name = ? ORDER BY display_name", account.identifier, name];
        if ([rs next]) {
            item = [[QUserQuery alloc] initWithIdentifier:@([rs intForColumn:@"identifier"]) account:account displayName:[rs stringForColumn:@"display_name"] query:[rs stringForColumn:@"query"]];
            item.updatedAt = [rs dateForColumn:@"updated_at"];
            item.externalId = [rs stringForColumn:@"external_id"];
        }
        
        [rs close];
    }];

    return item;
}

    

@end
