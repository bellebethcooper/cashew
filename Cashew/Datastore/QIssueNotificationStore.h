//
//  QIssueNotificationStore.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/20/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "QBaseStore.h"

@class SRIssueNotification;
@class QIssue;

@interface QIssueNotificationStore : QBaseStore

+ (void)saveIssueNotificationWithAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber threadId:(NSNumber *)threadId reason:(NSString *)reason read:(BOOL)read updatedAt:(NSDate *)updatedAt;
+ (NSDate *)notificationModifiedOnForAccountId:(NSNumber *)accountId;
+ (void)saveNotificationModifiedOnDate:(NSDate *)modifiedOn forAccountId:(NSNumber *)accountId;
+ (QIssue *)issueWithNotificationForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber;
+ (NSInteger)totalUnreadIssueNotificationsForAccountId:(NSNumber *)accountId;
+ (void)resetNotificationModifiedOnForAccountId:(NSNumber *)accountId;

@end
