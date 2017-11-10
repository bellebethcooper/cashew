//
//  QIssueStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueStore.h"
#import "QOwnerStore.h"
#import "QIssueConstants.h"
#import "QAccountStore.h"
#import "QRepositoryStore.h"
#import "QLabelStore.h"
#import "QMilestoneStore.h"
#import "Cashew-Swift.h"
#import "SRIssueReactionStore.h"

@interface _IssueResultSetEntry : NSObject
@property (nonatomic, strong) QIssue *issue;
@property (nonatomic, strong) NSNumber *accountId;
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, strong) NSNumber *assigneeId;
@property (nonatomic, strong) NSNumber *repositoryId;
@property (nonatomic, strong) NSNumber *milestoneId;
@property (nonatomic, strong) NSArray<NSString *> *labels;

// issue notification
//@property (nonatomic) BOOL read;
//@property (nonatomic) NSString *reason;
//@property (nonatomic) NSNumber *threadId;

@end

@implementation _IssueResultSetEntry

@end


@implementation QIssueStore

+ (NSIndexSet *)issuesIdsForRepository:(QRepository *)repository;
{
    NSParameterAssert(repository.account.identifier);
    NSParameterAssert(repository.identifier);
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    
    [QIssueStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT number FROM issue WHERE account_id = ? AND repository_id = ? ORDER BY number ASC", repository.account.identifier, repository.identifier];
        while ([rs next]) {
            NSUInteger number = [rs unsignedLongLongIntForColumn:@"number"];
            [indexSet addIndex:number];
        }
    }];
    
    return indexSet;
}


+ (void)updateIssueReactionCountsForIssue:(QIssue *)issue
{
    // should only be called after user reacts to an issue. why? cause that means we synced the reactions
    NSArray<SRIssueReaction *> *reaction = [SRIssueReactionStore issueReactionsForIssue:issue];
    issue.thumbsUpCount = 0;
    issue.thumbsDownCount = 0;
    issue.laughCount = 0;
    issue.hoorayCount = 0;
    issue.confusedCount = 0;
    issue.heartCount = 0;
    [reaction enumerateObjectsUsingBlock:^(SRIssueReaction * _Nonnull reaction, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([@"+1" isEqualToString:reaction.content]) {
            issue.thumbsUpCount += 1;
        } else if ([@"-1" isEqualToString:reaction.content]) {
            issue.thumbsDownCount += 1;
        } else if ([@"laugh" isEqualToString:reaction.content]) {
            issue.laughCount += 1;
        } else if ([@"hooray" isEqualToString:reaction.content]) {
            issue.hoorayCount += 1;
        } else if ([@"confused" isEqualToString:reaction.content]) {
            issue.confusedCount += 1;
        } else if ([@"heart" isEqualToString:reaction.content]) {
            issue.heartCount += 1;
        } else {
            NSAssert(false, @"unknown reaction");
        }
    }];
    
    [QIssueStore saveIssue:issue];
}

