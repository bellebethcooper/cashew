//
//  QRepositoryStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QRepositoryStore.h"
#import "QOwnerStore.h"
#import "QAccountStore.h"
#import "Cashew-Swift.h"

@interface _RepoResultSetEntry : NSObject
@property (nonatomic, strong) QRepository *repository;
@property (nonatomic, strong) NSNumber *accountId;
@property (nonatomic, strong) NSNumber *ownerId;
@end

@implementation _RepoResultSetEntry

@end


@implementation QRepositoryStore

+ (void)saveDeltaSyncDate:(NSDate *)date forRepository:(QRepository *)repo;
{
    NSParameterAssert(repo.identifier);
    NSParameterAssert(date);
    
    NSString *cacheKey = [SRRepositoryCache RepositoryCacheKeyForAccountId:repo.account.identifier repositoryId:repo.identifier];
    [[SRRepositoryCache sharedCache] removeObjectForKey:cacheKey];
    
    //+ (QRepository *)repositoryForAccountId:(NSNumber *)accountId identifier:(NSNumber *)identifier;
//    QRepository *currentRepo = 
    
    //DDLogDebug(@"Save Delta Sync Date for Repository [%@] with date [%@] vs repo_date [%@]", repo.fullName, date, repo.deltaSyncDate);
    [QRepositoryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        //NSString *dateString = [[QRepositoryStore _deltaSyncDateFormatter] stringFromDate:date];
        FMResultSet *rs = [db executeQuery:@"SELECT delta_sync_date FROM repository WHERE account_id = ? AND identifier = ?", repo.account.identifier, repo.identifier];
        NSDate *currentDeltaSyncDate = nil;
        if ([rs next]) {
            currentDeltaSyncDate = [rs dateForColumn:@"delta_sync_date"];
            
            [rs close];
        }
        
        if (!currentDeltaSyncDate || [date isAfterDate:currentDeltaSyncDate]) {
            BOOL success = [db executeUpdate:@"UPDATE repository SET delta_sync_date = ? WHERE account_id = ? AND identifier = ?", date, repo.account.identifier, repo.identifier];
            NSParameterAssert(success);
        }
        
//        BOOL success = [db executeUpdate:@"UPDATE repository SET delta_sync_date = ? WHERE account_id = ? AND identifier = ? AND (delta_sync_date < ? || delta_sync_date is null)", date, repo.account.identifier, repo.identifier, @(date.timeIntervalSince1970)];
//        NSParameterAssert(success);
    }];
}

+ (void)markAsCompletedSyncForRepository:(QRepository *)repo
{
    NSParameterAssert(repo.identifier);
    
    NSString *cacheKey = [SRRepositoryCache RepositoryCacheKeyForAccountId:repo.account.identifier repositoryId:repo.identifier];
    [[SRRepositoryCache sharedCache] removeObjectForKey:cacheKey];
    
    
    [QRepositoryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"UPDATE repository SET initial_sync_completed = ? WHERE account_id = ? AND identifier = ?", @YES, repo.account.identifier, repo.identifier];
        NSParameterAssert(success);
    }];
}


+ (void)deleteAssignee:(QOwner *)assignee forRepository:(QRepository *)repo;
{
    NSParameterAssert(assignee.identifier);
    NSParameterAssert(repo.account.identifier);
    NSParameterAssert(repo.identifier);
    
    [QRepositoryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM repository_assignee WHERE account_id = ? AND repository_id = ? AND owner_id = ?", repo.account.identifier, repo.identifier, assignee.identifier];
        NSParameterAssert(success);
    }];
}

+ (void)saveAssignee:(QOwner *)assignee forRepository:(QRepository *)repo;
{
    NSParameterAssert(assignee.identifier);
    NSParameterAssert(repo.account.identifier);
    NSParameterAssert(repo.identifier);
    
    [QOwnerStore saveOwner:assignee];
    
    [QRepositoryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM repository_assignee WHERE account_id = ? AND repository_id = ? AND owner_id = ?", repo.account.identifier ?: [NSNull null], repo.identifier ?: [NSNull null], assignee.identifier ?: [NSNull null]];
        
        if (![rs next]) {
            BOOL success = [db executeUpdate:@"INSERT INTO repository_assignee (account_id, repository_id, owner_id) VALUES (?, ?, ?)",
                            repo.account.identifier ?: [NSNull null], repo.identifier ?: [NSNull null], assignee.identifier ?: [NSNull null]];
            
            NSParameterAssert(success);
        }
        
        [rs close];
    }];
}

