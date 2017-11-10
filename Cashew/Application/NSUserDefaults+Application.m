//
//  NSUserDefaults+Application.m
//  Issues
//
//  Created by Hicham Bouabdallah on 3/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "NSUserDefaults+Application.h"

NSString * const kQCurrentAccountId = @"kQCurrentAccountId";

@implementation NSUserDefaults (Application)


+ (void)q_setCurrentAccountId:(NSNumber *)accountId;
{
    if (accountId) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:accountId forKey:kQCurrentAccountId];
        [userDefaults synchronize];
    }
}

+ (void)q_deleteCurrentAccountId;
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kQCurrentAccountId];
    [userDefaults synchronize];
}

+ (NSNumber *)q_currentAccountId;
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:kQCurrentAccountId];
}

@end
