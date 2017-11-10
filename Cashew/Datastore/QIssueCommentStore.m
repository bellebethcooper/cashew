//
//  QIssueCommentStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueCommentStore.h"
#import "QAccountStore.h"
#import "QOwnerStore.h"
#import "QRepositoryStore.h"
#import "Cashew-Swift.h"

@interface _IssueCommentResultSetEntry : NSObject

@property (nonatomic) QIssueComment *issueComment;
@property (nonatomic) NSNumber *accountId;
@property (nonatomic) NSNumber *repositoryId;
@property (nonatomic) NSNumber *userId;

@end

@implementation _IssueCommentResultSetEntry

@end


@implementation QIssueCommentStore



+ (void)updateIssueCommentReactionCountsForIssueComment:(QIssueComment *)issueComment
{
    // should only be called after user reacts to an issue. why? cause that means we synced the reactions
    NSArray<SRIssueCommentReaction *> *reaction = [SRIssueCommentReactionStore issueCommentReactionsForIssueComment:issueComment];
    issueComment.thumbsUpCount = 0;
    issueComment.thumbsDownCount = 0;
    issueComment.laughCount = 0;
    issueComment.hoorayCount = 0;
    issueComment.confusedCount = 0;
    issueComment.heartCount = 0;
    [reaction enumerateObjectsUsingBlock:^(SRIssueCommentReaction * _Nonnull reaction, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([@"+1" isEqualToString:reaction.content]) {
            issueComment.thumbsUpCount += 1;
        } else if ([@"-1" isEqualToString:reaction.content]) {
            issueComment.thumbsDownCount += 1;
        } else if ([@"laugh" isEqualToString:reaction.content]) {
            issueComment.laughCount += 1;
        } else if ([@"hooray" isEqualToString:reaction.content]) {
            issueComment.hoorayCount += 1;
        } else if ([@"confused" isEqualToString:reaction.content]) {
            issueComment.confusedCount += 1;
        } else if ([@"heart" isEqualToString:reaction.content]) {
            issueComment.heartCount += 1;
        } else {
            NSAssert(false, @"unknown reaction");
        }
    }];
    
    [QIssueCommentStore saveIssueComment:issueComment];
}



+ (void)saveIssueComment:(QIssueComment *)issueComment;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(issueComment.account);
    NSParameterAssert(issueComment.repository);
    NSParameterAssert(issueComment.identifier);
    NSParameterAssert(issueComment.user);
    NSParameterAssert(issueComment.issueNumber);
    
    // save users
    [QOwnerStore saveOwner:issueComment.user];
    
    
    // save issue comment
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    [QIssueCommentStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT updated_at, html_url FROM issue_comment WHERE account_id = ? AND identifier = ? AND repository_id = ? AND issue_number = ?",
                           issueComment.account.identifier ?:[NSNull null],
                           issueComment.identifier ?:[NSNull null],
                           issueComment.repository.identifier ?:[NSNull null],
                           issueComment.issueNumber ?:[NSNull null]];
        
        if ([rs next]) {
            
//            NSDate *currentDate = [rs dateForColumn:@"updated_at"];
//            if ([issueComment.updatedAt compare:currentDate] != NSOrderedDescending && [rs stringForColumn:@"html_url"] != nil) {
//                [rs close];
//                return;
//            }
            
            BOOL success = [db executeUpdate:@"UPDATE issue_comment SET html_url = ?, body = ?, updated_at = ?, thumbsup_count = ?, thumbsdown_count = ?, laugh_count = ?, hooray_count = ?, confused_count = ?, heart_count = ? WHERE account_id = ? AND identifier = ? AND repository_id = ? AND issue_number = ?",
                            issueComment.htmlURL.absoluteString ?:[NSNull null],
                            issueComment.body ?: [NSNull null],
                            issueComment.updatedAt ?:[NSNull null],
                            @(issueComment.thumbsUpCount),
                            @(issueComment.thumbsDownCount),
                            @(issueComment.laughCount),
                            @(issueComment.hoorayCount),
                            @(issueComment.confusedCount),
                            @(issueComment.heartCount),
                            issueComment.account.identifier ?:[NSNull null],
                            issueComment.identifier ?:[NSNull null],
                            issueComment.repository.identifier ?:[NSNull null],
                            issueComment.issueNumber ?:[NSNull null]
                            ];
            
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Update;
            
        } else {
            
            BOOL success = [db executeUpdate:@"INSERT INTO issue_comment (identifier, repository_id, body, issue_number, created_at, updated_at, user_id, account_id, html_url, thumbsup_count, thumbsdown_count, laugh_count, hooray_count, confused_count, heart_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            issueComment.identifier ?:[NSNull null],
                            issueComment.repository.identifier ?:[NSNull null],
                            issueComment.body ?:[NSNull null],
                            issueComment.issueNumber ?:[NSNull null],
                            issueComment.createdAt ?:[NSNull null],
                            issueComment.updatedAt ?:[NSNull null],
                            issueComment.user.identifier ?:[NSNull null],
                            issueComment.account.identifier ?:[NSNull null],
                            issueComment.htmlURL.absoluteString,
                            @(issueComment.thumbsUpCount),
                            @(issueComment.thumbsDownCount),
                            @(issueComment.laughCount),
                            @(issueComment.hoorayCount),
                            @(issueComment.confusedCount),
                            @(issueComment.heartCount)
                            ];
            
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Insert;
        }
        
        [rs close];
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [QIssueCommentStore notifyInsertObserversForStore:QIssueCommentStore.class record:issueComment];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [QIssueCommentStore notifyUpdateObserversForStore:QIssueCommentStore.class record:issueComment];
    }
}

