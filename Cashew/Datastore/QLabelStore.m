//
//  QLabelStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QLabelStore.h"
#import "QAccountStore.h"
#import "QRepositoryStore.h"
#import "Cashew-Swift.h"


@interface _LabelResultSetEntry : NSObject
@property (nonatomic, strong) QLabel *label;
@property (nonatomic, strong) NSNumber *accountId;
@property (nonatomic, strong) NSNumber *repositoryId;
@end

@implementation _LabelResultSetEntry

@end



@implementation QLabelStore

+ (void)saveLabel:(QLabel *)label allowUpdate:(BOOL)allowUpdate;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(label);
    NSParameterAssert(label.name);
    //NSParameterAssert(label.color);
    NSParameterAssert(label.repository);
    NSParameterAssert(label.account);
    
    NSString *labelCacheKey = [SRLabelCache LabelCacheKeyForAccountId:label.account.identifier repositoryId: label.repository.identifier name: label.name];
    [[SRLabelCache sharedCache] set:label forKey:labelCacheKey];
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    [QLabelStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM label WHERE account_id = ? AND name LIKE ? AND repository_id = ?",
                           label.account.identifier ?:[NSNull null], label.name ?:[NSNull null], label.repository.identifier ?:[NSNull null]];
        
        if ([rs next]) {
            
            if (allowUpdate){
                // DDLogDebug(@"name => %@ color=> %@ updated at => %@ vs %@", [rs stringForColumn:@"name"], [rs stringForColumn:@"color"], [rs dateForColumn:@"updated_at"], label.updatedAt);
                FMResultSet *afterRS = [db executeQuery:@"SELECT * FROM label WHERE account_id = ? AND name LIKE ? AND repository_id = ? AND updated_at > ?", label.account.identifier ?:[NSNull null], label.name ?:[NSNull null], label.repository.identifier ?:[NSNull null], label.updatedAt ?: @0];
                
                BOOL shouldUpdate = ![afterRS next];
                [afterRS close];
                
                if (shouldUpdate) {
                    BOOL success = [db executeUpdate:@"UPDATE label SET color = ? WHERE account_id = ? AND name LIKE ? AND repository_id = ? AND created_at = ? AND updated_at = ?",
                                    label.color ?:[NSNull null], label.account.identifier ?:[NSNull null], label.name ?:[NSNull null], label.repository.identifier ?:[NSNull null], label.createdAt ?:@0, label.updatedAt  ?:@0];
                    
                    NSParameterAssert(success);
                    dbOperation = QBaseDatabaseOperation_Update;
                }
            }
        } else {
            BOOL success = [db executeUpdate:@"INSERT INTO label (name, color, repository_id, account_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                            label.name ?:[NSNull null], label.color ?:[NSNull null], label.repository.identifier ?:[NSNull null], label.account.identifier ?:[NSNull null], label.createdAt ?:@0, label.updatedAt  ?:@0];
            NSParameterAssert(success);
            
            success = [db executeUpdate:@"INSERT INTO label_search (name, repository_id, account_id) VALUES (?, ?, ?)",
                       label.name ?:[NSNull null], label.repository.identifier ?:[NSNull null], label.account.identifier ?:[NSNull null]];
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Insert;
        }
        [rs close];
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [QLabelStore notifyInsertObserversForStore:QLabelStore.class record:label];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [QLabelStore notifyUpdateObserversForStore:QLabelStore.class record:label];
    }
}