+ (void)saveIssue:(QIssue *)issue;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(issue.account);
    NSParameterAssert(issue.repository);
    NSParameterAssert(issue.identifier);
    NSParameterAssert(issue.user);
    
    
    // save users
    if (issue.assignee) {
        [QOwnerStore saveOwner:issue.assignee];
    }
    [QOwnerStore saveOwner:issue.user];
    
    
    // save labels
    NSMutableArray<NSString *> *labelNames = [NSMutableArray new];
    [issue.labels enumerateObjectsUsingBlock:^(QLabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        [QLabelStore saveLabel:label allowUpdate:NO];
        [labelNames addObject:label.name];
    }];
    
    [QLabelStore saveIssueLabels:issue.labels forIssue:issue];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:labelNames options:NSJSONWritingPrettyPrinted error:&error];
    NSString *labelJSON = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // save milestone
    if (issue.milestone) {
        [QMilestoneStore saveMilestone:issue.milestone];
    }
    
    // save issue
    NSNumber *state = nil;
    if ([@"open" isEqualToString:issue.state]) {
        state  = @(IssueStoreIssueState_Open);
    } else if ([@"closed" isEqualToString:issue.state]) {
        state  = @(IssueStoreIssueState_Closed);
    }
    
    NSParameterAssert(state);
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    
    [QIssueStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT updated_at, html_url FROM issue WHERE account_id = ? AND identifier = ? AND repository_id = ?",
                           issue.account.identifier ?:[NSNull null], issue.identifier ?:[NSNull null], issue.repository.identifier ?:[NSNull null]];
        
        if ([rs next]) {    
            
            BOOL success = [db executeUpdate:@"UPDATE issue SET labels = ?, html_url = ?, assignee_id = ?, body = ?, closed_at = ?, state = ?, title = ?, updated_at = ?, milestone_id = ?, thumbsup_count = ?, thumbsdown_count = ?, laugh_count = ?, hooray_count = ?, confused_count = ?, heart_count = ?, issue_type = ? WHERE account_id = ? AND identifier = ? AND repository_id = ?",
                            labelJSON,
                            issue.htmlURL.absoluteString,
                            issue.assignee.identifier ?:[NSNull null],
                            issue.body ?:[NSNull null],
                            issue.closedAt ?:[NSNull null],
                            state ?:[NSNull null],
                            issue.title ?:[NSNull null],
                            issue.updatedAt ?:[NSNull null],
                            issue.milestone.identifier ?:[NSNull null],
                            @(issue.thumbsUpCount),
                            @(issue.thumbsDownCount),
                            @(issue.laughCount),
                            @(issue.hoorayCount),
                            @(issue.confusedCount),
                            @(issue.heartCount),
                            (issue.type ?: @"issue"),
                            issue.account.identifier ?:[NSNull null],
                            issue.identifier ?: [NSNull null],
                            issue.repository.identifier ?: [NSNull null]
                            ];
            
            NSParameterAssert(success);
            
            success = [db executeUpdate:@"UPDATE issue_search SET title = ?, body = ? WHERE account_id = ? AND identifier = ? AND repository_id = ?",
                       issue.title ?:[NSNull null],
                       issue.body ?:[NSNull null],
                       issue.account.identifier ?:[NSNull null],
                       issue.identifier ?:[NSNull null],
                       issue.repository.identifier ?:[NSNull null]];
            NSParameterAssert(success);
            
            dbOperation = QBaseDatabaseOperation_Update;
            
        } else {
            
            BOOL success = [db executeUpdate:@"INSERT INTO issue (labels, html_url, account_id, assignee_id, body, closed_at, created_at ,identifier, number, state, title, updated_at, milestone_id, user_id, repository_id, thumbsup_count, thumbsdown_count, laugh_count, hooray_count, confused_count, heart_count, search_uniq_key, issue_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            labelJSON,
                            issue.htmlURL.absoluteString ?:[NSNull null],
                            issue.account.identifier ?:[NSNull null],
                            issue.assignee.identifier ?:[NSNull null],
                            issue.body ?:[NSNull null],
                            issue.closedAt ?:[NSNull null],
                            issue.createdAt ?:[NSNull null],
                            issue.identifier ?:[NSNull null],
                            issue.number ?:[NSNull null],
                            state ?:[NSNull null],
                            issue.title ?:[NSNull null],
                            issue.updatedAt ?:[NSNull null],
                            issue.milestone.identifier ?:[NSNull null] ?:[NSNull null],
                            issue.user.identifier ?:[NSNull null],
                            issue.repository.identifier  ?:[NSNull null],
                            @(issue.thumbsUpCount),
                            @(issue.thumbsDownCount),
                            @(issue.laughCount),
                            @(issue.hoorayCount),
                            @(issue.confusedCount),
                            @(issue.heartCount),
                            [NSString stringWithFormat:@"%@_%@_%@", issue.account.identifier, issue.repository.identifier, issue.identifier],
                            (issue.type ?: @"issue")];
            
            NSParameterAssert(success);
            
            success = [db executeUpdate:@"INSERT INTO issue_search (identifier, account_id, repository_id, title, body) VALUES (?, ?, ?, ?, ?)",
                       issue.identifier ?:[NSNull null],
                       issue.account.identifier ?:[NSNull null],
                       issue.repository.identifier ?:[NSNull null],
                       issue.title ?:[NSNull null],
                       issue.body ?:[NSNull null]];
            NSParameterAssert(success);
            dbOperation = QBaseDatabaseOperation_Insert;
            
        }
        
        
        [rs close];
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [QIssueStore notifyInsertObserversForStore:QIssueStore.class record:issue];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [QIssueStore notifyUpdateObserversForStore:QIssueStore.class record:issue];
    }
}

