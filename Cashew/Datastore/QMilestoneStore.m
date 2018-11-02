//
//  QMilestoneStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QMilestoneStore.h"
#import "QIssueConstants.h"
#import "QAccountStore.h"
#import "QOwnerStore.h"
#import "QRepositoryStore.h"
#import "Cashew-Swift.h"

@interface _MilestoneResultSetEntry : NSObject

@property (nonatomic) QMilestone *milestone;
@property (nonatomic) NSNumber *accountId;
@property (nonatomic) NSNumber *creatorId;
@property (nonatomic) NSNumber *repositoryId;

@end

@implementation _MilestoneResultSetEntry

@end

@implementation QMilestoneStore


+ (void)saveMilestone:(QMilestone *)milestone;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(milestone);
    NSParameterAssert(milestone.identifier);
    NSParameterAssert(milestone.repository);
    NSParameterAssert(milestone.account);
    NSParameterAssert(milestone.creator);
    
    NSNumber *state = nil;
    if ([@"open" isEqualToString:milestone.state]) {
        state  = @(IssueStoreIssueState_Open);
    } else if ([@"closed" isEqualToString:milestone.state]) {
        state  = @(IssueStoreIssueState_Closed);
    }
    
    NSString *cacheKey = [SRMilestoneCache MilestoneCacheKeyForAccountId:milestone.account.identifier repositoryId:milestone.repository.identifier milestoneId:milestone.identifier];
    [[SRMilestoneCache sharedCache] removeObjectForKey:cacheKey];
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    
    
    [QMilestoneStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT updated_at, title FROM milestone WHERE account_id = ? AND identifier = ? AND repository_id = ?",
                           milestone.account.identifier ?:[NSNull null], milestone.identifier ?:[NSNull null], milestone.repository.identifier ?:[NSNull null]];
        
        if ([rs next]) {
            
            NSDate *currentDate = [rs dateForColumn:@"updated_at"];
            NSString *currentTitle = [rs stringForColumn:@"title"];
            if ([milestone.updatedAt compare:currentDate] != NSOrderedDescending && [milestone.title isEqualToString:currentTitle]) {
                [rs close];
                return;
            }
            
            BOOL success = [db executeUpdate:@"UPDATE milestone SET title = ?, description = ?, creator_id = ?, number = ?, state = ?, created_at = ?, closed_at = ?, due_on = ?, updated_at = ? WHERE account_id = ? AND identifier = ? AND repository_id = ?",
                            milestone.title ?:[NSNull null],
                            milestone.desc ?:[NSNull null],
                            milestone.creator.identifier ?:[NSNull null],
                            milestone.number ?:[NSNull null],
                            state ?:[NSNull null],
                            milestone.createdAt ?:[NSNull null],
                            milestone.closedAt ?:[NSNull null],
                            milestone.dueOn ?:[NSNull null],
                            milestone.updatedAt ?:[NSNull null],
                            milestone.account.identifier ?:[NSNull null],
                            milestone.identifier ?:[NSNull null],
                            milestone.repository.identifier ?:[NSNull null]];
            NSParameterAssert(success);
            
            success = [db executeUpdate:@"UPDATE milestone_search SET title = ? WHERE account_id = ? AND identifier = ? AND repository_id = ?",
                       milestone.title ?:[NSNull null],
                       milestone.account.identifier ?:[NSNull null],
                       milestone.identifier ?:[NSNull null],
                       milestone.repository.identifier  ?:[NSNull null]];
            NSParameterAssert(success);
            
            dbOperation = QBaseDatabaseOperation_Update;
            
        } else {
            BOOL success = [db executeUpdate:@"INSERT INTO milestone (title, description, creator_id, number, state, created_at, closed_at, due_on, updated_at, account_id, identifier, repository_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            milestone.title ?:[NSNull null],
                            milestone.desc ?:[NSNull null],
                            milestone.creator.identifier ?:[NSNull null],
                            milestone.number ?:[NSNull null],
                            state ?:[NSNull null],
                            milestone.createdAt ?:[NSNull null],
                            milestone.closedAt ?:[NSNull null],
                            milestone.dueOn ?:[NSNull null],
                            milestone.updatedAt ?:[NSNull null],
                            milestone.account.identifier ?:[NSNull null],
                            milestone.identifier ?:[NSNull null],
                            milestone.repository.identifier ?:[NSNull null]];
            NSParameterAssert(success);
            success = [db executeUpdate:@"INSERT INTO milestone_search (title, account_id, identifier, repository_id) VALUES (?, ?, ?, ?)",
                       milestone.title ?:[NSNull null],
                       milestone.account.identifier ?:[NSNull null],
                       milestone.identifier ?:[NSNull null],
                       milestone.repository.identifier ?:[NSNull null]];
            NSParameterAssert(success);
            
            dbOperation = QBaseDatabaseOperation_Insert;
            
        }
        
        [rs close];
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [QMilestoneStore notifyInsertObserversForStore:QMilestoneStore.class record:milestone];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [QMilestoneStore notifyUpdateObserversForStore:QMilestoneStore.class record:milestone];
    }
}


