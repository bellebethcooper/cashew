//
//  QIssueEventStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/26/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueEventStore.h"
#import "QMilestoneStore.h"
#import "QLabelStore.h"
#import "QAccountStore.h"
#import "Cashew-Swift.h"

@interface _IssueEventResultSetEntry : NSObject

@property (nonatomic) QIssueEvent *issueEvent;
@property (nonatomic) NSNumber *accountId;
@property (nonatomic) NSNumber *repositoryId;
@property (nonatomic) NSNumber *actorId;
@property (nonatomic) NSNumber *assigneeId;
@property (nonatomic) NSString *milestoneName;
@property (nonatomic) NSString *labelName;


@end

@implementation _IssueEventResultSetEntry

@end

@implementation QIssueEventStore


+ (void)saveIssueEvent:(QIssueEvent *)issueEvent;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(issueEvent.account);
    NSParameterAssert(issueEvent.repository);
    NSParameterAssert(issueEvent.identifier);
    NSParameterAssert(issueEvent.actor);
    NSParameterAssert(issueEvent.issueNumber);
    
    // save users
    [QOwnerStore saveOwner:issueEvent.actor];
    if (issueEvent.assignee) {
        [QOwnerStore saveOwner:issueEvent.assignee];
    }
    
    
    // milestone
    if (issueEvent.milestone && issueEvent.milestone.identifier) {
        [QMilestoneStore saveMilestone:issueEvent.milestone];
    }
    
    // label
    if (issueEvent.label) {
        [QLabelStore saveLabel:issueEvent.label allowUpdate:NO];
    }
    
    
    // save issue event
    __block BOOL didInsert = false;
    [QIssueEventStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue_event WHERE account_id = ? AND identifier = ? AND repository_id = ? AND issue_number = ?",
                           issueEvent.account.identifier ?:[NSNull null],
                           issueEvent.identifier ?:[NSNull null],
                           issueEvent.repository.identifier ?:[NSNull null],
                           issueEvent.issueNumber ?:[NSNull null]];
        
        if (![rs next]) {
            [rs close];
            BOOL success = [db executeUpdate:@"INSERT INTO issue_event (identifier, repository_id, issue_number, created_at, actor_id, assignee_id, account_id, event, commit_id, label_name, milestone_title, rename_from, rename_to) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            issueEvent.identifier ?:[NSNull null],
                            issueEvent.repository.identifier ?:[NSNull null],
                            issueEvent.issueNumber ?:[NSNull null],
                            issueEvent.createdAt ?:[NSNull null],
                            issueEvent.actor.identifier ?:[NSNull null],
                            issueEvent.assignee.identifier ?:[NSNull null],
                            issueEvent.account.identifier ?:[NSNull null],
                            issueEvent.event ?: [NSNull null],
                            issueEvent.commitId ?: [NSNull null],
                            issueEvent.label.name ?: [NSNull null],
                            issueEvent.milestone.title ?: [NSNull null],
                            issueEvent.renameFrom ?: [NSNull null],
                            issueEvent.renameTo ?: [NSNull null]
                            ];
            didInsert = true;
            NSParameterAssert(success);
 
        } else {
            [rs close];
        }
        
    }];
    
    if (didInsert) {
        [QIssueEventStore notifyInsertObserversForStore:QIssueEventStore.class record:issueEvent];
    }
    
}


