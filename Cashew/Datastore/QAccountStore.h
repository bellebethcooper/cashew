//
//  QAccountStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
#import "QAccount.h"

@interface QAccountStore : QBaseStore

+ (void)saveAccount:(QAccount *)account;
+ (void)deleteAccount:(QAccount *)account;
+ (NSArray<QAccount *> *)accounts;
+ (QAccount *)accountForIdentifier:(NSNumber *)identifier;
//+ (QAccount *)accountForLogin:(NSString *)login baseURL:(NSURL *)baseURL;
+ (QAccount *)accountForUserId:(NSNumber *)userId baseURL:(NSURL *)baseURL;
+ (BOOL)isDeletedAccount:(QAccount *)account;

@end
