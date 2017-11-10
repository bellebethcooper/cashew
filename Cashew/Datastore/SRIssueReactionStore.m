//
//  SRIssueReactionStore.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRIssueReactionStore.h"
#import "QOwnerStore.h"
#import "QRepositoryStore.h"

@implementation SRIssueReactionStore

+ (void)saveIssueReaction:(SRIssueReaction *)issueReaction;
{
    NSParameterAssert(issueReaction.account.identifier);
    NSParameterAssert(issueReaction.issueNumber);
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    
    [SRIssueReactionStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_reaction WHERE account_id = ? AND identifier = ?", issueReaction.account.identifier, issueReaction.identifier];
        
        if ([rs next]) {
            
            NSDate *createdAtDate = [rs dateForColumn:@"created_at"];
            NSString *content = [rs stringForColumn:@"content"];
            
            if ([content isEqualToString:issueReaction.content] && [issueReaction.createdAt compare:createdAtDate] != NSOrderedDescending) {
                [rs close];
                return;
            }
            
            [rs close];
            
            BOOL success = [db executeUpdate:@"UPDATE issue_reaction SET content = ?, created_at = ? WHERE account_id = ? AND identifier = ?",
                            issueReaction.content, issueReaction.createdAt, issueReaction.account.identifier, issueReaction.identifier];
            
            NSParameterAssert(success);

            
            dbOperation = QBaseDatabaseOperation_Update;
            
        } else {
            
            BOOL success = [db executeUpdate:@"INSERT INTO issue_reaction (identifier, user_id, repository_id, account_id, content, created_at, issue_number) VALUES (?, ?, ?, ?, ?, ?, ?)",
                            issueReaction.identifier, issueReaction.user.identifier, issueReaction.repository.identifier, issueReaction.account.identifier, issueReaction.content, issueReaction.createdAt, issueReaction.issueNumber];
            
            NSParameterAssert(success);
            
            dbOperation = QBaseDatabaseOperation_Insert;
            
        }
        
        
        [rs close];
    }];
    
    NSParameterAssert(![NSThread isMainThread]);
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [SRIssueReactionStore notifyInsertObserversForStore:SRIssueReactionStore.class record:issueReaction];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [SRIssueReactionStore notifyUpdateObserversForStore:SRIssueReactionStore.class record:issueReaction];
    }
    
}

+ (void)deleteIssueReaction:(SRIssueReaction *)issueReaction;
{
    NSParameterAssert(issueReaction.account.identifier);
    NSParameterAssert(issueReaction.issueNumber);
    
    [SRIssueReactionStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM issue_reaction WHERE account_id = ? AND identifier = ?", issueReaction.account.identifier, issueReaction.identifier];
        
        NSParameterAssert(success);
    }];
    
    NSParameterAssert(![NSThread isMainThread]);
    [SRIssueReactionStore notifyDeletionObserversForStore:SRIssueReactionStore.class record:issueReaction];
}

+ (SRIssueReaction *)didUserId:(NSNumber *)userId addReactionToIssue:(QIssue *)issue withContent:(NSString *)content;
{
    NSParameterAssert(userId);
    NSParameterAssert(issue);
    NSParameterAssert(content);
    
    __block SRIssueReaction *reaction = nil;
    
    [SRIssueReactionStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_reaction WHERE account_id = ? AND repository_id = ? AND issue_number = ? AND content = ? AND user_id = ?", issue.account.identifier, issue.repository.identifier, issue.issueNum, content, userId];
        
        if ([rs next]) {
            reaction = [SRIssueReactionStore _issueReactionFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    return reaction;
}

+ (NSArray<SRIssueReaction *> *)issueReactionsForIssue:(QIssue *)issue;
{
    NSParameterAssert(issue);
    
    NSMutableArray<SRIssueReaction *> *reactions = [NSMutableArray new];
    
    [SRIssueReactionStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_reaction WHERE account_id = ? AND repository_id = ? AND issue_number = ?", issue.account.identifier, issue.repository.identifier, issue.issueNum];
        
        while ([rs next]) {
            SRIssueReaction *reaction = [SRIssueReactionStore _issueReactionFromResultSet:rs];
            [reactions addObject:reaction];
            
        }
        
        [rs close];
    }];
    
    return reactions;
}

+ (SRIssueReaction *)_issueReactionFromResultSet:(FMResultSet *)rs
{
    SRIssueReaction *reaction = [SRIssueReaction new];
    
    reaction.identifier = @([rs intForColumn:@"identifier"]);
    NSNumber *repositoryId = @([rs intForColumn:@"repository_id"]);
    NSNumber *accountId = @([rs intForColumn:@"account_id"]);
    NSNumber *userId = @([rs intForColumn:@"user_id"]);
    
    reaction.user = [QOwnerStore ownerForAccountId:accountId identifier:userId];
    reaction.repository = [QRepositoryStore repositoryForAccountId:accountId identifier:repositoryId];
    reaction.account = reaction.repository.account;
    reaction.content = [rs stringForColumn:@"content"];
    reaction.createdAt = [rs dateForColumn:@"created_at"];
    reaction.issueNumber = @([rs intForColumn:@"issue_number"]);
    
    return reaction;
}

@end