+ (void)saveIssueLabels:(NSArray<QLabel *> *)labels forIssue:(QIssue *)issue
{
    NSParameterAssert(labels);
    NSParameterAssert(issue);
    
    NSSet *set = [NSSet setWithArray:labels];
    
    [QLabelStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL success = [db executeUpdate:@"DELETE FROM issue_label WHERE account_id = ? AND issue_id = ? AND repository_id = ?", issue.account.identifier, issue.identifier, issue.repository.identifier];
        NSParameterAssert(success);
        
        [set enumerateObjectsUsingBlock:^(QLabel * _Nonnull label, BOOL * _Nonnull stop) {
            NSString *labelCacheKey = [SRLabelCache LabelCacheKeyForAccountId:label.account.identifier repositoryId: label.repository.identifier name: label.name];
            [[SRLabelCache sharedCache] set:label forKey:labelCacheKey];
            
            BOOL success = [db executeUpdate:@"INSERT INTO issue_label (account_id, issue_id, repository_id, name) VALUES (?, ?, ?, ?)", issue.account.identifier, issue.identifier, issue.repository.identifier, label.name];
            NSParameterAssert(success);
        }];
        
    }];
}

+ (void)loadLabelsForIssues:(NSArray<QIssue *> *)issues;
{
    NSParameterAssert(issues);
    
    NSMutableString *sqls = [NSMutableString new];
    
    // map issues
    NSMutableDictionary *map = [NSMutableDictionary new];
    NSMutableArray *args = [NSMutableArray new];
    [issues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [QLabelStore _mapKeyForIssueAccountId:issue.account.identifier repositoryId:issue.repository.identifier issueId:issue.identifier];
        map[key] = issue;
        [sqls appendString:@"SELECT i.name as name, i.color as color, i.repository_id as repository_id, i.account_id as account_id, l.issue_id as issue_id, i.updated_at as updated_at, i.created_at as created_at FROM issue_label l INNER JOIN label i ON i.account_id = l.account_id AND i.name LIKE l.name AND i.repository_id = l.repository_id WHERE l.account_id = ? AND l.issue_id = ? AND l.repository_id = ?"];
        if (idx != issues.count-1) {
            [sqls appendString:@" \nUNION\n "];
        }
        [args addObject:issue.account.identifier];
        [args addObject:issue.identifier];
        [args addObject:issue.repository.identifier];
        
    }];
    
    
    // grab labels
    NSMutableDictionary *labelMap = [NSMutableDictionary new];
    [QLabelStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sqls withArgumentsInArray:args];
        while ([rs next]) {
            QLabel *label = [QLabel new];
            label.name = [rs stringForColumn:@"name"];
            label.color = [rs stringForColumn:@"color"];
            label.updatedAt = [rs dateForColumn:@"updated_at"];
            label.createdAt = [rs dateForColumn:@"created_at"];
            
            NSNumber *accountId = @([rs intForColumn:@"account_id"]);
            NSNumber *repositoryId = @([rs intForColumn:@"repository_id"]);
            NSNumber *issueId = @([rs intForColumn:@"issue_id"]);
            
            NSString *key = [QLabelStore _mapKeyForIssueAccountId:accountId repositoryId:repositoryId issueId:issueId];
            QIssue *issue = map[key];
            
            label.repository = issue.repository;
            label.account = issue.account;
            
            NSParameterAssert(issue);
            NSMutableSet *labelSet = labelMap[key];
            if (!labelSet) {
                labelSet = [NSMutableSet new];
                labelMap[key] = labelSet;
            }
            [labelSet addObject:label];
        }
        [rs close];
    }];
    
    // match things up
    [issues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [QLabelStore _mapKeyForIssueAccountId:issue.account.identifier repositoryId:issue.repository.identifier issueId:issue.identifier];
        issue.labels =  [labelMap[key] sortedArrayUsingComparator:^NSComparisonResult(QLabel *  _Nonnull obj1, QLabel *  _Nonnull obj2) {
            return [obj1.name compare:obj2.name];
        }]; //[labelMap[key] copy];
    }];
    
}

