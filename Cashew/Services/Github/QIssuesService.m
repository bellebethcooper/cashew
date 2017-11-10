//
//  QIssuesService.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssuesService.h"
#import "QIssue.h"
#import "QRepositoryStore.h"
#import "Cashew-Swift.h"

@implementation QIssuesService

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


// GET /repos/:owner/:repo/issues
- (void)issuesForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize sortKey:(NSString * )sortKey ascending:(BOOL)ascending since:(nullable NSDate *)since onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository);
    NSParameterAssert(repository.identifier);
    NSParameterAssert(repository.owner.identifier);
    NSParameterAssert(pageSize > 0);
    NSParameterAssert(pageNumber > 0);
    NSParameterAssert(sortKey);
    
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    
    NSMutableDictionary *params = params = @{ @"state": @"all", @"page": @(pageNumber), @"per_page": @(pageSize), @"sort":  sortKey }.mutableCopy;;
    
    if (since) {
        params[@"since"] = [[QIssuesService _githubDateFormatter] stringFromDate:since];
    }
    
    if (ascending) {
        params[@"direction"] = @"asc";
    } else {
        params[@"direction"] = @"desc";
    }
    
    
    [[QIssuesService _githubDateFormatter] stringFromDate:since];
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@/issues", repository.owner.login, repository.name]
      parameters:params progress:nil onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              NSMutableArray *result = [NSMutableArray array];
              for (NSDictionary *json in responseObject) {
                  QIssue *issue = [QIssue fromJSON:json];
                  [issue setAccount:self.account];
                  [issue setRepository:repository];
                  [result addObject:issue];
              }
              onCompletion(result, context, nil);
          }
      }];
}


// GET /repos/:owner/:repo/issues/:number/comments
- (void)issuesCommentsForRepository:(QRepository *)repository issueNumber:(NSNumber *)issueNumber pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize since:(NSDate *)since onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository);
    NSParameterAssert(issueNumber);
    NSParameterAssert(repository.identifier);
    NSParameterAssert(repository.owner.identifier);
    NSParameterAssert(pageSize > 0);
    NSParameterAssert(pageNumber > 0);
    
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    
    NSDictionary *params = nil;
    if (since) {
        params = @{@"page": @(pageNumber), @"per_page": @(pageSize), @"since": [[QIssuesService _githubDateFormatter] stringFromDate:since]};
    } else {
        params = @{@"page": @(pageNumber), @"per_page": @(pageSize)};
    }
    
    [[QIssuesService _githubDateFormatter] stringFromDate:since];
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@/issues/%@/comments", repository.owner.login, repository.name, issueNumber]
      parameters:params progress:nil onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              NSMutableArray *result = [NSMutableArray array];
              for (NSDictionary *json in responseObject) {
                  QIssueComment *issueComment = [QIssueComment fromJSON:json];
                  [issueComment setAccount:self.account];
                  [issueComment setRepository:repository];
                  [issueComment setIssueNumber:issueNumber];
                  [result addObject:issueComment];
              }
              onCompletion(result, context, nil);
          }
      }];
}

