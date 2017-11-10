//
//  SRIssueCommentReactionStore.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "QBaseStore.h"
#import "SRIssueCommentReaction.h"

@class QIssueComment;

@interface SRIssueCommentReactionStore : QBaseStore

+ (void)saveIssueCommentReaction:(SRIssueCommentReaction *)issueCommentReaction;
+ (void)deleteIssueCommentReaction:(SRIssueCommentReaction *)issueCommentReaction;
+ (NSArray<SRIssueCommentReaction *> *)issueCommentReactionsForIssueComment:(QIssueComment *)issueComment;
+ (SRIssueCommentReaction *)didUserId:(NSNumber *)userId addReactionToIssueComment:(QIssueComment *)issue withContent:(NSString *)content;


@end