+ (NSMutableArray<QIssueComment *> *)issueCommentsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueNumber);
    
    __block NSMutableArray<_IssueCommentResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_comment WHERE account_id = ? AND repository_id = ? AND issue_number = ? ORDER BY created_at ASC", accountId, repositoryId, issueNumber];
        
        while ([rs next]) {
            _IssueCommentResultSetEntry *entry = [QIssueCommentStore _issueCommentResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    
    NSMutableArray<QIssueComment *> *issueComments = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_IssueCommentResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QIssueComment *issueComment = [QIssueCommentStore _issueCommentFromResultSetEntry:entry];
        [issueComments addObject:issueComment];
        
    }];
    
    return issueComments;
}

+ (NSArray<NSNumber *> *)issueCommentIdsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueNumber);
    
    __block NSMutableArray<NSNumber *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT identifier FROM issue_comment WHERE account_id = ? AND repository_id = ? AND issue_number = ? ORDER BY created_at ASC", accountId, repositoryId, issueNumber];
        
        while ([rs next]) {
            [entries addObject:@([rs intForColumn:@"identifier"])];
        }
        [rs close];
    }];
    
    return [entries mutableCopy];
}

+ (QIssueComment *)issueCommentForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueCommentId:(NSNumber *)issueCommentId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueCommentId);
    
    __block _IssueCommentResultSetEntry *entry = nil;
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_comment WHERE account_id = ? AND repository_id = ? AND identifier = ?", accountId, repositoryId, issueCommentId];
        
        while ([rs next]) {
            entry = [QIssueCommentStore _issueCommentResultSetEntryFromResultSet:rs];
        }
        [rs close];
    }];
    
    if (!entry) {
        return nil;
    }
    
    QIssueComment *issueComment = [QIssueCommentStore _issueCommentFromResultSetEntry:entry];
    return issueComment;
}

+ (void)deleteIssueCommentId:(NSNumber *)issueCommentId accountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueCommentId);
    
    QIssueComment *issueComment = [QIssueCommentStore issueCommentForAccountId:accountId repositoryId:repositoryId issueCommentId:issueCommentId];
    if (!issueComment) {
        return;
    }
    
    [QMilestoneStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM issue_comment WHERE account_id = ? AND repository_id = ? AND identifier = ?", accountId, repositoryId, issueCommentId];
        NSParameterAssert(success);
    }];
    
    [QIssueCommentStore notifyDeletionObserversForStore:QIssueCommentStore.class record:issueComment];
}

#pragma mark - helpers

+ (QIssueComment *)_issueCommentFromResultSetEntry:(_IssueCommentResultSetEntry *)entry
{
    QIssueComment *issueComment = entry.issueComment;
    issueComment.account = [QAccountStore accountForIdentifier:entry.accountId];
    issueComment.user = [QOwnerStore ownerForAccountId:entry.accountId identifier:entry.userId];
    issueComment.repository = [QRepositoryStore repositoryForAccountId:entry.accountId identifier:entry.repositoryId];
    return issueComment;
}

+ (_IssueCommentResultSetEntry *)_issueCommentResultSetEntryFromResultSet:(FMResultSet *)rs
{
    QIssueComment *issueComment = [QIssueComment new];
    
    issueComment.createdAt = [rs dateForColumn:@"created_at"];
    issueComment.updatedAt = [rs dateForColumn:@"updated_at"];
    issueComment.identifier = @([rs intForColumn:@"identifier"]);
    issueComment.body = [rs stringForColumn:@"body"];
    issueComment.issueNumber = @([rs intForColumn:@"issue_number"]);
    issueComment.thumbsUpCount = [rs intForColumn:@"thumbsup_count"];
    issueComment.thumbsDownCount = [rs intForColumn:@"thumbsdown_count"];
    issueComment.laughCount = [rs intForColumn:@"laugh_count"];
    issueComment.hoorayCount = [rs intForColumn:@"hooray_count"];
    issueComment.confusedCount = [rs intForColumn:@"confused_count"];
    issueComment.heartCount = [rs intForColumn:@"heart_count"];
    
    if (![rs columnIsNull:@"html_url"]) {
        issueComment.htmlURL = [NSURL URLWithString:[rs stringForColumn:@"html_url"]];
    }
    
    _IssueCommentResultSetEntry *entry = [_IssueCommentResultSetEntry new];
    
    entry.issueComment = issueComment;
    
    
    entry.userId = @([rs intForColumn:@"user_id"]);
    entry.accountId = @([rs intForColumn:@"account_id"]);
    entry.repositoryId = @([rs intForColumn:@"repository_id"]);
    
    
    return entry;
}

@end
