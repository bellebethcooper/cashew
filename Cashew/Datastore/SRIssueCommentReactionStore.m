//
//  SRIssueCommentReactionStore.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRIssueCommentReactionStore.h"
#import "Cashew-Swift.h"

@implementation SRIssueCommentReactionStore

+ (void)saveIssueCommentReaction:(SRIssueCommentReaction *)issueCommentReaction
{
    NSParameterAssert(issueCommentReaction.account.identifier && issueCommentReaction.account.identifier.integerValue > 0);
    NSParameterAssert(issueCommentReaction.identifier);
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    
    [SRIssueCommentReactionStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_comment_reaction WHERE account_id = ? AND identifier = ?", issueCommentReaction.account.identifier, issueCommentReaction.identifier];
        
        if ([rs next]) {
            
            NSDate *createdAtDate = [rs dateForColumn:@"created_at"];
            NSString *content = [rs stringForColumn:@"content"];
            
            if ([content isEqualToString:issueCommentReaction.content] && [issueCommentReaction.createdAt compare:createdAtDate] != NSOrderedDescending) {
                [rs close];
                return;
            }
            
            [rs close];
            
            BOOL success = [db executeUpdate:@"UPDATE issue_comment_reaction SET content = ?, created_at = ? WHERE account_id = ? AND identifier = ?",
                            issueCommentReaction.content, issueCommentReaction.createdAt, issueCommentReaction.account.identifier, issueCommentReaction.identifier];
            
            NSParameterAssert(success);
            
            
            dbOperation = QBaseDatabaseOperation_Update;
            
        } else {
            
            BOOL success = [db executeUpdate:@"INSERT INTO issue_comment_reaction (identifier, user_id, repository_id, account_id, content, created_at, issue_comment_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
                            issueCommentReaction.identifier, issueCommentReaction.user.identifier, issueCommentReaction.repository.identifier, issueCommentReaction.account.identifier, issueCommentReaction.content, issueCommentReaction.createdAt, issueCommentReaction.issueCommentIdentifier];
            
            NSParameterAssert(success);
            
            dbOperation = QBaseDatabaseOperation_Insert;
            
        }
        
        
        [rs close];
    }];
    
    NSParameterAssert(![NSThread isMainThread]);
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [SRIssueCommentReactionStore notifyInsertObserversForStore:SRIssueCommentReactionStore.class record:issueCommentReaction];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [SRIssueCommentReactionStore notifyUpdateObserversForStore:SRIssueCommentReactionStore.class record:issueCommentReaction];
    }
    
}

+ (SRIssueCommentReaction *)didUserId:(NSNumber *)userId addReactionToIssueComment:(QIssueComment *)issueComment withContent:(NSString *)content;
{
    NSParameterAssert(userId);
    NSParameterAssert(issueComment);
    NSParameterAssert(content);
    
    __block SRIssueCommentReaction *reaction = nil;
    
    [SRIssueReactionStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_comment_reaction WHERE account_id = ? AND repository_id = ? AND issue_comment_id = ? AND content = ? AND user_id = ?", issueComment.account.identifier, issueComment.repository.identifier, issueComment.identifier, content, userId];
        
        if ([rs next]) {
            reaction = [SRIssueCommentReactionStore _issueCommentReactionFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    return reaction;
}

+ (void)deleteIssueCommentReaction:(SRIssueCommentReaction *)issueCommentReaction
{
    NSParameterAssert(issueCommentReaction.account.identifier);
    NSParameterAssert(issueCommentReaction.identifier);
    
    [SRIssueCommentReactionStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM issue_comment_reaction WHERE account_id = ? AND identifier = ?", issueCommentReaction.account.identifier, issueCommentReaction.identifier];
        
        NSParameterAssert(success);
    }];
    
    NSParameterAssert(![NSThread isMainThread]);
    [SRIssueCommentReactionStore notifyDeletionObserversForStore:SRIssueCommentReactionStore.class record:issueCommentReaction];
}


+ (NSArray<SRIssueCommentReaction *> *)issueCommentReactionsForIssueComment:(QIssueComment *)issueComment
{
    NSParameterAssert(issueComment);
    
    NSMutableArray<SRIssueCommentReaction *> *reactions = [NSMutableArray new];
    
    [SRIssueCommentReactionStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_comment_reaction WHERE account_id = ? AND repository_id = ? AND issue_comment_id = ?", issueComment.account.identifier, issueComment.repository.identifier, issueComment.identifier];
        
        while ([rs next]) {
            SRIssueCommentReaction *reaction = [SRIssueCommentReactionStore _issueCommentReactionFromResultSet:rs];
            
            [reactions addObject:reaction];
            
        }
        
        [rs close];
    }];
    
    return reactions;
}

+ (SRIssueCommentReaction *)_issueCommentReactionFromResultSet:(FMResultSet *)rs
{
    SRIssueCommentReaction *reaction = [SRIssueCommentReaction new];
    
    reaction.identifier = @([rs intForColumn:@"identifier"]);
    NSNumber *repositoryId = @([rs intForColumn:@"repository_id"]);
    NSNumber *accountId = @([rs intForColumn:@"account_id"]);
    NSNumber *userId = @([rs intForColumn:@"user_id"]);
    
    reaction.user = [QOwnerStore ownerForAccountId:accountId identifier:userId];
    reaction.repository = [QRepositoryStore repositoryForAccountId:accountId identifier:repositoryId];
    reaction.account = reaction.repository.account;
    reaction.content = [rs stringForColumn:@"content"];
    reaction.createdAt = [rs dateForColumn:@"created_at"];
    reaction.issueCommentIdentifier = @([rs intForColumn:@"issue_comment_id"]);
    
    return reaction;
}

@end
