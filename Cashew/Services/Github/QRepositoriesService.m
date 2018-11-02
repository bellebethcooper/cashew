//
//  QRepositoriesService.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QRepositoriesService.h"
#import "QRepository.h"
#import "QMilestone.h"
#import "QLabel.h"
#import "Cashew-Swift.h"

@implementation QRepositoriesService

// GET /user/repos
- (void)repositoriesForCurrentUserWithPageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSMutableOrderedSet *repositories = [NSMutableOrderedSet new];
    [self _repositoriesForCurrentUserWithPageNumber:pageNumber pageSize:pageSize repositories:repositories onCompletion:onCompletion];
}

- (void)_repositoriesForCurrentUserWithPageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize repositories:(NSMutableOrderedSet *)repositories onCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:@"user/repos"
      parameters:@{@"page": @(pageNumber), @"per_page": @(pageSize)} progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              for (NSDictionary *json in responseObject) {
                  QRepository *repo = [QRepository fromJSON:json];
                  repo.account = self.account;
                  [repositories addObject:repo];
              }
              
              if (context.nextPageNumber && context.nextPageNumber.integerValue <= 3) {
                  // DDLogDebug(@"default next repositories = %@ for page = %@", @(repositories.count), context.nextPageNumber);
                  [self _repositoriesForCurrentUserWithPageNumber:context.nextPageNumber.integerValue pageSize:pageSize repositories:repositories onCompletion:onCompletion];
              } else {
                  // DDLogDebug(@"default repositories = %@", @(repositories.count));
                  onCompletion(repositories.array, context, nil);
              }
          }
      }];
}

// GET /repos/:owner/:repo
- (void)repositoryForOwnerLogin:(NSString *)login repositoryName:(NSString *)repositoryName onCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@", login, repositoryName]
      parameters:nil progress:nil  onCompletion:^(NSDictionary *responseObject, QServiceResponseContext *context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              QRepository *repo = [QRepository fromJSON:responseObject];
              repo.account = self.account;
              onCompletion(repo, context, nil);
          }
      }];
}



// GET /repos/:owner/:repo/milestones
- (void)milestonesForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@/milestones", repository.owner.login, repository.name]
      parameters:@{@"page": @(pageNumber), @"per_page": @(pageSize), @"state": @"all"} progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              DDLogDebug(@"QRepositoriesService milestonesForRepo - results: %@", responseObject);
              NSMutableArray *result = [NSMutableArray array];
              for (NSDictionary *json in responseObject) {
                  QMilestone *milestone = [QMilestone fromJSON:json];
                  milestone.account = self.account;
                  milestone.repository = repository;
                  [result addObject:milestone];
              }
              
              onCompletion(result, context, nil);
          }
      }];
}

// GET /repos/:owner/:repo/labels
- (void)labelsForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@/labels", repository.owner.login, repository.name]
      parameters:@{@"page": @(pageNumber), @"per_page": @(pageSize)} progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              NSMutableArray *result = [NSMutableArray array];
              for (NSDictionary *json in responseObject) {
                  QLabel *label = [QLabel fromJSON:json];
                  label.account = self.account;
                  label.repository = repository;
                  [result addObject:label];
              }
              
              onCompletion(result, context, nil);
          }
      }];
}

//GET /repos/:owner/:repo/assignees
- (void)assigneesForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:[NSString stringWithFormat:@"repos/%@/%@/assignees", repository.owner.login, repository.name]
      parameters:@{@"page": @(pageNumber), @"per_page": @(pageSize)} progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              NSMutableArray<QOwner *> *result = [NSMutableArray array];
              for (NSDictionary *json in responseObject) {
                  QOwner *owner = [QOwner fromJSON:json];
                  owner.account = self.account;
                  [result addObject:owner];
              }
              
              onCompletion(result, context, nil);
          }
      }];
}

