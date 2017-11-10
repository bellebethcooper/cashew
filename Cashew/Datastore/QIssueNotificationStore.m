//
//  QIssueNotificationStore.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/20/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "QIssueNotificationStore.h"
#import "Cashew-Swift.h"
#import "QIssue.h"
#import "QIssueStore.h"
#import "QRepository.h"
#import "QRepositoryStore.h"
#import "QLabelStore.h"

@implementation QIssueNotificationStore

+ (NSInteger)totalUnreadIssueNotificationsForAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    __block NSInteger total = 0;
    [QIssueCommentDraftStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(*) FROM issue_notification issn INNER JOIN issue i ON i.account_id = issn.account_id AND i.repository_id = issn.repository_id AND i.number = issn.issue_number WHERE issn.read = 0 AND i.account_id = ?", accountId];
        if ([rs next]) {
            total = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return total;
}

// account_id integer NOT NULL, repository_id integer NOT NULL, issue_number integer NOT NULL, thread_id integer NOT NULL, reason text NOT NULL, read integer NOT NULL DEFAULT(0), updated_at timestamp NOT NULL, search_uniq_key varchar NOT NULL
+ (void)saveIssueNotificationWithAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber threadId:(NSNumber *)threadId reason:(NSString *)reason read:(BOOL)read updatedAt:(NSDate *)updatedAt
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueNumber);
    NSParameterAssert(threadId);
    NSParameterAssert(reason);
    NSParameterAssert(updatedAt);
    
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    
    [QIssueNotificationStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_notification WHERE account_id = ? AND thread_id = ? AND repository_id = ?",
                           accountId, threadId, repositoryId];
        
        if ([rs next]) {
            
            NSDate *currentDate = [rs dateForColumn:@"updated_at"];
            NSString *aReason = [rs stringForColumn:@"reason"];
            
            if ([updatedAt compare:currentDate] == NSOrderedSame && [aReason isEqualToString:reason] && [rs boolForColumn:@"read"] == read) {
                [rs close];
                return;
            }
            
            BOOL success = [db executeUpdate:@"UPDATE issue_notification SET read = ?, reason = ?, updated_at = ? WHERE account_id = ? AND thread_id = ? AND repository_id = ?",
                            @(read), reason, updatedAt, accountId, threadId, repositoryId];
            
            NSParameterAssert(success);
            
            dbOperation = QBaseDatabaseOperation_Update;
            
        } else {
            NSString *uniqKey = [NSString stringWithFormat:@"%@_%@_%@", accountId, repositoryId, issueNumber];
            BOOL success = [db executeUpdate:@"INSERT INTO issue_notification (account_id, thread_id, repository_id, reason, read, updated_at, issue_number, search_uniq_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                            accountId, threadId, repositoryId, reason, @(read), updatedAt, issueNumber, uniqKey];
            
            NSParameterAssert(success);
            
            dbOperation = QBaseDatabaseOperation_Insert;
        }
        
        [rs close];
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        QIssue *issueNotification  = [QIssueNotificationStore issueWithNotificationForAccountId:accountId repositoryId:repositoryId issueNumber:issueNumber];
        if (issueNotification) {
            [QIssueNotificationStore notifyInsertObserversForStore:QIssueNotificationStore.class record:issueNotification];
        }
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        QIssue *issueNotification  = [QIssueNotificationStore issueWithNotificationForAccountId:accountId repositoryId:repositoryId issueNumber:issueNumber];
        if (issueNotification) {
            [QIssueNotificationStore notifyUpdateObserversForStore:QIssueNotificationStore.class record:issueNotification];
        }
    }
}

+ (QIssue *)issueWithNotificationForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueNumber);
    
    QRepository *repository = [QRepositoryStore repositoryForAccountId:accountId identifier:repositoryId];
    QIssue *issue = repository ? [QIssueStore issueWithNumber:issueNumber forRepository:repository] : nil;
    
    if (!issue) {
        return nil;
    }
    
    __block NSNumber *threadId = nil;
    __block NSString *reason = nil;
    __block NSDate *updatedAt = nil;
    __block BOOL read = false;
    
    __block BOOL found = false;
    [QIssueNotificationStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT reason, read, updated_at, thread_id FROM issue_notification WHERE account_id = ? AND repository_id = ? AND issue_number = ?", accountId, repositoryId, issueNumber];
        
        if ([rs next]) {
            found = true;
            updatedAt = [rs dateForColumn:@"updated_at"];
            threadId = @([rs intForColumn:@"thread_id"]);
            reason = [rs stringForColumn:@"reason"];
            read = [rs boolForColumn:@"read"];
        }
        [rs close];
    }];
    
    if (!found) {
        return nil;
    }
    
    SRIssueNotification *notification = [[SRIssueNotification alloc] initWithThreadId:threadId read:read reason:reason updatedAt:updatedAt];
    issue.notification = notification;
    
    //[QLabelStore populateLabelsForIssues:@[issue]];
    return issue;
}

+ (NSDate *)notificationModifiedOnForAccountId:(NSNumber *)accountId
{
    NSParameterAssert(accountId);
    __block NSDate *currentDate = nil;
    [QIssueNotificationStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT notification_modified_on FROM account WHERE identifier = ?", accountId];
        
        if ([rs next]) {
            currentDate = [rs dateForColumn:@"notification_modified_on"];
        }
        [rs close];
    }];
    
    return currentDate;
}

+ (void)resetNotificationModifiedOnForAccountId:(NSNumber *)accountId
{
    NSParameterAssert(accountId);
    [QIssueNotificationStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"UPDATE account SET notification_modified_on = null WHERE identifier = ?", accountId];
        NSParameterAssert(success);
    }];
}

+ (void)saveNotificationModifiedOnDate:(NSDate *)modifiedOn forAccountId:(NSNumber *)accountId
{
    NSParameterAssert(modifiedOn);
    NSParameterAssert(accountId);
    [QIssueNotificationStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"UPDATE account SET notification_modified_on = ? WHERE identifier = ?", modifiedOn, accountId];
        NSParameterAssert(success);
    }];
}

@end