+ (NSMutableArray<QLabel *> *)labelsForAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSMutableArray<_LabelResultSetEntry *> *results = [NSMutableArray new];
    [QLabelStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM label where account_id = ? ORDER BY name", accountId];
        while ([rs next]) {
            _LabelResultSetEntry *entry = [_LabelResultSetEntry new];
            entry.label = [QLabel new];
            entry.label.name = [rs stringForColumn:@"name"];
            entry.label.color = [rs stringForColumn:@"color"];
            entry.accountId = @([rs intForColumn:@"account_id"]);
            entry.repositoryId = @([rs intForColumn:@"repository_id"]);
            entry.label.updatedAt = [rs dateForColumn:@"updated_at"];
            entry.label.createdAt = [rs dateForColumn:@"created_at"];
            [results addObject:entry];
        }
        
    }];
    
    NSMutableArray<QLabel *> *labels = [NSMutableArray new];
    [results enumerateObjectsUsingBlock:^(_LabelResultSetEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.label setAccount:[QAccountStore accountForIdentifier:obj.accountId]];
        [obj.label setRepository:[QRepositoryStore repositoryForAccountId:obj.accountId identifier:obj.repositoryId]];
        [labels addObject:obj.label];
    }];
    
    return labels;
}

+ (NSArray<QLabel *> *)labelsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId includeHidden:(BOOL)includeHidden;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    
    NSMutableArray<_LabelResultSetEntry *> *results = [NSMutableArray new];
    [QLabelStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM label where account_id = ? and repository_id = ? ORDER BY name", accountId, repositoryId];
        while ([rs next]) {
            _LabelResultSetEntry *entry = [_LabelResultSetEntry new];
            entry.label = [QLabel new];
            entry.label.name = [rs stringForColumn:@"name"];
            entry.label.color = [rs stringForColumn:@"color"];
            entry.accountId = @([rs intForColumn:@"account_id"]);
            entry.repositoryId = @([rs intForColumn:@"repository_id"]);
            entry.label.updatedAt = [rs dateForColumn:@"updated_at"];
            entry.label.createdAt = [rs dateForColumn:@"created_at"];
            [results addObject:entry];
        }
    }];
    NSMutableArray<QLabel *> *labels = [NSMutableArray new];
    [results enumerateObjectsUsingBlock:^(_LabelResultSetEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.label setAccount:[QAccountStore accountForIdentifier:obj.accountId]];
        [obj.label setRepository:[QRepositoryStore repositoryForAccountId:obj.accountId identifier:obj.repositoryId]];
        [labels addObject:obj.label];
    }];
//    DDLogDebug(@"QLabelStore labelsForAccount - returning: %@", labels);
    return labels;
}

+ (NSMutableArray<QLabel *> *)searchLabelsWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(query);
    NSParameterAssert(repositoryId);
    
    NSMutableArray<NSString *> *labelNames = [NSMutableArray new];
    NSMutableArray<_LabelResultSetEntry *> *results = [NSMutableArray new];
    [QLabelStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *searchRS = [db executeQuery:@"SELECT lsearch.name, matchinfo(label_search,'pcnalx') as relevance FROM label_search lsearch WHERE lsearch.name MATCH ? AND lsearch.account_id = ? AND lsearch.repository_id = ? ORDER BY relevance", query, accountId, repositoryId];
        while (searchRS.next) {
            [labelNames addObject:[searchRS stringForColumn:@"name"]];
            // DDLogDebug(@"Sorted: %@", [searchRS stringForColumn:@"name"]);
        }
        
        NSMutableArray *sqlArgs = [NSMutableArray new];
        NSMutableArray *questionMarks = [NSMutableArray new];
        [labelNames enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            [questionMarks addObject:@"?"];
            [sqlArgs addObject:name];
        }];
        
        [sqlArgs addObject:accountId];
        [sqlArgs addObject:repositoryId];
        
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM label l WHERE l.name in (%@) AND l.account_id = ? AND l.repository_id = ? AND l.deleted = 0", [questionMarks componentsJoinedByString:@", "]];
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:sqlArgs];
        
        while ([rs next]) {
            _LabelResultSetEntry *entry = [_LabelResultSetEntry new];
            entry.label = [QLabel new];
            entry.label.name = [rs stringForColumn:@"name"];
            entry.label.color = [rs stringForColumn:@"color"];
            entry.accountId = @([rs intForColumn:@"account_id"]);
            entry.repositoryId = @([rs intForColumn:@"repository_id"]);
            entry.label.updatedAt = [rs dateForColumn:@"updated_at"];
            entry.label.createdAt = [rs dateForColumn:@"created_at"];
            [results addObject:entry];
        }
        
    }];
    
    NSMutableArray<QLabel *> *labels = [NSMutableArray new];
    [results enumerateObjectsUsingBlock:^(_LabelResultSetEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.label setAccount:[QAccountStore accountForIdentifier:obj.accountId]];
        [obj.label setRepository:[QRepositoryStore repositoryForAccountId:obj.accountId identifier:obj.repositoryId]];
        [labels addObject:obj.label];
        //  DDLogDebug(@"Unsorted: %@", obj.label.name);
    }];
    
    [labels sortUsingComparator:^NSComparisonResult(QLabel * label1, QLabel * label2) {
        NSUInteger index1 = [labelNames indexOfObject:label1.name];
        NSUInteger index2 = [labelNames indexOfObject:label2.name];
        return [@(index1) compare:@(index2)];
    }];
    
    return labels;
}

