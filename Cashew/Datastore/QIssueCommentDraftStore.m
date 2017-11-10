//
//  QIssueCommentDraftStore.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/22/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "QIssueCommentDraftStore.h"
#import "Cashew-Swift.h"

@interface _IssueCommentDraftResultSetEntry : NSObject

@property (nonatomic) NSNumber *issueNumber;
@property (nonatomic) NSNumber *issueCommentId;
@property (nonatomic) NSNumber *accountId;
@property (nonatomic) NSNumber *repositoryId;
@property (nonatomic) NSString *body;
@property (nonatomic) SRIssueCommentDraftType draftType;
@end

@implementation _IssueCommentDraftResultSetEntry

@end

@implementation QIssueCommentDraftStore

+ (void)deleteIssueCommentDraft:(SRIssueCommentDraft *)issueCommentDraft;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(issueCommentDraft.account);
    NSParameterAssert(issueCommentDraft.repository);
    NSParameterAssert(issueCommentDraft.issueNumber);
    
    [QIssueCommentDraftStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *sql = nil;
        if (issueCommentDraft.issueCommentId == nil) {
            sql = @"DELETE FROM issue_comment_draft WHERE account_id = ? AND repository_id = ? AND issue_number = ? AND issue_comment_id is NULL AND type = ?";
            BOOL success = [db executeUpdate:sql,
                            issueCommentDraft.account.identifier ?:[NSNull null],
                            issueCommentDraft.repository.identifier ?:[NSNull null],
                            issueCommentDraft.issueNumber ?:[NSNull null],
                            @(issueCommentDraft.type)];
            NSParameterAssert(success);
            
        } else {
            sql = @"DELETE FROM issue_comment_draft WHERE account_id = ? AND repository_id = ? AND issue_number = ? AND issue_comment_id = ? AND type = ?";
            BOOL success = [db executeUpdate:sql,
                            issueCommentDraft.account.identifier ?:[NSNull null],
                            issueCommentDraft.repository.identifier ?:[NSNull null],
                            issueCommentDraft.issueNumber ?:[NSNull null],
                            issueCommentDraft.issueCommentId ?:[NSNull null],
                            @(issueCommentDraft.type)];
            NSParameterAssert(success);
        }
    }];
    
    [QIssueCommentDraftStore notifyDeletionObserversForStore:QIssueCommentDraftStore.class record:issueCommentDraft];
}