// GET /repos/:owner/:repo/issues/:number/events
- (void)issuesEventsForRepository:(QRepository *)repository issueNumber:(NSNumber *)issueNumber pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize since:(NSDate *)since onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository);
    NSParameterAssert(issueNumber);
    NSParameterAssert(repository.identifier);
    NSParameterAssert(repository.owner.identifier);
    NSParameterAssert(pageSize > 0);
    NSParameterAssert(pageNumber > 0);
    
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    
    NSDictionary *params = nil;
    if (since) {
        params = @{@"page": @(pageNumber), @"per_page": @(pageSize), @"since": [[QIssuesService _githubDateFormatter] stringFromDate:since]};
    } else {
        params = @{@"page": @(pageNumber), @"per_page": @(pageSize)};
    }
    
    [[QIssuesService _githubDateFormatter] stringFromDate:since];
    
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@/issues/%@/events", repository.owner.login, repository.name, issueNumber]
      parameters:params progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              NSMutableArray *result = [NSMutableArray array];
              for (NSDictionary *json in responseObject) {
                  if (json[@"actor"] && json[@"actor"] != [NSNull null]) {
                      
                      if ( json[@"label"] && (![json[@"label"][@"color"] isKindOfClass:NSString.class] || ![json[@"label"][@"name"] isKindOfClass:NSString.class]) ) {
                          continue;
                      }
                      
                      QIssueEvent *issueEvent = [QIssueEvent fromJSON:json];
                      [issueEvent setAccount:self.account];
                      [issueEvent setRepository:repository];
                      [issueEvent setIssueNumber:issueNumber];
                      [result addObject:issueEvent];
                  }
              }
              onCompletion(result, context, nil);
          }
      }];
}

- (void)fetchAllIssuesEventsForRepository:(QRepository *)repository
                              issueNumber:(NSNumber *)issueNumber
                               pageNumber:(NSInteger)pageNumber
                                    since:(nullable NSDate *)since
                             onCompletion:(QServiceOnCompletion)onCompletion;
{
    [self _fetchAllIssuesEventsForRepository:repository issueNumber:issueNumber pageNumber:1 since:since issueEvents:[NSMutableArray new] onCompletion:onCompletion];
}

- (void)_fetchAllIssuesEventsForRepository:(QRepository *)repository
                               issueNumber:(NSNumber *)issueNumber
                                pageNumber:(NSInteger)pageNumber
                                     since:(nullable NSDate *)since
                               issueEvents:(NSMutableArray *)issueEvents
                              onCompletion:(QServiceOnCompletion)onCompletion;
{
    [self issuesEventsForRepository:repository issueNumber:issueNumber pageNumber:pageNumber pageSize:100 since:since onCompletion:^(NSArray *events, QServiceResponseContext *context, NSError *error) {
        if (error || !events) {
            onCompletion(issueEvents, context, error);
            return;
        }
        
        [issueEvents addObjectsFromArray:events];
        
        if (context.nextPageNumber) {
            [self _fetchAllIssuesEventsForRepository:repository issueNumber:issueNumber pageNumber:context.nextPageNumber.integerValue since:since issueEvents:issueEvents onCompletion:onCompletion];
        } else {
            onCompletion(issueEvents, context, nil);
        }
    }];
}


// POST /repos/:owner/:repo/issues/:number/comments
- (void)createCommentForRepository:(QRepository *)repository
                       issueNumber:(NSNumber *)number
                              body:(NSString *)body
                      onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository.identifier);
    NSParameterAssert(number);
    NSParameterAssert(body);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    NSString *adjustedBody = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (adjustedBody && adjustedBody.length > 0) {
        params[@"body"] = adjustedBody;
    }
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager POST:[NSString stringWithFormat:@"repos/%@/%@/issues/%@/comments", repository.owner.login, repository.name, number]
       parameters:params progress:nil onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
           if (error) {
               onCompletion(nil, context, error);
           } else {
               QIssueComment *comment = [QIssueComment fromJSON:json];
               [comment setAccount:self.account];
               [comment setRepository:repository];
               [comment setIssueNumber:number];
               
               onCompletion(comment, context, nil);
           }
       }];
}

//GET /repos/:owner/:repo/issues/:number
- (void)issueForRepository:(QRepository *)repository
               issueNumber:(NSNumber *)issueNumber
              onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(issueNumber);
    NSParameterAssert(repository);
    NSParameterAssert(onCompletion);
    
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, issueNumber]
       parameters:@{} progress:nil onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
           if (error) {
               onCompletion(nil, context, error);
           } else {
               QIssue *issue = [QIssue fromJSON:json];
               [issue setAccount:self.account];
               [issue setRepository:repository];
               
               onCompletion(issue, context, nil);
           }
       }];
}