+ (NSMutableArray<QLabel *> *)searchLabelsWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(query);
    
    NSMutableArray<_LabelResultSetEntry *> *results = [NSMutableArray new];
    [QLabelStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM label_search lsearch INNER JOIN label l ON l.account_id = lsearch.account_id AND l.repository_id = lsearch.repository_id AND l.name LIKE lsearch.name WHERE lsearch.name  MATCH ? AND l.account_id = ?", query, accountId];
        while ([rs next]) {
            _LabelResultSetEntry *entry = [_LabelResultSetEntry new];
            entry.label = [QLabel new];
            entry.label.name = [rs stringForColumn:@"name"];
            entry.label.color = [rs stringForColumn:@"color"];
            entry.accountId = @([rs intForColumn:@"account_id"]);
            entry.repositoryId = @([rs intForColumn:@"repository_id"]);
            entry.label.updatedAt = [rs dateForColumn:@"updated_at"];
            entry.label.createdAt = [rs dateForColumn:@"created_at"];
            [results addObject:entry];
        }
        
    }];
    
    NSMutableArray<QLabel *> *labels = [NSMutableArray new];
    [results enumerateObjectsUsingBlock:^(_LabelResultSetEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.label setAccount:[QAccountStore accountForIdentifier:obj.accountId]];
        [obj.label setRepository:[QRepositoryStore repositoryForAccountId:obj.accountId identifier:obj.repositoryId]];
        [labels addObject:obj.label];
    }];
    
    return labels;
}

+ (NSMutableArray<QLabel *> *)labelsWithNames:(NSArray<NSString *> *)names forAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(names.count > 0);
    
    NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
    NSMutableArray *args = [NSMutableArray new];
    [names enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
        [args addObject:obj];
    }];
    
    NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM label WHERE name in %@ AND account_id = ?", questionMarksString];
    [args addObject:accountId];
    
    
    NSMutableArray<_LabelResultSetEntry *> *results = [NSMutableArray new];
    [QLabelStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            _LabelResultSetEntry *entry = [_LabelResultSetEntry new];
            entry.label = [QLabel new];
            entry.label.name = [rs stringForColumn:@"name"];
            entry.label.color = [rs stringForColumn:@"color"];
            entry.accountId = @([rs intForColumn:@"account_id"]);
            entry.repositoryId = @([rs intForColumn:@"repository_id"]);
            entry.label.updatedAt = [rs dateForColumn:@"updated_at"];
            entry.label.createdAt = [rs dateForColumn:@"created_at"];
            [results addObject:entry];
        }
        
    }];
    
    NSMutableArray<QLabel *> *labels = [NSMutableArray new];
    [results enumerateObjectsUsingBlock:^(_LabelResultSetEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.label setAccount:[QAccountStore accountForIdentifier:obj.accountId]];
        [obj.label setRepository:[QRepositoryStore repositoryForAccountId:obj.accountId identifier:obj.repositoryId]];
        [labels addObject:obj.label];
    }];
    
    return labels;
}