// GET /search/repositories
- (void)searchRepositoriesWithQuery:(NSString *)query pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize contextId:(NSNumber *)contextId onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSMutableOrderedSet *repositories = [NSMutableOrderedSet new];
    
    NSString *adjustedQuery = [query trimmedString];
    if (![query containsString:@"user:"] && [query containsString:@"/"] && ![query containsString:@" "]) {
        NSArray<NSString *> *pieces = [query componentsSeparatedByString:@"/"];
        if (pieces.count == 2) {
            adjustedQuery = [NSString stringWithFormat:@"user:%@ %@", pieces[0], pieces[1]];
        }
    }
    
    [self _searchRepositoriesWithQuery:adjustedQuery pageNumber:pageNumber pageSize:pageSize contextId:contextId repositories:repositories onCompletion:onCompletion];
}

- (void)_searchRepositoriesWithQuery:(NSString *)query pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize contextId:(NSNumber *)contextId repositories:(NSMutableOrderedSet *)repos onCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:@"search/repositories"
      parameters:@{@"page": @(pageNumber), @"per_page": @(pageSize), @"q": query} progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          context.contextId = contextId;
          
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              //NSMutableArray *result = [NSMutableArray array];
              for (NSDictionary *json in [(NSDictionary *)responseObject objectForKey:@"items"]) {
                  QRepository *repo = [QRepository fromJSON:json];
                  repo.account = self.account;
                  [repos addObject:repo];
              }
              
              if (context.nextPageNumber && context.nextPageNumber.integerValue <= 1) {
                  // DDLogDebug(@"next search repositories = %@ for page = %@", @(repos.count), context.nextPageNumber);
                  [self _searchRepositoriesWithQuery:query pageNumber:context.nextPageNumber.integerValue pageSize:pageSize contextId:contextId repositories:repos onCompletion:onCompletion];
              } else {
                  // DDLogDebug(@"search repositories = %@", @(repos.count));
                  onCompletion(repos.array, context, nil);
              }
          }
      }];
}


// GET /orgs/:name/repos
- (void)repositoriesForOrganizationNamed:(NSString *)orgName onCompletion:(QServiceOnCompletion)onCompletion;
{
    NSParameterAssert(orgName);
    
    [self _repositoriesForOrganizationNamed:orgName onCompletion:onCompletion pageNumber:0 pageSize:100 repositories:[NSMutableArray new]];
}

- (void)_repositoriesForOrganizationNamed:(NSString *)orgName onCompletion:(QServiceOnCompletion)onCompletion pageNumber:(NSUInteger)pageNumber pageSize:(NSUInteger)pageSize repositories:(NSMutableArray *)repos
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:[NSString stringWithFormat:@"orgs/%@/repos", orgName] //@"/search/repositories"
      parameters:@{@"page": @(pageNumber), @"per_page": @(pageSize)} progress:nil  onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              for (NSDictionary *json in responseObject) {
                  QRepository *repo = [QRepository fromJSON:json];
                  repo.account = self.account;
                  [repos addObject:repo];
              }
              
              if (context.nextPageNumber) {
                  [self _repositoriesForOrganizationNamed:orgName onCompletion:onCompletion pageNumber:context.nextPageNumber.unsignedIntegerValue pageSize:pageSize repositories:repos];
              } else {
                  onCompletion(repos, context, nil);
              }
          }
      }];
}

//- (void)starredRepositoriesForloginUserOnCompletion:(QServiceOnCompletion)onCompletion;
//{
//    AFHTTPSessionManager *manager = [self httpSessionManager];
//    [manager GET:@"user/starred"
//      parameters:@{} progress:nil success:^(NSURLSessionDataTask *task, NSArray *responseObject) {
//
//          NSMutableArray *result = [NSMutableArray array];
//          for (NSDictionary *json in responseObject) {
//              QRepository *repo = [QRepository fromJSON:json];
//              repo.account = self.account;
//              repo.starred = YES;
//              [result addObject:repo];
//          }
//
//          //DDLogDebug(@"responseObject %@", responseObject);
//          onCompletion(result, nil);
//
//
//      } failure:^(NSURLSessionDataTask * task, NSError * error) {
//          DDLogDebug(@"error %@", error);
//          onCompletion(nil, error);
//      }];
//}

@end