+ (void)deleteMilestone:(QMilestone *)milestone
{
    NSParameterAssert(milestone);
    NSParameterAssert(milestone.repository.identifier);
    NSParameterAssert(milestone.account.identifier);
    
    NSString *cacheKey = [SRMilestoneCache MilestoneCacheKeyForAccountId:milestone.account.identifier repositoryId:milestone.repository.identifier milestoneId:milestone.identifier];
    [[SRMilestoneCache sharedCache] removeObjectForKey:cacheKey];
    
    [QMilestoneStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM milestone WHERE account_id = ? AND identifier = ? AND repository_id = ?", milestone.account.identifier, milestone.identifier, milestone.repository.identifier];
        NSParameterAssert(success);
    }];
    
    [QMilestoneStore notifyDeletionObserversForStore:QMilestoneStore.class record:milestone];
}

+ (void)hideMilestone:(QMilestone *)milestone
{
    NSParameterAssert(milestone);
    NSParameterAssert(milestone.repository.identifier);
    NSParameterAssert(milestone.account.identifier);
    
    NSString *cacheKey = [SRMilestoneCache MilestoneCacheKeyForAccountId:milestone.account.identifier repositoryId:milestone.repository.identifier milestoneId:milestone.identifier];
    [[SRMilestoneCache sharedCache] removeObjectForKey:cacheKey];
    __block BOOL alreadyHidden = false;
    
    [QMilestoneStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT DELETED FROM milestone WHERE account_id = ? AND identifier = ? AND repository_id = ?", milestone.account.identifier, milestone.identifier, milestone.repository.identifier];
        
        if ([rs next]) {
            alreadyHidden = [rs intForColumn:@"DELETED"] == 1;
            [rs close];
        }
        
        if (!alreadyHidden) {
            BOOL success = [db executeUpdate:@"UPDATE milestone SET DELETED = 1 WHERE account_id = ? AND identifier = ? AND repository_id = ?", milestone.account.identifier, milestone.identifier, milestone.repository.identifier];
            NSParameterAssert(success);
        }
    }];
    
    if (!alreadyHidden) {
        [QMilestoneStore notifyDeletionObserversForStore:QMilestoneStore.class record:milestone];
    }
}

+ (void)unhideMilestonesNotInMilestoneSet:(NSSet<QMilestone *> *)milestoneSet forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId
{
    if (milestoneSet.count == 0) {
        return;
    }
    NSMutableArray *sqlArgs = [NSMutableArray new];
    NSMutableArray *questionMarks = [NSMutableArray new];
    [milestoneSet enumerateObjectsUsingBlock:^(QMilestone * _Nonnull milestone, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
        [sqlArgs addObject:milestone.identifier];
    }];
    
    [sqlArgs addObject:accountId];
    [sqlArgs addObject:repositoryId];
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE milestone SET deleted = 0 WHERE identifier NOT IN (%@) AND account_id = ? AND repository_id = ?", [questionMarks componentsJoinedByString:@", "]];
    [QLabelStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:sql withArgumentsInArray:sqlArgs];
        NSParameterAssert(success);
    }];
}

