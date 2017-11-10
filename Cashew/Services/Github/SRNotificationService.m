//
//  SRNotificationService.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/19/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRNotificationService.h"
#import "QIssuesService.h"
#import "QIssue.h"

@implementation SRNotificationService

+ (NSDateFormatter *)_githubDateFormatter
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    });
    return formatter;
}


// GET /notifications
- (void)notificationsSinceDate:(NSDate *)sinceDate pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    
    NSMutableDictionary *params =  @{@"all":@YES, @"page": @(pageNumber), @"per_page": @(pageSize)}.mutableCopy;
    
//    if (sinceDate) {
//        params[@"since"] = [[SRNotificationService _githubDateFormatter] stringFromDate:sinceDate];
//    }
    
    if (sinceDate) {
        NSString *lastModified = [[QAFHTTPSessionManager lastModifiedDateFormatter] stringFromDate:sinceDate];
        [manager.requestSerializer setValue:lastModified forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    [manager GET:@"notifications"
      parameters:params progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              //DDLogDebug(@"issue notifications responseObject -> %@", responseObject);
              onCompletion(responseObject, context, nil);
          }
      }];
}

// PATCH /notifications/threads/:id
- (void)markNotificationAsReadForIssue:(QIssue *)issue onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(issue.notification.threadId);
    
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    
    //NSDictionary *params =  @{};
    
    [manager PATCH:[NSString stringWithFormat:@"notifications/threads/%@", issue.notification.threadId]
        parameters:nil
      onCompletion:^(id responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              //DDLogDebug(@"issue notifications responseObject -> %@", responseObject);
              onCompletion(responseObject, context, nil);
          }
      }];
}

@end