+ (void)saveRepository:(QRepository *)repo;
{
    //NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(repo);
    NSParameterAssert(repo.owner);
    
    [QOwnerStore saveOwner:repo.owner];
    
    NSString *cacheKey = [SRRepositoryCache RepositoryCacheKeyForAccountId:repo.account.identifier repositoryId:repo.identifier];
    [[SRRepositoryCache sharedCache] removeObjectForKey:cacheKey];
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    [QRepositoryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM repository WHERE account_id = ? AND identifier = ?", repo.account.identifier ?:[NSNull null], repo.identifier ?:[NSNull null]];
        
        if ([rs next]) {
            [rs close];
            //NSLog(@"saving repo -> %@ with external id -> %@", repo.fullName, repo.externalId);
            BOOL success = [db executeUpdate:@"UPDATE repository_search SET name = ?, full_name = ? WHERE account_id = ? AND identifier = ?",
                            repo.name ?:[NSNull null],
                            repo.fullName ?:[NSNull null],
                           // repo.owner.identifier ?:[NSNull null],
                            repo.account.identifier ?:[NSNull null],
                            repo.identifier ?:[NSNull null]];
            NSParameterAssert(success);
            
            success = [db executeUpdate:@"UPDATE repository SET updated_at = ?, external_id = ? WHERE account_id = ? AND identifier = ?",
                       repo.updatedAt ?: [NSNull null],
                       repo.externalId ?: [NSNull null],
                       repo.account.identifier ?:[NSNull null],
                       repo.identifier ?:[NSNull null]];
//            NSLog(@"name=%@ fullName=%@ desc=%@ ownerId=%@ updatedAt=%@ externalId=%@ accountId=%@ identifer=%@", repo.name ?:[NSNull null],
//                  repo.fullName ?:[NSNull null],
//                  repo.desc ?:[NSNull null],
//                  repo.owner.identifier ?:[NSNull null],
//                  repo.updatedAt ?: [NSNull null],
//                  repo.externalId ?: [NSNull null],
//                  repo.account.identifier ?:[NSNull null],
//                  repo.identifier ?:[NSNull null]);
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Update;
        } else {
            BOOL success = [db executeUpdate:@"INSERT INTO repository (description, account_id, name, full_name, identifier, owner_id, updated_at, external_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                            repo.desc ?:[NSNull null], repo.account.identifier ?:[NSNull null], repo.name ?:[NSNull null], repo.fullName ?:[NSNull null], repo.identifier ?:[NSNull null], repo.owner.identifier ?:[NSNull null],
                            repo.updatedAt ?: [NSNull null], repo.externalId ?: [NSNull null]];
            
            NSParameterAssert(success);
            
            success = [db executeUpdate:@"INSERT INTO repository_search (identifier, account_id, name, full_name) VALUES (?, ?, ?, ?)",
                       repo.identifier ?:[NSNull null], repo.account.identifier ?:[NSNull null], repo.name ?:[NSNull null], repo.fullName ?:[NSNull null]];
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Insert;
            
        }
        
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [QRepositoryStore notifyInsertObserversForStore:QRepositoryStore.class record:repo];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [QRepositoryStore notifyUpdateObserversForStore:QRepositoryStore.class record:repo];
    }
}

+ (NSArray<QRepository *> *)repositoriesForAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSMutableArray *repos = [NSMutableArray new];
    
    NSMutableArray<_RepoResultSetEntry *> *entries = [NSMutableArray new];
    [QRepositoryStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM repository WHERE account_id = ? ORDER BY full_name", accountId];
        
        while (rs.next) {
            [entries addObject:[QRepositoryStore _repositoryResultSetEntryFromResultSet:rs]];
        }
        [rs close];
    }];
    
    [entries enumerateObjectsUsingBlock:^(_RepoResultSetEntry *entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QRepository *repo = [QRepositoryStore _repositoriesFromResultSetEntry:entry];
        [repos addObject:repo];
    }];
    
    return repos;
}

