//
//  QOwnerStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QOwnerStore.h"
#import "QOwnerConstants.h"
#import "QAccountStore.h"
#import "Cashew-Swift.h"

@interface _OwnerResultSetEntry : NSObject
@property (nonatomic, strong) QOwner *owner;
@property (nonatomic, strong) NSNumber *accountId;
@end

@implementation _OwnerResultSetEntry

@end

@implementation QOwnerStore

+ (void)saveOwner:(QOwner *)owner;
{
    //NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(owner);
    NSParameterAssert(owner.account);
    NSParameterAssert(owner.account.identifier);
    QAccount *account = owner.account;
    
    NSParameterAssert([owner.type isEqualToString:@"User"] || [owner.type isEqualToString:@"Organization"]);
    
    NSString *cacheKey = [SROwnerCache OwnerCacheKeyForAccountId:owner.account.identifier ownerId:owner.identifier];
    [[SROwnerCache sharedCache] removeObjectForKey:cacheKey];
    
    NSNumber *ownerType = nil;
    if ([owner.type isEqualToString:@"User"]) {
        ownerType = @(OwnerStoreType_User);
    } else if ([owner.type isEqualToString:@"Organization"]) {
        ownerType = @(OwnerStoreType_Organization);
    }
    
    [QOwnerStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM owner WHERE account_id = ? AND identifier = ?",
                           account.identifier ?:[NSNull null], owner.identifier ?:[NSNull null]];
        
        if ([rs next]) {
            BOOL success = [db executeUpdate:@"UPDATE owner SET avatar_url = ?, html_url = ? WHERE account_id = ? AND identifier = ?",
                            owner.avatarURL.absoluteString ?:[NSNull null], owner.htmlURL.absoluteString ?:[NSNull null], account.identifier ?:[NSNull null], owner.identifier ?:[NSNull null]];
            NSParameterAssert(success);
            
        } else {
            BOOL success = [db executeUpdate:@"INSERT INTO owner (account_id, identifier, avatar_url, login, type, html_url) VALUES (?, ?, ?, ?, ?, ?)",
                            account.identifier ?:[NSNull null],
                            owner.identifier ?:[NSNull null],
                            owner.avatarURL.absoluteString ?:[NSNull null],
                            owner.login, ownerType ?:[NSNull null],
                            owner.htmlURL.absoluteString ?:[NSNull null]];
            NSParameterAssert(success);
            
            success = [db executeUpdate:@"INSERT INTO owner_search (identifier, account_id, login) VALUES (?, ?, ?)",
                       owner.identifier ?:[NSNull null],
                       owner.account.identifier ?:[NSNull null],
                       owner.login ?:[NSNull null]];
            NSParameterAssert(success);
        }
        
        [rs close];
    }];
}

+ (void)deleteOwner:(QOwner *)owner;
{
    NSParameterAssert(owner.login);
    NSParameterAssert(owner.account.identifier);
    
    NSString *cacheKey = [SROwnerCache OwnerCacheKeyForAccountId:owner.account.identifier ownerId:owner.identifier];
    [[SROwnerCache sharedCache] removeObjectForKey:cacheKey];

    [QOwnerStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM owner WHERE account_id = ? AND login = ?", owner.account.identifier, owner.login];
        NSParameterAssert(success);
    }];
}

+ (QOwner *)ownerForAccountId:(NSNumber *)accountId login:(NSString *)login;
{
    NSParameterAssert(accountId);
    NSParameterAssert(login);
    
    __block _OwnerResultSetEntry *entry;
    
    [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM owner WHERE account_id = ? AND login = ?", accountId, login];
        if ([rs next] ) {
            entry = [QOwnerStore _ownerFromResultSet:rs];
        }
        [rs close];
    }];
    
    QOwner *owner = nil;
    
    if (entry) {
        owner = [QOwnerStore _ownerFromOwnerResultSetEntry:entry];
    }
    
    return owner;
}

+ (QOwner *)ownerForAccountId:(NSNumber *)accountId identifier:(NSNumber *)identifier;
{
    NSParameterAssert(accountId);
    NSParameterAssert(identifier);
    
    NSString *cacheKey = [SROwnerCache OwnerCacheKeyForAccountId:accountId ownerId:identifier];
    QOwner *owner = [[SROwnerCache sharedCache] fetch:cacheKey fetcher:^QOwner *{
        
        __block _OwnerResultSetEntry *entry;
        
        [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM owner WHERE account_id = ? AND identifier = ?", accountId, identifier];
            if ([rs next] ) {
                entry = [QOwnerStore _ownerFromResultSet:rs];
            }
            [rs close];
        }];
        
        QOwner *owner = nil;
        
        if (entry) {
            owner = [QOwnerStore _ownerFromOwnerResultSetEntry:entry];
        }
        
        return owner;
    }];

    
    return owner;
}


