//
//  QIssueCommentStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
//#import "Cashew-Swift.h"

@class QIssueComment;
@class SRIssueCommentDraft;

@interface QIssueCommentStore : QBaseStore

+ (void)saveIssueComment:(QIssueComment *)issueComment;
+ (NSArray<QIssueComment *> *)issueCommentsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber;
+ (NSArray<NSNumber *> *)issueCommentIdsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber;
+ (void)deleteIssueCommentId:(NSNumber *)issueCommentId accountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
+ (QIssueComment *)issueCommentForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueCommentId:(NSNumber *)issueCommentId;
+ (void)updateIssueCommentReactionCountsForIssueComment:(QIssueComment *)issueComment;

@end