+ (NSMutableArray<QIssueEvent *> *)issueEventsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber skipEvents:(NSArray<NSString *> *)events;
{
    NSParameterAssert(accountId);
    NSParameterAssert(repositoryId);
    NSParameterAssert(issueNumber);
    
    NSMutableArray *questionMarks = [NSMutableArray new];
    [events enumerateObjectsUsingBlock:^(NSString * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
    }];
    
    __block NSMutableArray<_IssueEventResultSetEntry *> *entries = [NSMutableArray new];
    [QMilestoneStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = nil;
        
        if (questionMarks.count > 0) {
            NSMutableArray *args = [NSMutableArray arrayWithArray:events];
            [args addObject:accountId];
            [args addObject:repositoryId];
            [args addObject:issueNumber];
            
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM issue_event WHERE event not in (%@) AND account_id = ? AND repository_id = ? AND issue_number = ? ORDER BY created_at ASC", [questionMarks componentsJoinedByString:@", "]];
            rs = [db executeQuery:sql withArgumentsInArray:args];
        } else {
            rs = [db executeQuery:@"SELECT * FROM issue_event WHERE account_id = ? AND repository_id = ? AND issue_number = ? ORDER BY created_at ASC", accountId, repositoryId, issueNumber];
        }
        
        while ([rs next]) {
            _IssueEventResultSetEntry *entry = [QIssueEventStore _issueEventResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        [rs close];
    }];
    
    
    NSMutableArray<QIssueEvent *> *issueEvents = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_IssueEventResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QIssueEvent *issueEvent = [QIssueEventStore _issueEventFromResultSetEntry:entry];
        [issueEvents addObject:issueEvent];
        
    }];
    
    return issueEvents;
}

#pragma mark - helpers

+ (QIssueEvent *)_issueEventFromResultSetEntry:(_IssueEventResultSetEntry *)entry
{
    QIssueEvent *issueEvent = entry.issueEvent;
    issueEvent.account = [QAccountStore accountForIdentifier:entry.accountId];
    issueEvent.actor = [QOwnerStore ownerForAccountId:entry.accountId identifier:entry.actorId];
    issueEvent.repository = [QRepositoryStore repositoryForAccountId:entry.accountId identifier:entry.repositoryId];
    if (entry.assigneeId) {
        issueEvent.assignee = [QOwnerStore ownerForAccountId:entry.accountId identifier:entry.assigneeId];
    }
    if (entry.labelName) {
        issueEvent.label = [QLabelStore labelWithName:entry.labelName forRepository:issueEvent.repository account:issueEvent.account];
        // NSParameterAssert(issueEvent.label);
        if (!issueEvent.label) {
            issueEvent.label = [QLabel new];
            issueEvent.label.name = entry.labelName;
        }
    }
    if (entry.milestoneName) {
        issueEvent.milestone = [[QMilestoneStore milestonesWithTitle:@[entry.milestoneName] forAccountId:issueEvent.account.identifier] firstObject];
        if (!issueEvent.milestone) {
            issueEvent.milestone = [QMilestone new];
            issueEvent.milestone.title = entry.milestoneName;
        }
    }
    return issueEvent;
}

+ (_IssueEventResultSetEntry *)_issueEventResultSetEntryFromResultSet:(FMResultSet *)rs
{
    QIssueEvent *issueEvent = [QIssueEvent new];
    
    issueEvent.createdAt = [rs dateForColumn:@"created_at"];
    issueEvent.identifier = @([rs intForColumn:@"identifier"]);
    issueEvent.issueNumber = @([rs intForColumn:@"issue_number"]);
    issueEvent.event = [rs stringForColumn:@"event"];
    issueEvent.commitId = [rs stringForColumn:@"commit_id"];
    issueEvent.renameFrom = [rs stringForColumn:@"rename_from"];
    issueEvent.renameTo = [rs stringForColumn:@"rename_to"];
    
    
    _IssueEventResultSetEntry *entry = [_IssueEventResultSetEntry new];
    
    entry.issueEvent = issueEvent;
    
    
    entry.actorId = @([rs intForColumn:@"actor_id"]);
    entry.accountId = @([rs intForColumn:@"account_id"]);
    entry.repositoryId = @([rs intForColumn:@"repository_id"]);
    entry.labelName = [rs stringForColumn:@"label_name"];
    entry.milestoneName = [rs stringForColumn:@"milestone_title"];
    
    
    if (![rs columnIsNull:@"assignee_id"]) {
        entry.assigneeId = @([rs intForColumn:@"assignee_id"]);
    }
    
    
    return entry;
}


@end