+ (NSArray<QOwner *> *)ownersWithLogins:(NSArray<NSString *> *)logins forAccountId:(NSNumber *)accountId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(logins && logins.count > 0 );
    
    NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
    NSMutableArray *args = [NSMutableArray new];
    [logins enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
        [args addObject:obj];
    }];
    
    NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM owner where login in %@ AND account_id = ?", questionMarksString];
    [args addObject:accountId];
    
    NSMutableArray<_OwnerResultSetEntry *> *entries = [NSMutableArray new];
    [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        
        while (rs.next) {
            _OwnerResultSetEntry *entry = [QOwnerStore _ownerFromResultSet:rs];
            [entries addObject:entry];
        }
        
        [rs close];
    }];
    
    NSMutableArray<QOwner *> *owners = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_OwnerResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        [owners addObject:[QOwnerStore _ownerFromOwnerResultSetEntry:entry]];
    }];
    
    return owners;
}


+ (BOOL)isCollaboratorUserId:(NSNumber *)userId forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(userId);
    NSParameterAssert(repositoryId);
    
    __block BOOL collaborator = false;
    [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT o.* FROM owner o INNER JOIN repository_assignee ra where ra.account_id = ? AND ra.repository_id = ? AND o.account_id = ra.account_id AND o.identifier = ra.owner_id AND ra.owner_id = ?", accountId, repositoryId, userId];
        if (rs.next) {
            collaborator = true;
        }
        [rs close];
    }];
    
    return collaborator;
}


+ (NSArray<QOwner *> *)ownersForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);

    NSMutableArray<_OwnerResultSetEntry *> *entries = [NSMutableArray new];
    [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT o.* FROM owner o INNER JOIN repository_assignee ra where ra.account_id = ? AND ra.repository_id = ? AND o.account_id = ra.account_id AND o.identifier = ra.owner_id", accountId, repositoryId];
        
        while (rs.next) {
            _OwnerResultSetEntry *entry = [QOwnerStore _ownerFromResultSet:rs];
            [entries addObject:entry];
        }
        
        [rs close];
    }];
    
    NSMutableArray<QOwner *> *owners = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_OwnerResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        [owners addObject:[QOwnerStore _ownerFromOwnerResultSetEntry:entry]];
    }];
    
    return owners;
}

+ (NSArray<QOwner *> *)ownersForAccountId:(NSNumber *)accountId
{
    NSParameterAssert(accountId);
    
    NSMutableArray<_OwnerResultSetEntry *> *entries = [NSMutableArray new];
    [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT o.* FROM owner o WHERE o.account_id = ? GROUP BY login ORDER BY login ASC", accountId];
        
        while (rs.next) {
            _OwnerResultSetEntry *entry = [QOwnerStore _ownerFromResultSet:rs];
            [entries addObject:entry];
        }
        
        [rs close];
    }];
    
    NSMutableArray<QOwner *> *owners = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_OwnerResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        [owners addObject:[QOwnerStore _ownerFromOwnerResultSetEntry:entry]];
    }];
    
    return owners;
}

+ (NSArray<QOwner *> *)searchUserWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId
{
    NSParameterAssert(accountId);
    NSParameterAssert(query);
    
    NSMutableArray<_OwnerResultSetEntry *> *entries = [NSMutableArray new];
    NSMutableArray<NSString *> *logins = [NSMutableArray new];
    [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *searchRS = [db executeQuery:@"SELECT os.login, matchinfo(owner_search,'pcnalx') as relevance FROM owner_search os WHERE os.login MATCH ? AND os.account_id = ? ORDER BY relevance LIMIT 30",
                                 query, accountId];
        while (searchRS.next) {
            [logins addObject:[searchRS stringForColumn:@"login"]];
        }
        
        NSMutableArray *sqlArgs = [NSMutableArray new];
        NSMutableArray *questionMarks = [NSMutableArray new];
        [logins enumerateObjectsUsingBlock:^(NSString * _Nonnull login, NSUInteger idx, BOOL * _Nonnull stop) {
            [questionMarks addObject:@"?"];
            [sqlArgs addObject:login];
        }];
        
        [sqlArgs addObject:@(OwnerStoreType_User)];
        [sqlArgs addObject:accountId];
        
        
        NSString *sql = [NSString stringWithFormat:@"SELECT o.* FROM owner o WHERE o.login in ( %@ ) and o.type = ? AND o.account_id = ?", [questionMarks componentsJoinedByString:@", "]];
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:sqlArgs];
        
        while (rs.next) {
            _OwnerResultSetEntry *entry = [QOwnerStore _ownerFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    NSMutableArray<QOwner *> *owners = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_OwnerResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        [owners addObject:[QOwnerStore _ownerFromOwnerResultSetEntry:entry]];
    }];
    
    
    [owners sortUsingComparator:^NSComparisonResult(QOwner * user1, QOwner * user2) {
        NSUInteger index1 = [logins indexOfObject:user1.login];
        NSUInteger index2 = [logins indexOfObject:user2.login];
        return [@(index1) compare:@(index2)];
    }];
    
    return owners;
}