+ (QIssue *)mostRecentUpdatedIssueForRepository:(QRepository *)repository;
{
    __block _IssueResultSetEntry *entry = nil;
    [QIssueStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue WHERE account_id = ? AND repository_id = ? ORDER BY updated_at DESC limit 1",
                           repository.account.identifier ?:[NSNull null],
                           repository.identifier  ?:[NSNull null]];
        
        if ([rs next]) {
            entry = [QIssueStore _issueResultSetEntryFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    QIssue *issue = [QIssueStore _issueFromResultSetEntry:entry];
    return issue;
}

+ (QIssue *)issueWithNumber:(NSNumber *)number forRepository:(QRepository *)repository;
{
    NSParameterAssert(number);
    NSParameterAssert(repository.account.identifier);
    NSParameterAssert(repository.identifier);
    
    __block _IssueResultSetEntry *entry = nil;
    [QIssueStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM issue WHERE account_id = ? AND repository_id = ? AND number = ? limit 1",
                           repository.account.identifier ?: [NSNull null],
                           repository.identifier ?: [NSNull null],
                           number ?: [NSNull null]];
        
        if ([rs next]) {
            entry = [QIssueStore _issueResultSetEntryFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    QIssue *issue = [QIssueStore _issueFromResultSetEntry:entry];
    return issue;
}

+ (BOOL)_buildSqlQueryForIssuesWithFilter:(QIssueFilter *)filter isCountQuery:(BOOL)isCountQuery outNSMutableString:(NSMutableString **)outSQL outArgs:(NSMutableArray **)outArgs;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(filter.account);
    
    NSString *select = nil;
    
    if (filter.filterType == SRFilterType_Notifications) {
        select = isCountQuery ? @"SELECT count(*) FROM issue_notification issn INNER JOIN issue i ON i.account_id = issn.account_id AND i.repository_id = issn.repository_id AND i.number = issn.issue_number WHERE" : @"SELECT i.*, issn.read as notification_read, issn.reason as notification_reason, issn.thread_id as notification_thread_id, issn.updated_at as notification_updated_at FROM issue_notification issn INNER JOIN issue i ON i.account_id = issn.account_id AND i.repository_id = issn.repository_id AND i.number = issn.issue_number LEFT OUTER JOIN owner u ON i.account_id = u.account_id AND i.assignee_id = u.identifier WHERE";
        
    } else if (filter.filterType == SRFilterType_Favorites) {
        select = isCountQuery ? @"SELECT count(*) FROM issue_favorite ifav INNER JOIN issue i ON i.account_id = ifav.account_id AND i.repository_id = ifav.repository_id AND i.number = ifav.issue_number WHERE" : @"SELECT i.*, 1 as notification_read FROM issue_favorite ifav INNER JOIN issue i ON i.account_id = ifav.account_id AND i.repository_id = ifav.repository_id AND i.number = ifav.issue_number LEFT OUTER JOIN owner u ON i.account_id = u.account_id AND i.assignee_id = u.identifier WHERE";
        
    } else if (filter.filterType == SRFilterType_Drafts) {
        select = isCountQuery ? @"SELECT COUNT(DISTINCT (i.account_id || \"_\" || i.repository_id || \"_\" || i.number)) FROM issue_comment_draft icd INNER JOIN issue i ON i.account_id = icd.account_id AND i.repository_id = icd.repository_id AND i.number = icd.issue_number WHERE" : @"SELECT i.*, 1 as notification_read FROM issue_comment_draft icd INNER JOIN issue i ON i.account_id = icd.account_id AND i.repository_id = icd.repository_id AND i.number = icd.issue_number LEFT OUTER JOIN owner u ON i.account_id = u.account_id AND i.assignee_id = u.identifier WHERE";
        
    } else {
        select = isCountQuery ? @"SELECT count(*) FROM issue i WHERE" : @"SELECT i.*, 1 as notification_read FROM issue i LEFT OUTER JOIN owner u ON i.account_id = u.account_id AND i.assignee_id = u.identifier WHERE";
    }
    
    NSMutableString *sql = [[NSMutableString alloc] initWithString:select];
    NSMutableArray *args = [NSMutableArray new];
    BOOL didAddWhereClause = NO;
    
    
    // searh query
    NSString *query = filter.query;
    if (query.length > 0) {
        didAddWhereClause = true;
        if (![query hasSuffix:@"*"]) {
            query = [NSString stringWithFormat:@"%@*", query];
        }
        
        [sql appendString:@" i.search_uniq_key in (SELECT (account_id || \"_\" || repository_id || \"_\" || identifier) as issue_key FROM issue_search WHERE issue_search MATCH ? AND account_id  = ?)"];
        [args addObject:query];
        [args addObject:filter.account.identifier];
    }
    
    // states
    if (filter.states.count > 0) {
        if (didAddWhereClause) {
            [sql appendString:@" AND "];
        }
        
        [sql appendString:@" i.state in "];
        NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
        [filter.states enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [questionMarks addObject:@"?"];
            [args addObject:obj];
        }];
        
        NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
        
        [sql appendString:questionMarksString];
        didAddWhereClause = YES;
    }
    
    // assignee
    if (filter.assignees.count > 0) {
        
        NSMutableArray<NSString *> *assigneeStrings = [NSMutableArray new];
        [filter.assignees enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSString.class]) {
                [assigneeStrings addObject:obj];
            }
        }];
        
        NSArray<QOwner *> *assignees = assigneeStrings.count > 0 ? [QOwnerStore ownersWithLogins:assigneeStrings forAccountId:filter.account.identifier] : @[];
        if (assignees.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@"( i.assignee_id in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [assignees enumerateObjectsUsingBlock:^(QOwner * _Nonnull assignee, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:assignee.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
            if ([filter.assignees containsObject:NSNull.null]) {
                [sql appendString:@" OR i.assignee_id is null)"];
            } else {
                [sql appendString:@")"];
            }
          
        } else if ([filter.assignees containsObject:NSNull.null]) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@"(i.assignee_id is null)"];
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" i.assignee_id in (null)"];
        }
        
        didAddWhereClause = YES;
    }
    
    // -assignee
    if (filter.assigneeExcludes.count > 0) {
        NSArray<QOwner *> *assignees = [QOwnerStore ownersWithLogins:filter.assigneeExcludes.array forAccountId:filter.account.identifier];
        if (assignees.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" (i.assignee_id NOT IN "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [assignees enumerateObjectsUsingBlock:^(QOwner * _Nonnull assignee, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:assignee.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@) OR i.assignee_id is null)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" i.assignee_id NOT in (null)"];
        }
        
        didAddWhereClause = YES;
    }
    
    // author
    if (filter.authors.count > 0) {
        NSArray<QOwner *> *authors = [QOwnerStore ownersWithLogins:filter.authors.array forAccountId:filter.account.identifier];
        if (authors.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" i.user_id in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [authors enumerateObjectsUsingBlock:^(QOwner *  _Nonnull author, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:author.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" i.user_id in (null)"];
        }
        
        didAddWhereClause = YES;
    }
    
    // -author
    if (filter.authorExcludes.count > 0) {
        NSArray<QOwner *> *authors = [QOwnerStore ownersWithLogins:filter.authorExcludes.array forAccountId:filter.account.identifier];
        if (authors.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" i.user_id NOT in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [authors enumerateObjectsUsingBlock:^(QOwner *  _Nonnull author, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:author.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" i.user_id NOT in (null)"];
        }
        
        didAddWhereClause = YES;
    }
    
    // milestone
    if (filter.milestones.count > 0) {
        
        NSMutableArray<NSString *> *milestoneStrings = [NSMutableArray new];
        [filter.milestones enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSString.class]) {
                [milestoneStrings addObject:obj];
            }
        }];
        
        NSArray<QMilestone *> *milestones = milestoneStrings.count > 0 ? [QMilestoneStore milestonesWithTitle:milestoneStrings forAccountId:filter.account.identifier] : @[];
        if (milestones.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@"( i.milestone_id in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [milestones enumerateObjectsUsingBlock:^(QMilestone *  _Nonnull milestone, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:milestone.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
            
            if ([filter.milestones containsObject:NSNull.null]) {
                [sql appendString:@" OR i.milestone_id is null)"];
            } else {
                [sql appendString:@")"];
            }
            
        } else if ([filter.milestones containsObject:NSNull.null]) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" (i.milestone_id is null)"];
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" i.milestone_id in (null)"];
        }
        
        didAddWhereClause = YES;
    }
    
    // -milestone
    if (filter.milestoneExcludes.count > 0) {
        NSArray<QMilestone *> *milestones = [QMilestoneStore milestonesWithTitle:filter.milestoneExcludes.array forAccountId:filter.account.identifier];
        if (milestones.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" (i.milestone_id NOT in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [milestones enumerateObjectsUsingBlock:^(QMilestone *  _Nonnull milestone, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:milestone.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@) or i.milestone_id is null)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" i.milestone_id NOT in (null)"];
        }
        
        didAddWhereClause = YES;
    }
    
    
    // repo
    if (filter.repositories.count > 0) {
        NSArray<QRepository *> *repos = [QRepositoryStore repositoriesWithTitle:filter.repositories.array forAccountId:filter.account.identifier];
        if (repos.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" i.repository_id in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [repos enumerateObjectsUsingBlock:^(QRepository *  _Nonnull repo, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:repo.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" i.repository_id in (null)"];
            
        }
        
        didAddWhereClause = YES;
    }
    
    // -repo
    if (filter.repositorieExcludes.count > 0) {
        NSArray<QRepository *> *repos = [QRepositoryStore repositoriesWithTitle:filter.repositorieExcludes.array forAccountId:filter.account.identifier];
        if (repos.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" (i.repository_id NOT in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [repos enumerateObjectsUsingBlock:^(QRepository *  _Nonnull repo, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:repo.identifier];
            }];
            
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@) OR repository_id is null)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" i.repository_id NOT in (null)"];
            
        }
        
        didAddWhereClause = YES;
    }
    
    // issue numbers
    if (filter.issueNumbers.count > 0) {
        if (didAddWhereClause) {
            [sql appendString:@" AND "];
        }
        
        [sql appendString:@" i.number in "];
        NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
        [filter.issueNumbers enumerateObjectsUsingBlock:^(NSString *  _Nonnull issueNumber, NSUInteger idx, BOOL * _Nonnull stop) {
            [questionMarks addObject:@"?"];
            [args addObject:issueNumber];
        }];
        
        NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
        
        [sql appendString:questionMarksString];
        
        didAddWhereClause = YES;
    }
    
    // label
    if (filter.labels.count > 0) {
        
        NSMutableArray<NSString *> *labelStrings = [NSMutableArray new];
        [filter.labels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSString.class]) {
                [labelStrings addObject:obj];
            }
        }];
        
        NSArray<QLabel *> *labels = labelStrings.count > 0 ? [QLabelStore labelsWithNames:labelStrings forAccountId:filter.account.identifier] : @[];
        
        if (labels.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@"( EXISTS (SELECT * FROM issue_label il WHERE il.account_id = i.account_id AND il.issue_id = i.identifier AND il.repository_id = i.repository_id AND il.name in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [labels enumerateObjectsUsingBlock:^(QLabel *  _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:label.name];
            }];
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            [sql appendString:@")"];
            
            if ([filter.labels containsObject:NSNull.null]) {
                [sql appendString:@" OR NOT EXISTS (SELECT * FROM issue_label il WHERE il.account_id = i.account_id AND il.issue_id = i.identifier AND il.repository_id = i.repository_id) )"];
            } else {
                [sql appendString:@")"];
            }
        } else if ([filter.labels containsObject:NSNull.null]) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" NOT EXISTS (SELECT * FROM issue_label il WHERE il.account_id = i.account_id AND il.issue_id = i.identifier AND il.repository_id = i.repository_id)"];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" EXISTS (SELECT * FROM issue_label il WHERE il.account_id = i.account_id AND il.issue_id = i.identifier AND il.repository_id = i.repository_id AND il.name in (null)"];
            
        }
        didAddWhereClause = YES;
    }
    
    // -label
    if (filter.labelExcludes.count > 0) {
        NSArray<QLabel *> *labels = [QLabelStore labelsWithNames:filter.labelExcludes.array forAccountId:filter.account.identifier];
        if (labels.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" NOT EXISTS (SELECT * FROM issue_label il WHERE il.account_id = i.account_id AND il.issue_id = i.identifier AND il.repository_id = i.repository_id AND il.name in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [labels enumerateObjectsUsingBlock:^(QLabel *  _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:label.name];
            }];
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            [sql appendString:@")"];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            [sql appendString:@" NOT EXISTS (SELECT * FROM issue_label il WHERE il.account_id = i.account_id AND il.issue_id = i.identifier AND il.repository_id = i.repository_id AND il.name in (null)"];
            
        }
        didAddWhereClause = YES;
    }
    
    // mentions
    if (filter.mentions.count > 0) {
        NSArray<QOwner *> *users = [QOwnerStore ownersWithLogins:filter.mentions.array forAccountId:filter.account.identifier];
        if (users.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" EXISTS (SELECT * FROM issue_event ie WHERE ie.account_id = i.account_id AND ie.issue_number = i.number AND ie.repository_id = i.repository_id AND ie.event = 'mentioned' AND ie.actor_id in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [users enumerateObjectsUsingBlock:^(QOwner *  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:user.identifier];
            }];
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            [sql appendString:@")"];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" EXISTS (SELECT * FROM issue_event ie WHERE ie.account_id = i.account_id AND ie.issue_number = i.number AND ie.repository_id = i.repository_id AND ie.event = 'mentioned' AND ie.actor_id in (null)"];
        }
        didAddWhereClause = YES;
    }
    
    // -mentions
    if (filter.mentionExcludes.count > 0) {
        NSArray<QOwner *> *users = [QOwnerStore ownersWithLogins:filter.mentionExcludes.array forAccountId:filter.account.identifier];
        if (users.count > 0) {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" NOT EXISTS (SELECT * FROM issue_event ie WHERE ie.account_id = i.account_id AND ie.issue_number = i.number AND ie.repository_id = i.repository_id AND ie.event = 'mentioned' AND ie.actor_id in "];
            NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
            [users enumerateObjectsUsingBlock:^(QOwner *  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
                [questionMarks addObject:@"?"];
                [args addObject:user.identifier];
            }];
            NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
            
            [sql appendString:questionMarksString];
            [sql appendString:@")"];
            
        } else {
            if (didAddWhereClause) {
                [sql appendString:@" AND "];
            }
            
            [sql appendString:@" NOT EXISTS (SELECT * FROM issue_event ie WHERE ie.account_id = i.account_id AND ie.issue_number = i.number AND ie.repository_id = i.repository_id AND ie.event = 'mentioned' AND ie.actor_id in (null)"];
        }
        didAddWhereClause = YES;
    }
    
    *outSQL = sql;
    *outArgs = args;
    
    if (didAddWhereClause) {
        [sql appendString:@" AND i.account_id = ?"];
        [args addObject:filter.account.identifier];
    }
    
    return didAddWhereClause;
    
}