+ (QMilestone *)milestoneForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId identifier:(NSNumber *)identifier;
{
    NSParameterAssert(accountId);
    NSParameterAssert(identifier);
    NSParameterAssert(repositoryId);
    
    NSString *cacheKey = [SRMilestoneCache MilestoneCacheKeyForAccountId:accountId repositoryId:repositoryId milestoneId:identifier];
    QMilestone *milestone = [[SRMilestoneCache sharedCache] fetch:cacheKey fetcher:^QMilestone *{
        __block _MilestoneResultSetEntry *entry = nil;
        [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM milestone WHERE account_id = ? AND identifier = ? AND repository_id = ?", accountId, identifier, repositoryId];
            
            if ([rs next]) {
                entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
            }
            [rs close];
        }];
        
        QMilestone *milestone = nil;
        if (entry) {
            milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
        }
        return milestone;
    }];
    
    return milestone;
}

//+ (NSArray<QMilestone *> *)milestoneForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId includeHidden:(BOOL)includeHidden;
//{
//    NSParameterAssert(accountId);
//    NSParameterAssert(repositoryId);
//
//    __block NSMutableArray<_MilestoneResultSetEntry *> *entries = [NSMutableArray new];
//    [QMilestoneStore doInTransaction:^(FMDatabase *db, BOOL *rollback) {
//        FMResultSet *rs = [db executeQuery:@"SELECT * FROM milestone WHERE account_id = ? AND repository_id = ?", accountId, repositoryId];
//
//        while ([rs next]) {
//            _MilestoneResultSetEntry *entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
//            [entries addObject:entry];
//        }
//        [rs close];
//    }];
//
//
//    NSMutableArray<QMilestone *> *milestones = [NSMutableArray new];
//    [entries enumerateObjectsUsingBlock:^(_MilestoneResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
//        QMilestone *milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
//        [milestones addObject:milestone];
//
//    }];
//
//    return milestones;
//}
//


+ (NSMutableArray<QMilestone *> *)milestonesForAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    
    __block NSMutableArray<_MilestoneResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM milestone WHERE account_id = ? ORDER BY title", accountId];
        
        while ([rs next]) {
            _MilestoneResultSetEntry *entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    
    NSMutableArray<QMilestone *> *milestones = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_MilestoneResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QMilestone *milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
        [milestones addObject:milestone];
        
    }];
    
    return milestones;
}

+ (NSArray<QMilestone *> *)milestonesForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId includeHidden:(BOOL)includeHidden;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    
    __block NSMutableArray<_MilestoneResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM milestone WHERE account_id = ? AND repository_id = ? AND deleted in (?,?) ORDER BY title", accountId, repositoryId, @0, includeHidden ? @1 : @0];
        
        while ([rs next]) {
            _MilestoneResultSetEntry *entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    
    NSMutableArray<QMilestone *> *milestones = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_MilestoneResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QMilestone *milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
        [milestones addObject:milestone];
        
    }];
    
    return milestones;
}

+ (NSArray<QMilestone *> *)openMilestonesForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    
    __block NSMutableArray<_MilestoneResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM milestone WHERE account_id = ? AND repository_id = ? AND deleted = ? AND closed_at is null ORDER BY title", accountId, repositoryId, @0];
        
        while ([rs next]) {
            _MilestoneResultSetEntry *entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    
    NSMutableArray<QMilestone *> *milestones = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_MilestoneResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QMilestone *milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
        [milestones addObject:milestone];
        
    }];
    
    return milestones;
}

