//
//  QSession.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QContext.h"
#import <FXKeychain/FXKeychain.h>
#import "QAccount.h"

static NSString * const kQAccountListKey = @"kQAccountListKey";
NSString * const kQContextChangeNotification = @"kQContextChangeNotification";
NSString * const kQShowCreateNewIssueNotification = @"kQShowCreateNewIssueNotification";
NSString * const kQContextIssueSelectionChangeNotification = @"kQContextIssueSelectionChangeNotification";

@implementation QContext {
    FXKeychain *_keychain;
    dispatch_queue_t _syncAccountsQueue;
}


+ (instancetype)sharedContext {
    static dispatch_once_t onceToken;
    static QContext *session;
    dispatch_once(&onceToken, ^{
        session = [QContext new];
    });
    return session;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *serviceName = @"co.hellocode.cashew.keychain";
        _keychain = [[FXKeychain alloc] initWithService:serviceName accessGroup:nil accessibility:FXKeychainAccessibleAlways];
        NSLog(@"QContext init - keychain: %@", _keychain);
        _syncAccountsQueue = dispatch_queue_create("co.hellocode.cashew.sync.accounts", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (QAccount *)currentAccount
{
    return self.currentFilter.account;
}

#pragma mark - Search Context

- (void)setCurrentFilter:(QIssueFilter *)currentFilter;
{
    [self setCurrentFilter:currentFilter sender:nil postNotification:true];
}

- (void)setCurrentFilter:(QIssueFilter *)currentFilter sender:(id)sender
{
    [self setCurrentFilter:currentFilter sender:sender postNotification:true];
}

- (void)setCurrentFilter:(QIssueFilter *)currentFilter sender:(id)sender postNotification:(BOOL)postNotification;
{
    if (_currentFilter != currentFilter) {
        _currentFilter = currentFilter;
        if (postNotification) {
            dispatch_block_t block = ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kQContextChangeNotification object:sender];
            };
            if ([NSThread isMainThread]) {
                block();
            } else {
            dispatch_async(dispatch_get_main_queue(), block);
            }
        }
    }
}

- (void)setCurrentIssues:(NSArray<QIssue *> *)currentIssues
{
    NSSet<QIssue *> *currentSet = _currentIssues ? [NSSet setWithArray:_currentIssues] : [NSSet new];
    NSSet<QIssue *> *newSet = currentIssues ? [NSSet setWithArray:currentIssues] : [NSSet new];
    
    _currentIssues = currentIssues;
    if (![newSet isEqualToSet:currentSet]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kQContextIssueSelectionChangeNotification object:_currentIssues];
        });
    }
}


#pragma mark - Accounts
- (NSArray<NSString *> *)_accountNamesForCurrentUser
{
    
    __block NSArray *accounts = nil;
    
    dispatch_sync(_syncAccountsQueue, ^{
        accounts = [[NSUserDefaults standardUserDefaults] arrayForKey:kQAccountListKey];
    });
    
    return accounts;
}

- (void)addAccount:(QAccount *)account withPassword:(NSString *)password {
    NSLog(@"QContext addAccount");
    dispatch_sync(_syncAccountsQueue, ^{
        
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        if (password) {
            dictionary[@"password"] = password;
        }
        
        if (account.authToken) {
            dictionary[@"auth_token"] = account.authToken;
        }
        NSLog(@"QContext addAccount: %@ password: %@", account.username, password);
        [self _storeValue:dictionary inKeychainForKey:account.username];
    });
}

- (void)removeAccount:(QAccount *)account;
{
    if (!account) {
        return;
    }
    dispatch_sync(_syncAccountsQueue, ^{
        [_keychain removeObjectForKey:account.username];
    });
}

- (NSString *)passwordForLogin:(NSString *)login;
{
    NSDictionary *auth = [self _keychainObjectForKey:login];
    if ([auth isKindOfClass:NSString.class]) {
        return nil;
    }
    return auth[@"password"];
}

- (NSString *)authTokenForLogin:(NSString *)login;
{
    NSDictionary *auth = [self _keychainObjectForKey:login];
    if ([auth isKindOfClass:NSString.class]) {
        return nil;
    }
    return auth[@"auth_token"];
}


#pragma mark - Keychain

- (void)_storeValue:(id)value inKeychainForKey:(NSString *)key {
    NSLog(@"QContext storeValue - value: %@ key: %@ keychain: %@", value, key, _keychain);
    [_keychain setObject:value forKey:key];
}

- (id)_keychainObjectForKey:(NSString *)key {
    return [_keychain objectForKey:key];
}


@end
