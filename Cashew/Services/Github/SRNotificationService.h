//
//  SRNotificationService.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/19/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "QBaseService.h"

@class QIssue;

@interface SRNotificationService : QBaseService

// GET /notifications
- (void)notificationsSinceDate:(NSDate *)sinceDate pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;

// PATCH /notifications/threads/:id
- (void)markNotificationAsReadForIssue:(QIssue *)issue onCompletion:(QServiceOnCompletion)onCompletion;

@end
