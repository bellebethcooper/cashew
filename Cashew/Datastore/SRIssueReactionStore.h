//
//  SRIssueReactionStore.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "QBaseStore.h"
#import "SRIssueReaction.h"
#import "QIssue.h"

@interface SRIssueReactionStore : QBaseStore

+ (void)saveIssueReaction:(SRIssueReaction *)issueReaction;
+ (void)deleteIssueReaction:(SRIssueReaction *)issueReaction;
+ (NSArray<SRIssueReaction *> *)issueReactionsForIssue:(QIssue *)issue;
+ (SRIssueReaction *)didUserId:(NSNumber *)userId addReactionToIssue:(QIssue *)issue withContent:(NSString *)content;

@end