// POST /repos/:owner/:repo/issues
- (void)createIssueForRepository:(QRepository *)repository
                           title:(NSString *)title
                            body:(NSString *)body
                        assignee:(NSString *)assignee
                       milestone:(NSNumber *)milestoneNumber
                          labels:(NSArray<NSString *> *)labels
                    onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository.identifier);
    NSParameterAssert(title);
    NSParameterAssert(onCompletion);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    //    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    //
    //    if (self.account) {
    //        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.account.username password:self.account.password];
    //    }
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"title"] = title;
    
    NSString *adjustedBody = body ?: [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (adjustedBody && adjustedBody.length > 0) {
        params[@"body"] = adjustedBody;
    }
    
    NSString *adjustedAssignee = assignee ?: [assignee stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (adjustedAssignee && adjustedAssignee.length > 0) {
        params[@"assignee"] = adjustedAssignee;
    }
    
    if (milestoneNumber) {
        params[@"milestone"] = milestoneNumber;
    }
    
    if (labels && labels.count > 0) {
        params[@"labels"] = labels;
    }
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager POST:[NSString stringWithFormat:@"repos/%@/%@/issues", repository.owner.login, repository.name]
       parameters:params progress:nil onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
           if (error) {
               onCompletion(nil, context, error);
           } else {
               QIssue *issue = [QIssue fromJSON:json];
               [issue setAccount:self.account];
               [issue setRepository:repository];
               
               onCompletion(issue, context, nil);
           }
       }];
}


// PATCH /repos/:owner/:repo/issues/:number
- (void)closeIssueForRepository:(QRepository *)repository number:(NSNumber *)number onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository.identifier);
    NSParameterAssert(number);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer] skipAuthToken:NO];
    //    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    //
    //    if (self.account) {
    //        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.account.username password:self.account.password];
    //    }
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"state"] = @"closed";
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, number]
        parameters:params
      onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QIssue *issue = [QIssue fromJSON:json];
              [issue setAccount:self.account];
              [issue setRepository:repository];
              
              onCompletion(issue, context, nil);
              
          }
      }];
}

// PATCH /repos/:owner/:repo/issues/:number
- (void)reopenIssueForRepository:(QRepository *)repository number:(NSNumber *)number onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository.identifier);
    NSParameterAssert(number);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"state"] = @"open";
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, number]
        parameters:params
      onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QIssue *issue = [QIssue fromJSON:json];
              [issue setAccount:self.account];
              [issue setRepository:repository];
              
              onCompletion(issue, context, nil);
              
          }
      }];
}

// PATCH /repos/:owner/:repo/issues/:number
- (void)saveLabels:(NSArray<NSString *> *)labels
     forRepository:(QRepository *)repository
       issueNumber:(NSNumber *)number
      onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository);
    NSParameterAssert(number);
    NSParameterAssert(onCompletion);
    NSParameterAssert(labels);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"labels"] = labels ?: [NSNull null];
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, number]
        parameters:params
      onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QIssue *issue = [QIssue fromJSON:json];
              [issue setAccount:self.account];
              [issue setRepository:repository];
              
              onCompletion(issue, context, nil);
              
          }
      }];
}

// PATCH /repos/:owner/:repo/issues/:number
- (void)saveMilestoneNumber:(NSNumber *)milestoneNumber
              forRepository:(QRepository *)repository
                     number:(NSNumber *)number
               onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository.identifier);
    NSParameterAssert(number);
    NSParameterAssert(onCompletion);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"milestone"] = milestoneNumber ?: [NSNull null];
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, number]
        parameters:params
      onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QIssue *issue = [QIssue fromJSON:json];
              [issue setAccount:self.account];
              [issue setRepository:repository];
              
              onCompletion(issue, context, nil);
          }
      }];
}