+ (NSInteger)countForIssuesWithFilter:(QIssueFilter *)filter;
{
    NSParameterAssert(![NSThread isMainThread]);
    // build sql query
    NSMutableString *sql = nil;
    NSMutableArray *args = nil;
    BOOL didAddWhereClause = [QIssueStore _buildSqlQueryForIssuesWithFilter:filter isCountQuery:YES outNSMutableString:&sql outArgs:&args];
    
    
    // check if anything was added
    if (!didAddWhereClause) {
        [sql appendString:@" i.account_id = ?"];
        [args addObject:filter.account.identifier];
    } else {
        [sql appendString:@" AND i.account_id = ?"];
        [args addObject:filter.account.identifier];
    }
    
    //    if (filter.filterType == SRFilterType_Drafts) {
    //        [sql appendString:@" group by i.account_id, i.repository_id, i.number"];
    //    }
    
    __block NSInteger count = 0;
    [QIssueStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        if ([rs next]) {
            count = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    
    return count;
}

+ (NSArray<QIssue *> *)issuesWithNumbers:(NSArray<NSNumber *> *)numbers forRepository:(QRepository *)repository;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(repository.account);
    NSParameterAssert(repository.fullName);
    
    if (numbers.count == 0) {
        return [NSArray new];
    }
    
    QIssueFilter *filter = [QIssueFilter new];
    filter.repositories = [NSOrderedSet orderedSetWithObject:repository.fullName];
    filter.account = repository.account;
    filter.issueNumbers = [NSOrderedSet orderedSetWithArray:numbers];
    
    return [QIssueStore issuesWithFilter:filter pagination:nil];
}

+ (NSArray<QIssue *> *)issuesWithFilter:(QIssueFilter *)filter pagination:(QPagination *)aPagination;
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(filter);
    NSParameterAssert(filter.sortKey);
    //  NSParameterAssert(aPagination);
    
    // build sql query
    NSMutableString *sql = nil;
    NSMutableArray *args = nil;
    BOOL didAddWhereClause = [QIssueStore _buildSqlQueryForIssuesWithFilter:filter isCountQuery:NO outNSMutableString:&sql outArgs:&args];
    
    
    // check if anything was added
    if (!didAddWhereClause) {
        [sql appendString:@" i.account_id = ?"];
        [args addObject:filter.account.identifier];
    } else {
        [sql appendString:@" AND i.account_id = ?"];
        [args addObject:filter.account.identifier];
    }
    
    if (filter.filterType == SRFilterType_Drafts) {
        [sql appendString:@" group by i.account_id, i.repository_id, i.number "];
    }
    
    // ORDER
    if (!filter.query)
    {
        if ([filter.sortKey isEqualToString:kQIssueAssigneeSortKey]) {
            [sql appendString:[NSString stringWithFormat:@" ORDER BY notification_read ASC, u.login %@ ", filter.ascending ? @"ASC": @"DESC"]];
        } else {
            [sql appendString:[NSString stringWithFormat:@" ORDER BY notification_read ASC, %@ %@ ", filter.sortKey, filter.ascending ? @"ASC": @"DESC"]];
        }
    }
    
    // Paging
    if (aPagination) {
        [sql appendString:@" LIMIT ? OFFSET ? "];
        [args addObject:aPagination.pageSize];
        [args addObject:aPagination.pageOffset];
    }
    
    // execute query
    NSMutableArray<_IssueResultSetEntry *> *entries = [NSMutableArray new];
    [QIssueStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        
        while ([rs next]) {
            _IssueResultSetEntry *entry = [QIssueStore _issueResultSetEntryFromResultSet:rs];
            [entries addObject:entry];
        }
        
        [rs close];
    }];
    
    //NSLog(@"sql -> %@\nargs -> %@", sql, args);
    
    NSMutableArray<QIssue *> *issues = [NSMutableArray new];
    [entries enumerateObjectsUsingBlock:^(_IssueResultSetEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        QIssue *issue = [QIssueStore _issueFromResultSetEntry:entry];
        
        // repository and account can be nil if IssueSyncer is still running and the user deletes the repository or account. need a cleaner way to handle this
        // FIXME: hicham - find a cleaner way to handle this. Maybe turn off syncer before deleting repository
        if (issue.repository && issue.account) {
            [issues addObject:issue];
        }
    }];
    
    
    return issues;
}

