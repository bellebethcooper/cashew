//
//  QLabelStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
#import "QLabel.h"
#import "QIssue.h"

@interface QLabelStore : QBaseStore

+ (void)saveLabel:(QLabel *)label allowUpdate:(BOOL)allowUpdate;
+ (void)saveIssueLabels:(NSArray<QLabel *> *)labels forIssue:(QIssue *)issue;
+ (void)loadLabelsForIssues:(NSArray<QIssue *> *)issues;
+ (QLabel *)labelWithName:(NSString *)name forRepository:(QRepository *)repo account:(QAccount *)account;
+ (NSMutableArray<QLabel *> *)labelsForAccountId:(NSNumber *)accountId;
+ (NSArray<QLabel *> *)labelsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId includeHidden:(BOOL)includeHidden;
+ (NSMutableArray<QLabel *> *)searchLabelsWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId;
+ (NSMutableArray<QLabel *> *)searchLabelsWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
+ (NSMutableArray<QLabel *> *)labelsWithNames:(NSArray<NSString *> *)names forAccountId:(NSNumber *)accountId;
+ (void)deleteLabel:(QLabel *)label;
+ (void)hideLabel:(QLabel *)label;
+ (void)unhideLabelsNotInLabelSet:(NSSet<QLabel *> *)labelSet accountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
+ (BOOL)isHiddenLabelName:(NSString *)name accountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;

@end