+ (QRepository *)repositoryForAccountId:(NSNumber *)accountId fullName:(NSString *)fullName;
{
    NSParameterAssert(accountId);
    NSParameterAssert(fullName);
    //NSMutableArray *repos = [NSMutableArray new];
    
    __block _RepoResultSetEntry *entry;
    [QRepositoryStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM repository WHERE account_id = ? AND full_name = ?", accountId, fullName];
        
        if (rs.next) {
            entry = [QRepositoryStore _repositoryResultSetEntryFromResultSet:rs];
        }
        [rs close];
    }];
    
    if (!entry) {
        return nil;
    }
    QRepository *repo = [QRepositoryStore _repositoriesFromResultSetEntry:entry];
    
    return repo;
}

+ (QRepository *)repositoryForAccountId:(NSNumber *)accountId ownerLogin:(NSString *)ownerLogin repositoryName:(NSString *)repositoryName;
{
    NSParameterAssert(accountId);
    NSParameterAssert(ownerLogin);
    NSParameterAssert(repositoryName);
    return [QRepositoryStore repositoryForAccountId:accountId fullName:[NSString stringWithFormat:@"%@/%@", ownerLogin, repositoryName]];
}


+ (QRepository *)repositoryForAccountId:(NSNumber *)accountId identifier:(NSNumber *)identifier;
{
    NSParameterAssert(accountId);
    NSParameterAssert(identifier);
    
    
    NSString *cacheKey = [SRRepositoryCache RepositoryCacheKeyForAccountId:accountId repositoryId:identifier];
    QRepository *repo = [[SRRepositoryCache sharedCache] fetch:cacheKey fetcher:^QRepository *{
        __block _RepoResultSetEntry *entry;
        [QRepositoryStore doReadInTransaction:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM repository WHERE account_id = ? AND identifier = ?", accountId, identifier];
            
            if (rs.next) {
                entry = [QRepositoryStore _repositoryResultSetEntryFromResultSet:rs];
            }
            [rs close];
        }];
        
        if (!entry) {
            return nil;
        }
        QRepository *repo = [QRepositoryStore _repositoriesFromResultSetEntry:entry];
        return repo;
    }];
    

    return repo;
}

+ (NSArray<QRepository *> *)searchRepositoriesWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(query);
    
    NSMutableArray *repos = [NSMutableArray new];
    
    NSMutableArray<_RepoResultSetEntry *> *entries = [NSMutableArray new];
    [QRepositoryStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT r.* FROM repository r INNER JOIN repository_search rs WHERE rs.account_id = r.account_id AND rs.identifier = r.identifier AND rs.account_id = ? AND rs.name MATCH ? ", accountId, query];
        
        while (rs.next) {
            [entries addObject:[QRepositoryStore _repositoryResultSetEntryFromResultSet:rs]];
        }
        [rs close];
    }];
    
    [entries enumerateObjectsUsingBlock:^(_RepoResultSetEntry *entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QRepository *repo = [QRepositoryStore _repositoriesFromResultSetEntry:entry];
        [repos addObject:repo];
    }];
    
    return repos;
}

+ (NSArray<QRepository *> *)repositoriesWithTitle:(NSArray<NSString *> *)titles forAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(titles && titles.count > 0);
    
    NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
    NSMutableArray *args = [NSMutableArray new];
    [titles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
        [args addObject:obj];
    }];
    
    [titles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       // [questionMarks addObject:@"?"];
        [args addObject:obj];
    }];
    
    
    NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM repository WHERE (full_name in %@ OR name in %@) AND account_id = ?", questionMarksString, questionMarksString];
    [args addObject:accountId];
    
    
    NSMutableArray *repos = [NSMutableArray new];
    
    NSMutableArray<_RepoResultSetEntry *> *entries = [NSMutableArray new];
    [QRepositoryStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        
        while (rs.next) {
            [entries addObject:[QRepositoryStore _repositoryResultSetEntryFromResultSet:rs]];
        }
        [rs close];
    }];
    
    [entries enumerateObjectsUsingBlock:^(_RepoResultSetEntry *entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QRepository *repo = [QRepositoryStore _repositoriesFromResultSetEntry:entry];
        [repos addObject:repo];
    }];

    return repos;
}