+ (BOOL)areTheseOwnerLogins:(NSArray<NSString *> *)ownerLogins mentionedInIssue:(QIssue *)issue
{
    if (ownerLogins.count == 0) {
        return false;
    }
    
    NSArray<QOwner *> *users = [QOwnerStore ownersWithLogins:ownerLogins forAccountId:issue.account.identifier];
    
    if (users.count == 0) {
        return false;
    }
    
    NSMutableArray<NSNumber *> *args = [NSMutableArray new];
    NSMutableArray<NSString *> *questionMarks = [NSMutableArray new];
    [users enumerateObjectsUsingBlock:^(QOwner *  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
        [questionMarks addObject:@"?"];
        [args addObject:user.identifier];
    }];
    
    NSMutableString *sql = [NSMutableString new];
    [sql appendString:@"SELECT identifier FROM issue_event ie WHERE ie.actor_id in "];
    
    NSString *questionMarksString = [NSString stringWithFormat:@"(%@)", [questionMarks componentsJoinedByString:@", "]];
    
    [sql appendString:questionMarksString];
    [sql appendString:@" AND ie.account_id = ? AND ie.issue_number = ? AND ie.repository_id = ? AND ie.event = 'mentioned' LIMIT 1"];
    [args addObject:issue.account.identifier];
    [args addObject:issue.issueNum];
    [args addObject:issue.repository.identifier];
    
    __block BOOL exists = false;
    [QIssueStore doReadInTransaction:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        
        while ([rs next]) {
            exists = true;
        }
        
        [rs close];
    }];
    
    return exists;
}

