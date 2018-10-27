//
//  QRepositoryStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
#import "QRepository.h"

@interface QRepositoryStore : QBaseStore

+ (void)saveRepository:(QRepository *)repo;
+ (void)saveAssignee:(QOwner *)assignee forRepository:(QRepository *)repo;
+ (NSArray<QRepository *> *)repositoriesForAccountId:(NSNumber *)accountId;
+ (QRepository *)repositoryForAccountId:(NSNumber *)accountId identifier:(NSNumber *)identifier;
+ (QRepository *)repositoryForAccountId:(NSNumber *)accountId fullName:(NSString *)fullName;
+ (QRepository *)repositoryForAccountId:(NSNumber *)accountId ownerLogin:(NSString *)ownerLogin repositoryName:(NSString *)repositoryName;
+ (NSArray<QRepository *> *)searchRepositoriesWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId;
+ (NSArray<QRepository *> *)repositoriesWithTitle:(NSArray<NSString *> *)titles forAccountId:(NSNumber *)accountId;
+ (void)delete:(QRepository *)repository;
+ (void)markAsCompletedSyncForRepository:(QRepository *)repo;
+ (void)deleteAssignee:(QOwner *)assignee forRepository:(QRepository *)repo;
+ (void)saveDeltaSyncDate:(NSDate *)date forRepository:(QRepository *)repo;
+ (BOOL)isDeletedRepository:(QRepository *)repository;

@end
