//
//  QIssueEventStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/26/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
//#import "Cashew-Swift.h"

@class QIssueEvent;

@interface QIssueEventStore : QBaseStore

+ (void)saveIssueEvent:(QIssueEvent *)issueEvent;

+ (NSArray<QIssueEvent *> *)issueEventsForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId issueNumber:(NSNumber *)issueNumber skipEvents:(NSArray<NSString *> *)events;

@end