+ (NSArray<QMilestone *> *)searchMilestoneWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(query);
    
    __block NSMutableArray<_MilestoneResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT m.* FROM milestone_search ms INNER JOIN milestone m ON ms.account_id = m.account_id AND ms.repository_id = m.repository_id AND m.identifier = ms.identifier WHERE ms.account_id = ? AND ms.title MATCH ? AND m.repository_id = ? AND m.deleted = 0", accountId, query, repositoryId];
        
        while ([rs next]) {
            _MilestoneResultSetEntry *entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    
    NSMutableArray<QMilestone *> *milestones = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_MilestoneResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QMilestone *milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
        [milestones addObject:milestone];
        
    }];
    
    return milestones;
}

+ (NSArray<QMilestone *> *)searchMilestoneWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(query);
    
    __block NSMutableArray<_MilestoneResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT m.* FROM milestone_search ms INNER JOIN milestone m ON ms.account_id = m.account_id AND ms.repository_id = m.repository_id AND m.identifier = ms.identifier WHERE ms.account_id = ? AND ms.title MATCH ?", accountId, query];
        
        while ([rs next]) {
            _MilestoneResultSetEntry *entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    
    NSMutableArray<QMilestone *> *milestones = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_MilestoneResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QMilestone *milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
        [milestones addObject:milestone];
        
    }];
    
    return milestones;
}

+ (NSArray<QMilestone *> *)milestonesWithTitle:(NSArray<NSString *> *)titles forAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(titles && titles.count > 0);
    
    NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
    NSMutableArray *args = [NSMutableArray new];
    [titles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
        [args addObject:obj];
    }];
    
    NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM milestone WHERE title in %@ AND account_id = ?", questionMarksString];
    [args addObject:accountId];
    
    __block NSMutableArray<_MilestoneResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        
        while ([rs next]) {
            _MilestoneResultSetEntry *entry = [QMilestoneStore _milestoneResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        
        [rs close];
    }];
    
    
    NSMutableArray<QMilestone *> *milestones = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_MilestoneResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QMilestone *milestone = [QMilestoneStore _milestoneFromResultSetEntry:entry];
        [milestones addObject:milestone];
        
    }];
    
    return milestones;
}

#pragma mark - helpers

+ (QMilestone *)_milestoneFromResultSetEntry:(_MilestoneResultSetEntry *)entry {
    
    QMilestone *milestone = entry.milestone;
    milestone.account = [QAccountStore accountForIdentifier:entry.accountId];
    milestone.creator = [QOwnerStore ownerForAccountId:entry.accountId identifier:entry.creatorId];
    milestone.repository = [QRepositoryStore repositoryForAccountId:entry.accountId identifier:entry.repositoryId];
    return milestone;
}

+ (_MilestoneResultSetEntry *)_milestoneResultSetEntryFromResultSet:(FMResultSet *)rs
{
    QMilestone *milestone = [QMilestone new];
    
    milestone.createdAt = [rs dateForColumn:@"created_at"];
    if ([rs columnIsNull:@"closed_at"]) {
        milestone.closedAt = [rs dateForColumn:@"closed_at"];
    }
    milestone.updatedAt = [rs dateForColumn:@"updated_at"];
    
    if (![rs columnIsNull:@"due_on"]) {
        milestone.dueOn = [rs dateForColumn:@"due_on"];
    }
    milestone.identifier = @([rs intForColumn:@"identifier"]);
    milestone.title = [rs stringForColumn:@"title"];
    milestone.desc = [rs stringForColumn:@"description"];
    milestone.number = @([rs intForColumn:@"number"]);
    
    NSInteger state = [rs intForColumn:@"state"];
    if (state == IssueStoreIssueState_Open) {
        milestone.state = @"open";
    } else if (state == IssueStoreIssueState_Closed) {
        milestone.state = @"closed";
    }
    
    _MilestoneResultSetEntry *entry = [_MilestoneResultSetEntry new];
    
    entry.milestone = milestone;
    entry.creatorId = @([rs intForColumn:@"creator_id"]);
    entry.accountId = @([rs intForColumn:@"account_id"]);
    entry.repositoryId = @([rs intForColumn:@"repository_id"]);
    
    
    return entry;
}

@end