// PATCH /repos/:owner/:repo/issues/:number
- (void)saveAssigneeLogin:(NSString *)assignee
            forRepository:(QRepository *)repository
                   number:(NSNumber *)number
             onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository.identifier);
    NSParameterAssert(number);
    NSParameterAssert(onCompletion);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"assignee"] = assignee ?: [NSNull null];
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, number]
        parameters:params
      onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QIssue *issue = [QIssue fromJSON:json];
              [issue setAccount:self.account];
              [issue setRepository:repository];
              
              onCompletion(issue, context, nil);
          }
      }];
}


// PATCH /repos/:owner/:repo/issues/:number
- (void)saveIssueTitle:(NSString *)title
         forRepository:(QRepository *)repository
                number:(NSNumber *)number
          onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(title);
    NSParameterAssert(repository.identifier);
    NSParameterAssert(number);
    NSParameterAssert(onCompletion);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"title"] = title;
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, number]
        parameters:params
      onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QIssue *issue = [QIssue fromJSON:json];
              [issue setAccount:self.account];
              [issue setRepository:repository];
              
              onCompletion(issue, context, nil);
          }
      }];
}

- (void)saveIssueBody:(NSString *)body
        forRepository:(QRepository *)repository
               number:(NSNumber *)number
         onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(body);
    NSParameterAssert(repository.identifier);
    NSParameterAssert(number);
    NSParameterAssert(onCompletion);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"body"] = body;
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/%@", repository.owner.login, repository.name, number]
        parameters:params
      onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QIssue *issue = [QIssue fromJSON:json];
              [issue setAccount:self.account];
              [issue setRepository:repository];
              
              onCompletion(issue, context, nil);
          }
      }];
}

// DELETE /repos/:owner/:repo/issues/comments/:id
- (void)deleteIssueComment:(QIssueComment *)comment onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(comment.identifier);
    NSParameterAssert(comment.repository);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    [manager DELETE:[NSString stringWithFormat:@"repos/%@/%@/issues/comments/%@", comment.repository.owner.login, comment.repository.name, comment.identifier]
         parameters:nil
       onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
           onCompletion(nil, context, error);
       }];
}

// PATCH /repos/:owner/:repo/issues/comments/:id
- (void)updateCommentText:(NSString *)body
            forRepository:(QRepository *)repository
              issueNumber:(NSNumber *)issueNumber
        commentIdentifier:(NSNumber *)identifier
             onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(repository.identifier);
    NSParameterAssert(identifier);
    NSParameterAssert(body);
    NSParameterAssert(issueNumber);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    NSDictionary *params = @{ @"body": body};
    
    [[manager requestSerializer] setValue:@"application/vnd.github.squirrel-girl-preview" forHTTPHeaderField:@"Accept"];
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/issues/comments/%@", repository.owner.login, repository.name, identifier]
        parameters:params onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
            if (error) {
                onCompletion(nil, context, error);
            } else {
                QIssueComment *comment = [QIssueComment fromJSON:json];
                [comment setAccount:self.account];
                [comment setRepository:repository];
                [comment setIssueNumber:issueNumber];
                
                onCompletion(comment, context, nil);
            }
        }];
}


//PATCH /repos/:owner/:repo/milestones/:number
- (void)closeMilestone:(QMilestone *)milestone
          onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(milestone.repository.owner);
    NSParameterAssert(milestone.repository.name);
    NSParameterAssert(milestone.number);
    
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer]];
    NSDictionary *params = @{ @"state": @"closed"};
    
    [manager PATCH:[NSString stringWithFormat:@"repos/%@/%@/milestones/%@", milestone.repository.owner.login, milestone.repository.name, milestone.number]
        parameters:params onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
            if (error) {
                onCompletion(nil, context, error);
            } else {
                QMilestone *updateMilestone = [QMilestone fromJSON:json];
                
                [updateMilestone setRepository:milestone.repository];
                [updateMilestone setAccount:self.account];
                
                onCompletion(updateMilestone, context, nil);
            }
        }];
}

@end