#pragma mark - Adaptors

+ (QIssue *)_issueFromResultSetEntry:(_IssueResultSetEntry *)entry
{
    QIssue *issue = nil;
    if (entry) {
        issue = entry.issue;
        issue.account = [QAccountStore accountForIdentifier:entry.accountId];
        if (entry.assigneeId) {
            issue.assignee = [QOwnerStore ownerForAccountId:entry.accountId identifier:entry.assigneeId];
        }
        issue.user = [QOwnerStore ownerForAccountId:entry.accountId identifier:entry.userId];
        issue.repository = [QRepositoryStore repositoryForAccountId:entry.accountId identifier:entry.repositoryId];
        if (entry.milestoneId) {
            issue.milestone = [QMilestoneStore milestoneForAccountId:entry.accountId repositoryId:entry.repositoryId identifier:entry.milestoneId];
        }
        
        //if (entry.labels) {
        NSMutableArray<QLabel *> *labels = [[NSMutableArray alloc] init];
        [entry.labels enumerateObjectsUsingBlock:^(NSString * _Nonnull labelName, NSUInteger idx, BOOL * _Nonnull stop) {
            if (issue.repository) { /// this can happen if user deletes repository while syncer is still running. need a better fix
                QLabel *label = [QLabelStore labelWithName:labelName forRepository:issue.repository account:issue.account];
                //NSParameterAssert(label);
                if (label) {
                    [labels addObject:label];
                }
            }
        }];
        issue.labels = labels;
        // }
    }
    return issue;
}