+ (void)deleteLabel:(QLabel *)label;
{
    NSParameterAssert(label.name);
    NSParameterAssert(label.repository.identifier);
    NSParameterAssert(label.repository.account.identifier);
    
    [QLabelStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM label WHERE account_id = ? AND name = ? AND repository_id = ?",label.repository.account.identifier, label.name, label.repository.identifier];
        NSParameterAssert(success);
    }];
}

+ (void)hideLabel:(QLabel *)label;
{
    NSParameterAssert(label.name);
    NSParameterAssert(label.repository.identifier);
    NSParameterAssert(label.repository.account.identifier);
    
    [QLabelStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"UPDATE label SET deleted = 1 WHERE account_id = ? AND name = ? AND repository_id = ?",label.repository.account.identifier, label.name, label.repository.identifier];
        NSParameterAssert(success);
    }];
}

+ (BOOL)isHiddenLabelName:(NSString *)name accountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId
{
    NSParameterAssert(name);
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    
    __block BOOL hidden = true;
    
    [QLabelStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM label WHERE account_id = ? AND name LIKE ? AND repository_id = ? AND DELETED = 0",  accountId, name, repositoryId];
        
        if ([rs next]) {
            hidden = false;
        }
        [rs close];
    }];
    
    return hidden;
}

+ (void)unhideLabelsNotInLabelSet:(NSSet<QLabel *> *)labelSet accountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId
{
    if (labelSet.count == 0) {
        return;
    }
    NSMutableArray *sqlArgs = [NSMutableArray new];
    NSMutableArray *questionMarks = [NSMutableArray new];
    [labelSet enumerateObjectsUsingBlock:^(QLabel * _Nonnull label, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
        [sqlArgs addObject:label.name];
    }];
    
    [sqlArgs addObject:accountId];
    [sqlArgs addObject:repositoryId];
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE label SET deleted = 0 WHERE name NOT IN (%@) AND account_id = ?  AND repository_id = ?", [questionMarks componentsJoinedByString:@", "]];
    [QLabelStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:sql withArgumentsInArray:sqlArgs];
        NSParameterAssert(success);
    }];
}

+ (QLabel *)labelWithName:(NSString *)name forRepository:(QRepository *)repo account:(QAccount *)account
{
    NSParameterAssert(name);
    NSParameterAssert(repo.identifier);
    NSParameterAssert(account.identifier);
    
    NSString *labelCacheKey = [SRLabelCache LabelCacheKeyForAccountId:account.identifier repositoryId: repo.identifier name: name];
    
    return [[SRLabelCache sharedCache] fetch:labelCacheKey fetcher:^QLabel *{
        __block QLabel *label = nil;
        
        [QLabelStore doReadInTransaction:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM label WHERE account_id = ? AND name LIKE ? AND repository_id = ?", account.identifier, name, repo.identifier];
            
            if ([rs next]) {
                label = [QLabel new];
                label.name = [rs stringForColumn:@"name"];
                label.color = [rs stringForColumn:@"color"];
                label.repository = repo;
                label.account = account;
                label.updatedAt = [rs dateForColumn:@"updated_at"];
                label.createdAt = [rs dateForColumn:@"created_at"];
            }
            [rs close];
        }];
        
        return label;
    }];
}

+ (NSString *)_mapKeyForIssueAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueId:(NSNumber *)issueId
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueId);
    return [NSString stringWithFormat:@"%@_%@_%@", accountId, repositoryId, issueId];
}

@end