+ (NSInteger)totalIssueCommentDraftsForAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    __block NSInteger total = 0;
    [QIssueCommentDraftStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(DISTINCT (account_id || \"_\" || repository_id || \"_\" || issue_number)) FROM issue_comment_draft where account_id = ?", accountId];
        if ([rs next]) {
            total = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return total;
}

+ (void)saveIssueCommentDraft:(SRIssueCommentDraft *)issueCommentDraft;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(issueCommentDraft.account);
    NSParameterAssert(issueCommentDraft.repository);
    NSParameterAssert(issueCommentDraft.issueNumber);
    
    if (!issueCommentDraft.body || issueCommentDraft.body.trimmedString.length == 0) {
        return;
    }
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    
    [QIssueCommentDraftStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = nil;
        
        if (issueCommentDraft.issueCommentId != nil) {
            rs = [db executeQuery:@"SELECT * FROM issue_comment_draft WHERE account_id = ? AND repository_id = ? AND issue_number = ? AND issue_comment_id = ? AND type = ?",
                  issueCommentDraft.account.identifier ?:[NSNull null],
                  issueCommentDraft.repository.identifier ?:[NSNull null],
                  issueCommentDraft.issueNumber ?:[NSNull null],
                  issueCommentDraft.issueCommentId ?:[NSNull null],
                  @(issueCommentDraft.type)];
        } else {
            rs = [db executeQuery:@"SELECT * FROM issue_comment_draft WHERE account_id = ? AND repository_id = ? AND issue_number = ? AND issue_comment_id is NULL AND type = ?",
                  issueCommentDraft.account.identifier ?:[NSNull null],
                  issueCommentDraft.repository.identifier ?:[NSNull null],
                  issueCommentDraft.issueNumber ?:[NSNull null],
                  @(issueCommentDraft.type)];
        }
        
        if ([rs next]) {
            [rs close];
            BOOL success = false;
            //DDLogDebug(@"updating -> %@ %@ %@ %@ %@", issueCommentDraft.account.identifier, issueCommentDraft.repository.identifier, issueCommentDraft.issueNumber, issueCommentDraft.issueCommentId ?: @"nil", issueCommentDraft.body);
            if (issueCommentDraft.issueCommentId != nil) {
                success = [db executeUpdate:@"UPDATE issue_comment_draft SET body = ? WHERE account_id = ? AND repository_id = ? AND issue_number = ? AND issue_comment_id = ? AND type = ?",
                           issueCommentDraft.body,
                           issueCommentDraft.account.identifier ?:[NSNull null],
                           issueCommentDraft.repository.identifier ?:[NSNull null],
                           issueCommentDraft.issueNumber ?:[NSNull null],
                           issueCommentDraft.issueCommentId ?:[NSNull null],
                           @(issueCommentDraft.type)];
            } else {
                success = [db executeUpdate:@"UPDATE issue_comment_draft SET body = ? WHERE account_id = ? AND repository_id = ? AND issue_number = ? AND issue_comment_id is NULL AND type = ?",
                           issueCommentDraft.body,
                           issueCommentDraft.account.identifier ?:[NSNull null],
                           issueCommentDraft.repository.identifier ?:[NSNull null],
                           issueCommentDraft.issueNumber ?:[NSNull null],
                           @(issueCommentDraft.type)];
            }
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Update;
            
        } else {
            //DDLogDebug(@"inserting-> %@ %@ %@ %@ %@", issueCommentDraft.account.identifier, issueCommentDraft.repository.identifier, issueCommentDraft.issueNumber, issueCommentDraft.issueCommentId ?: @"nil", issueCommentDraft.body);
            BOOL success = [db executeUpdate:@"INSERT INTO issue_comment_draft (body, account_id, repository_id, issue_number, issue_comment_id, type) VALUES (?, ?, ?, ?, ?, ?)",
                            issueCommentDraft.body,
                            issueCommentDraft.account.identifier ?:[NSNull null],
                            issueCommentDraft.repository.identifier ?:[NSNull null],
                            issueCommentDraft.issueNumber ?:[NSNull null],
                            issueCommentDraft.issueCommentId ?:[NSNull null],
                            @(issueCommentDraft.type)];
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Insert;
        }
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [QIssueCommentDraftStore notifyInsertObserversForStore:QIssueCommentDraftStore.class record:issueCommentDraft];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [QIssueCommentDraftStore notifyUpdateObserversForStore:QIssueCommentDraftStore.class record:issueCommentDraft];
    }
}

+ (NSArray<SRIssueCommentDraft *> *)issueCommentDraftsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueNumber);
    
    __block NSMutableArray<_IssueCommentDraftResultSetEntry *> *draftEntries = [NSMutableArray new];
    
    [QIssueCommentDraftStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_comment_draft WHERE account_id = ? AND repository_id = ? AND issue_number = ?",
                           accountId ?: [NSNull null], repositoryId ?: [NSNull null], issueNumber ?: [NSNull null]];
        
        while ([rs next]) {
            _IssueCommentDraftResultSetEntry *entry = [_IssueCommentDraftResultSetEntry new];
            entry.accountId = @([rs intForColumn:@"account_id"]);
            entry.repositoryId = @([rs intForColumn:@"repository_id"]);
            entry.issueNumber = @([rs intForColumn:@"issue_number"]);
            entry.body = [rs stringForColumn:@"body"];
            
            if (![rs columnIsNull:@"issue_comment_id"]) {
                entry.issueCommentId = @([rs intForColumn:@"issue_comment_id"]);
            }
            entry.draftType = [rs intForColumn:@"type"];
            
            [draftEntries addObject:entry];
        }
        
        [rs close];
    }];
    
    
    NSMutableArray<SRIssueCommentDraft *> *drafts = [NSMutableArray new];
    
    [draftEntries enumerateObjectsUsingBlock:^(_IssueCommentDraftResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QAccount *account = [QAccountStore accountForIdentifier:entry.accountId];
        QRepository *repository = [QRepositoryStore repositoryForAccountId:entry.accountId identifier:entry.repositoryId];
        
        SRIssueCommentDraft *draft = [[SRIssueCommentDraft alloc] initWithAccount:account repository:repository issueCommentId:entry.issueCommentId issueNumber:entry.issueNumber body:entry.body type:entry.draftType];
        [drafts addObject:draft];
    }];
    
    return drafts;
}

@end