+ (NSArray<QOwner *> *)searchUserWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
{
    NSParameterAssert(accountId);
    NSParameterAssert(query);
    NSParameterAssert(repositoryId);
    
    NSMutableArray<_OwnerResultSetEntry *> *entries = [NSMutableArray new];
    NSMutableArray<NSString *> *logins = [NSMutableArray new];
    [QOwnerStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *searchRS = [db executeQuery:@"SELECT os.login, matchinfo(owner_search,'pcnalx') as relevance FROM owner_search os INNER JOIN repository_assignee ra WHERE os.login MATCH ? AND os.account_id = ? AND ra.account_id = os.account_id AND ra.account_id = os.account_id AND ra.repository_id = ? AND ra.owner_id = os.identifier ORDER BY relevance LIMIT 30",
                                 query, accountId, repositoryId];
        while (searchRS.next) {
            [logins addObject:[searchRS stringForColumn:@"login"]];
        }
        
        NSMutableArray *sqlArgs = [NSMutableArray new];
        NSMutableArray *questionMarks = [NSMutableArray new];
        [logins enumerateObjectsUsingBlock:^(NSString * _Nonnull login, NSUInteger idx, BOOL * _Nonnull stop) {
            [questionMarks addObject:@"?"];
            [sqlArgs addObject:login];
        }];
        
        [sqlArgs addObject:@(OwnerStoreType_User)];
        [sqlArgs addObject:accountId];
        
        
        NSString *sql = [NSString stringWithFormat:@"SELECT o.* FROM owner o WHERE o.login in ( %@ ) and o.type = ? AND o.account_id = ?", [questionMarks componentsJoinedByString:@", "]];
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:sqlArgs];
        
        while (rs.next) {
            _OwnerResultSetEntry *entry = [QOwnerStore _ownerFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    NSMutableArray<QOwner *> *owners = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_OwnerResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        [owners addObject:[QOwnerStore _ownerFromOwnerResultSetEntry:entry]];
    }];
    
    
    [owners sortUsingComparator:^NSComparisonResult(QOwner * user1, QOwner * user2) {
        NSUInteger index1 = [logins indexOfObject:user1.login];
        NSUInteger index2 = [logins indexOfObject:user2.login];
        return [@(index1) compare:@(index2)];
    }];
    
    return owners;
}


#pragma mark - Adaptors

+ (QOwner *)_ownerFromOwnerResultSetEntry:(_OwnerResultSetEntry *)entry
{
    QOwner *owner = entry.owner;
    owner.account = [QAccountStore accountForIdentifier:entry.accountId];
    return owner;
}

+ (_OwnerResultSetEntry *)_ownerFromResultSet:(FMResultSet *)rs
{
    _OwnerResultSetEntry *entry = [_OwnerResultSetEntry new];
    QOwner *owner = [QOwner new];
    
    owner.login = [rs stringForColumn:@"login"];
    owner.avatarURL = [NSURL URLWithString:[rs stringForColumn:@"avatar_url"]];
    owner.htmlURL = [NSURL URLWithString:[rs stringForColumn:@"html_url"]];
    NSInteger type = [rs intForColumn:@"type"];
    if (type == OwnerStoreType_Organization) {
        [owner setType:@"Organization"];
    } else if (type == OwnerStoreType_User) {
        [owner setType:@"User"];
    }
    owner.identifier = @([rs intForColumn:@"identifier"]);
    
    entry.owner = owner;
    entry.accountId = @([rs intForColumn:@"account_id"]);
    return entry;
    
}

@end
