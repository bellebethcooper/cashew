//
//  QRepositoriesService.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QBaseService.h"
#import "QAccount.h"
#import "QRepository.h"

@interface QRepositoriesService : QBaseService

// GET /user/repos
- (void)repositoriesForCurrentUserWithPageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;

// GET /repos/:owner/:repo/milestones
- (void)milestonesForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;

// GET /search/repositories
- (void)searchRepositoriesWithQuery:(NSString *)query pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize contextId:(NSNumber *)contextId onCompletion:(QServiceOnCompletion)onCompletion;

// GET /repos/:owner/:repo/labels
- (void)labelsForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;

//GET /repos/:owner/:repo/assignees
- (void)assigneesForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize onCompletion:(QServiceOnCompletion)onCompletion;

// GET /orgs/:name/repos
- (void)repositoriesForOrganizationNamed:(NSString *)orgName onCompletion:(QServiceOnCompletion)onCompletion;

// GET /repos/:owner/:repo
- (void)repositoryForOwnerLogin:(NSString *)login repositoryName:(NSString *)repositoryName onCompletion:(QServiceOnCompletion)onCompletion;

@end