+ (_IssueResultSetEntry *)_issueResultSetEntryFromResultSet:(FMResultSet *)rs
{
    _IssueResultSetEntry *entry = [_IssueResultSetEntry new];
    QIssue *issue = [QIssue new];
    
    entry.issue = issue;
    entry.userId = @([rs intForColumn:@"user_id"]);
    if (![rs columnIsNull:@"assignee_id"]) {
        entry.assigneeId = @([rs intForColumn:@"assignee_id"]);
    }
    entry.repositoryId = @([rs intForColumn:@"repository_id"]);
    entry.accountId = @([rs intForColumn:@"account_id"]);
    
    if (![rs columnIsNull:@"milestone_id"]) {
        entry.milestoneId = @([rs intForColumn:@"milestone_id"]);
    }
    
    issue.body = [rs stringForColumn:@"body"];
    issue.closedAt = [rs dateForColumn:@"closed_at"];
    issue.createdAt = [rs dateForColumn:@"created_at"];
    issue.identifier = @([rs intForColumn:@"identifier"]);
    issue.number = @([rs intForColumn:@"number"]);
    //thumbsup_count = ?, thumbsdown_count = ?, laugh_count = ?, hooray_count = ?, confused_count = ?, heart_count
    issue.thumbsUpCount = [rs intForColumn:@"thumbsup_count"];
    issue.thumbsDownCount = [rs intForColumn:@"thumbsdown_count"];
    issue.laughCount = [rs intForColumn:@"laugh_count"];
    issue.hoorayCount = [rs intForColumn:@"hooray_count"];
    issue.confusedCount = [rs intForColumn:@"confused_count"];
    issue.heartCount = [rs intForColumn:@"heart_count"];
    issue.type = [rs stringForColumn:@"issue_type"] ?: @"issue";
    
    if (![rs columnIsNull:@"labels"]) {
        NSError *error;
        NSData *data = [[rs stringForColumn:@"labels"] dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (!error) {
                entry.labels = json;
            }
        }
    }
    
    if (![rs columnIsNull:@"html_url"]) {
        issue.htmlURL = [NSURL URLWithString:[rs stringForColumn:@"html_url"]];
    }
    
    NSInteger state = [rs intForColumn:@"state"];
    if (state == IssueStoreIssueState_Open) {
        issue.state = @"open";
    } else if (state == IssueStoreIssueState_Closed) {
        issue.state = @"closed";
    }
    issue.title = [rs stringForColumn:@"title"];
    issue.updatedAt = [rs dateForColumn:@"updated_at"];
    
    // issue notifications
    if ([rs hasColumnNamed:@"notification_reason"] && [rs hasColumnNamed:@"notification_thread_id"] && [rs hasColumnNamed:@"notification_read"] && [rs hasColumnNamed:@"notification_updated_at"]) {
        
        SRIssueNotification *notification = [[SRIssueNotification alloc] initWithThreadId:@([rs intForColumn:@"notification_thread_id"]) read:[rs boolForColumn:@"notification_read"] reason:[rs stringForColumn:@"notification_reason"] updatedAt:[rs dateForColumn:@"notification_updated_at"]];
        issue.notification = notification;
    }
    
    return entry;
}



@end
