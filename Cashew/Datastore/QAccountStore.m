//
//  QAccountStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QAccountStore.h"
#import "QContext.h"
#import "QUserQueryStore.h"
#import "Cashew-Swift.h"

@implementation QAccountStore

+ (void)saveAccount:(QAccount *)account;
{
    NSParameterAssert(account);
    NSParameterAssert(account.username);
    NSParameterAssert(account.baseURL);
    NSParameterAssert(account.accountName);
    
    __block BOOL didCreateAccount = false;
    
    [QAccountStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM account WHERE (login = ? OR user_id = ?) AND base_url = ?", account.username, account.userId, account.baseURL];
        
        if ([rs next]) {
            
            if (![rs columnIsNull:@"identifier"]) {
                NSString *cacheKey = [SRAccountCache AccountCacheKeyForAccountId:@([rs intForColumn:@"identifier"])];
                [[SRAccountCache sharedCache] removeObjectForKey:cacheKey];
            }
            
            BOOL success = [db executeUpdate:@"UPDATE account SET account_name = ? WHERE login = ? AND base_url = ?", account.accountName, account.username, account.baseURL];
            NSParameterAssert(success);
        } else {
            BOOL success = [db executeUpdate:@"INSERT INTO account (account_name, login, base_url, user_id) VALUES (?, ?, ?, ?)", account.accountName, account.username, account.baseURL, account.userId];
            NSParameterAssert(success);
            didCreateAccount = true;
        }
        
        [rs close];
    }];
    
    if (didCreateAccount) {
        [QAccountStore notifyInsertObserversForStore:QAccount.class record:account];
    }
}

+ (BOOL)isDeletedAccount:(QAccount *)account;
{
    __block BOOL isDeleted = false;
    
    [QRepositoryStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * from account WHERE identifier = ?", account.identifier];
        isDeleted = ![rs next];
        [rs close];
    }];
    
    return isDeleted;
}


+ (QAccount *)accountForIdentifier:(NSNumber *)identifier
{
    NSParameterAssert(identifier);
    
    NSString *cacheKey = [SRAccountCache AccountCacheKeyForAccountId:identifier];
    QAccount *account = [[SRAccountCache sharedCache] fetch:cacheKey fetcher:^QAccount *{
        __block QAccount *account = nil;
        [QAccountStore doReadInTransaction:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM account WHERE identifier = ?", identifier];
            
            if ([rs next]) {
                account = [QAccountStore _accountFromResultSet:rs];
            }
            
            [rs close];
        }];
        return account;
    }];
    
    return account;
}

+ (QAccount *)accountForUserId:(NSNumber *)userId baseURL:(NSURL *)baseURL;
{
    NSParameterAssert(userId);
    NSParameterAssert(baseURL);
    __block QAccount *account = nil;
    [QAccountStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM account WHERE user_id = ? AND base_url = ?", userId, baseURL.absoluteString];
        
        if ([rs next]) {
            account = [QAccountStore _accountFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    return account;
}

+ (void)deleteAccount:(QAccount *)account;
{    
    NSString *cacheKey = [SRAccountCache AccountCacheKeyForAccountId:account.identifier];
    [[SRAccountCache sharedCache] removeObjectForKey:cacheKey];
    
    [QAccountStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        if (![db executeUpdate:@"DELETE FROM account WHERE identifier = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        if (![db executeUpdate:@"DELETE FROM issue WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_comment WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_event WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_search WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM label WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM label_search WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM milestone WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM milestone_search WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM owner WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM owner_search WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM repository WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM repository_assignee WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM user_search_query WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM repository_search WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_label WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }

        
        if (![db executeUpdate:@"DELETE FROM issue_comment_draft WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_notification WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_favorite WHERE account_id = ?", account.identifier]) {
            *rollback = YES;
            return;
        }
    }];
    
    [QAccountStore notifyDeletionObserversForStore:QAccount.class record:account];
}


+ (NSArray<QAccount *> *)accounts;
{
    NSMutableArray *accounts = [NSMutableArray new];
    [QAccountStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM account"];
        
        while (rs.next) {
            QAccount *account = [QAccountStore _accountFromResultSet:rs];
            
            [accounts addObject:account];
        }
        
        [rs close];
    }];
    return accounts;
}

#pragma mark - Adaptors
+ (QAccount *)_accountFromResultSet:(FMResultSet *)rs
{
    QAccount *account = [QAccount new];
    
    
    account.username = [rs stringForColumn:@"login"];
    account.userId = @([rs intForColumn:@"user_id"]);
    account.baseURL = [NSURL URLWithString:[rs stringForColumn:@"base_url"]];
    account.accountName = [rs stringForColumn:@"account_name"];
    account.identifier = @([rs intForColumn:@"identifier"]);
    account.authToken = [[QContext sharedContext] authTokenForLogin:account.username];
    
    return account;
}


@end
