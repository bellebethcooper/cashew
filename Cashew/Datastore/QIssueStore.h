//
//  QIssueStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
#import "QIssue.h"
#import "QPagination.h"
#import "QIssueFilter.h"

@interface QIssueStore : QBaseStore

+ (void)saveIssue:(QIssue *)issue;
+ (QIssue *)mostRecentUpdatedIssueForRepository:(QRepository *)repository;
+ (NSArray<QIssue *> *)issuesWithFilter:(QIssueFilter *)filter pagination:(QPagination *)aPagination;
+ (NSInteger)countForIssuesWithFilter:(QIssueFilter *)filter;
+ (NSIndexSet *)issuesIdsForRepository:(QRepository *)repository;
+ (QIssue *)issueWithNumber:(NSNumber *)number forRepository:(QRepository *)repository;
+ (BOOL)areTheseOwnerLogins:(NSArray<NSString *> *)ownerLogins mentionedInIssue:(QIssue *)issue;
+ (NSArray<QIssue *> *)issuesWithNumbers:(NSArray<NSNumber *> *)numbers forRepository:(QRepository *)repository;
+ (void)updateIssueReactionCountsForIssue:(QIssue *)issue;

@end
