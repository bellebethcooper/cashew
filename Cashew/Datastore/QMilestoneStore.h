//
//  QMilestoneStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
#import "QMilestone.h"

@interface QMilestoneStore : QBaseStore

+ (void)saveMilestone:(QMilestone *)milestone;

+ (NSArray<QMilestone *> *)milestonesForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId includeHidden:(BOOL)includeHidden;

+ (NSArray<QMilestone *> *)openMilestonesForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;

+ (QMilestone *)milestoneForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId identifier:(NSNumber *)identifier;
+ (NSMutableArray<QMilestone *> *)milestonesForAccountId:(NSNumber *)accountId;
+ (NSArray<QMilestone *> *)searchMilestoneWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId;
+ (NSArray<QMilestone *> *)searchMilestoneWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
+ (NSArray<QMilestone *> *)milestonesWithTitle:(NSArray<NSString *> *)titles forAccountId:(NSNumber *)accountId;
+ (void)deleteMilestone:(QMilestone *)milestone;
+ (void)hideMilestone:(QMilestone *)milestone;
+ (void)unhideMilestonesNotInMilestoneSet:(NSSet<QMilestone *> *)milestoneSet forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;

@end
