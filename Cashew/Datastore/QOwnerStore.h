//
//  QOwnerStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
#import "QOwner.h"

@interface QOwnerStore : QBaseStore

+ (void)saveOwner:(QOwner *)owner;
+ (QOwner *)ownerForAccountId:(NSNumber *)accountId identifier:(NSNumber *)identifier;
+ (QOwner *)ownerForAccountId:(NSNumber *)accountId login:(NSString *)login;
+ (NSArray<QOwner *> *)searchUserWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId;
+ (NSArray<QOwner *> *)searchUserWithQuery:(NSString *)query forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
+ (NSArray<QOwner *> *)ownersWithLogins:(NSArray<NSString *> *)logins forAccountId:(NSNumber *)accountId;
+ (NSArray<QOwner *> *)ownersForAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
+ (void)deleteOwner:(QOwner *)owner;
+ (BOOL)isCollaboratorUserId:(NSNumber *)userId forAccountId:(NSNumber *)accountId repositoryId:(NSNumber *)repositoryId;
+ (NSArray<QOwner *> *)ownersForAccountId:(NSNumber *)accountId;

@end