+ (void)deleteRepository:(QRepository *)repository;
{
    NSString *cacheKey = [SRRepositoryCache RepositoryCacheKeyForAccountId:repository.account.identifier repositoryId:repository.identifier];
    [[SRRepositoryCache sharedCache] removeObjectForKey:cacheKey];
    
    [QRepositoryStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        if (![db executeUpdate:@"DELETE FROM issue WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_comment WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        if (![db executeUpdate:@"DELETE FROM issue_search WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        if (![db executeUpdate:@"DELETE FROM label WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        if (![db executeUpdate:@"DELETE FROM label_search WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        if (![db executeUpdate:@"DELETE FROM milestone WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        if (![db executeUpdate:@"DELETE FROM milestone_search WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        //        if (![db executeUpdate:@"DELETE FROM owner WHERE account_id = ?", repository.identifier]) {
        //            *rollback = YES;
        //            return;
        //        }
        //        if (![db executeUpdate:@"DELETE FROM owner_search WHERE account_id = ?", repository.identifier]) {
        //            *rollback = YES;
        //            return;
        //        }
        if (![db executeUpdate:@"DELETE FROM repository WHERE identifier = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        if (![db executeUpdate:@"DELETE FROM repository_search WHERE identifier = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_label WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_event WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_comment WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM repository_assignee WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_comment_draft WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_notification WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }
        
        if (![db executeUpdate:@"DELETE FROM issue_favorite WHERE repository_id = ? AND account_id = ?", repository.identifier, repository.account.identifier]) {
            *rollback = YES;
            return;
        }

    }];
    [QRepositoryStore notifyDeletionObserversForStore:QRepositoryStore.class record:repository];
}

+ (BOOL)isDeletedRepository:(QRepository *)repository;
{
    __block BOOL isDeleted = false;
    
    [QRepositoryStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * from repository WHERE account_id = ? AND identifier = ?", repository.account.identifier, repository.identifier];
        isDeleted = ![rs next];
        [rs close];
    }];
    
    return isDeleted;
}

#pragma mark - Adaptors
+ (QRepository *)_repositoriesFromResultSetEntry:(_RepoResultSetEntry *)entry
{
    QRepository *repo = entry.repository;
    if (repo) {
        repo.account = [QAccountStore accountForIdentifier:entry.accountId];
        repo.owner = [QOwnerStore ownerForAccountId:entry.accountId identifier:entry.ownerId];
    }
    return repo;
}

+ (_RepoResultSetEntry *)_repositoryResultSetEntryFromResultSet:(FMResultSet *)rs
{
    QRepository *repo = [QRepository new];

    repo.name = [rs stringForColumn:@"name"];
    repo.fullName = [rs stringForColumn:@"full_name"];
    repo.identifier = @([rs intForColumn:@"identifier"]);
    repo.desc = [rs stringForColumn:@"description"];
    repo.externalId = [rs stringForColumn:@"external_id"];
    repo.updatedAt = [rs dateForColumn:@"updated_at"];
    
    if ([rs columnIsNull:@"initial_sync_completed"] == NO) {
        repo.initialSyncCompleted = [rs boolForColumn:@"initial_sync_completed"];
    } else {
        repo.initialSyncCompleted = NO;
    }
    
    if ([rs columnIsNull:@"delta_sync_date"] == NO) {
        repo.deltaSyncDate = [rs dateForColumn:@"delta_sync_date"];
    }
    
    _RepoResultSetEntry *entry = [_RepoResultSetEntry new];
    entry.repository = repo;
    entry.accountId = @([rs intForColumn:@"account_id"]);
    entry.ownerId = @([rs intForColumn:@"owner_id"]);
    
    return entry;
}


@end
