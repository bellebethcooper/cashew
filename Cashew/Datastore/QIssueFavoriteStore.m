//
//  QIssueFavoriteStore.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/23/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "QIssueFavoriteStore.h"
#import "QIssue.h"

@implementation QIssueFavoriteStore


+ (void)favoriteIssue:(QIssue *)issue;
{
    NSParameterAssert(issue.account.identifier);
    NSParameterAssert(issue.repository.identifier);
    NSParameterAssert(issue.number);
    
    __block BOOL didCreate = false;
    
    [QIssueFavoriteStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_favorite WHERE account_id = ? AND repository_id = ? AND issue_number = ?", issue.account.identifier, issue.repository.identifier, issue.number];
        if ( [rs next] ) {
            [rs close];
            return;
        }
        [rs close];
        
        didCreate = true;
        BOOL success = [db executeUpdate:@"INSERT INTO issue_favorite (account_id, repository_id, issue_number, search_uniq_key) VALUES (?, ?, ?, ?)", issue.account.identifier, issue.repository.identifier, issue.number, [QIssueFavoriteStore _issueFavoriteSearchKeyForIssue:issue]];
        NSParameterAssert(success);
    }];
    
    if (didCreate) {
        [QIssueFavoriteStore notifyInsertObserversForStore:QIssueFavoriteStore.class record:issue];
    }
}

+ (BOOL)isFavoritedIssue:(QIssue *)issue;
{
    __block BOOL isFavorited = false;
    
    [QIssueFavoriteStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_favorite WHERE account_id = ? AND repository_id = ? AND issue_number = ?", issue.account.identifier, issue.repository.identifier, issue.number];
        if ( [rs next] ) {
            isFavorited = true;
        }
        [rs close];
    }];
    
    return isFavorited;
}

+ (void)unfavoriteIssue:(QIssue *)issue;
{
    NSParameterAssert(issue.account.identifier);
    NSParameterAssert(issue.repository.identifier);
    NSParameterAssert(issue.number);
    
    [QIssueFavoriteStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM issue_favorite WHERE account_id = ? AND repository_id = ? AND issue_number = ?", issue.account.identifier, issue.repository.identifier, issue.number];
        NSParameterAssert(success);
    }];
    [QIssueFavoriteStore notifyDeletionObserversForStore:QIssueFavoriteStore.class record:issue];
}

+ (NSInteger)totalFavoritedOutOfIssues:(NSArray<QIssue *> *)issues;
{
    NSParameterAssert(issues);
    __block NSInteger count = 0;
    
    NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
    NSMutableArray<NSString *> *args = [NSMutableArray new];
    
    [issues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [QIssueFavoriteStore _issueFavoriteSearchKeyForIssue:issue];
        [questionMarks addObject:@"?"];
        [args addObject:key];
    }];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) as total FROM issue_favorite WHERE search_uniq_key in (%@)", [questionMarks componentsJoinedByString:@", "]];
    
    
    [QIssueFavoriteStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        if ([rs next]) {
            count = [rs intForColumnIndex:0];
            [rs close];
        }
    }];
    
    return count;
}

+ (NSString *)_issueFavoriteSearchKeyForIssue:(QIssue *)issue
{
    return [NSString stringWithFormat:@"%@_%@_%@", issue.account.identifier, issue.repository.identifier, issue.number];
}

@end
