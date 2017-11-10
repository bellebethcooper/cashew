//
//  QIssueCommentDraftStore.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/22/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QBaseStore.h"

@class SRIssueCommentDraft;

@interface QIssueCommentDraftStore : QBaseStore

+ (void)saveIssueCommentDraft:(SRIssueCommentDraft *)issueCommentDraft;
+ (void)deleteIssueCommentDraft:(SRIssueCommentDraft *)issueCommentDraft;
+ (NSArray<SRIssueCommentDraft *> *)issueCommentDraftsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber;
+ (NSInteger)totalIssueCommentDraftsForAccountId:(NSNumber *)identifier;

@end
