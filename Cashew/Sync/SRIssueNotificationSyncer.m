//
//  SRIssueNotificationSyncer.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRIssueNotificationSyncer.h"
#import "Cashew-Swift.h"
#import "SRNotificationService.h"
#import "QIssueNotificationStore.h"
#import "QAccountStore.h"
#import "QRepositoryStore.h"

@interface SRIssueNotificationSyncer() <QStoreObserver>

@end

@implementation SRIssueNotificationSyncer

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [QRepositoryStore remove:self];
}

+ (instancetype)sharedIssueNotificationSync;
{
    static dispatch_once_t onceToken;
    static SRIssueNotificationSyncer *sync;
    dispatch_once(&onceToken, ^{
        
        sync = [[SRIssueNotificationSyncer alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sync selector:@selector(_didFinishDeltaIssueSynching:) name:kDidFinishDeltaIssueSynchingNotification object:nil];
        [QRepositoryStore addObserver:sync];
    });
    
    return sync;
}

- (void)_didFinishDeltaIssueSynching:(NSNotification *)notification
{
    // fetch notifications on each account
    NSArray<QAccount *> *accounts = [QAccountStore accounts];
    [accounts enumerateObjectsUsingBlock:^(QAccount * _Nonnull account, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDate *sinceDate = [QIssueNotificationStore notificationModifiedOnForAccountId:account.identifier];
//        DDLogDebug(@"START fetching notifications for account = %@ lastModified = %@", account.username, sinceDate);
       [self _fetchNotificationsForAccount:account sinceDate:sinceDate pageNumber:1 pageSize:100];
    }];
    
}

- (void)_fetchNotificationsForAccount:(QAccount *)account sinceDate:(NSDate *)date pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize
{
    NSParameterAssert(![NSThread isMainThread]);
    NSParameterAssert(account);
    
    SRNotificationService *notificationService = [SRNotificationService serviceForAccount:account];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [notificationService notificationsSinceDate:date pageNumber:pageNumber pageSize:pageSize onCompletion:^(NSArray<NSDictionary *>  *notifications, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
        
        if (error != nil) {
            //DDLogDebug(@"error fetching notifications -> %@", error);
            DDLogDebug(@"[ERROR] done fetching notifications for account = %@ lastModified = %@", account.username, context.lastModified);
            return;
        }
        
        [notifications enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull notification, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *subject = notification[@"subject"];
            
            if (!subject || ![@"Issue" isEqualToString:subject[@"type"]]) {
                DDLogDebug(@"skipping notification %@", notification);
                return;
            }
            
            NSNumber *threadId = notification[@"id"];
            NSString *reason = notification[@"reason"];
            NSNumber *repositoryId = notification[@"repository"][@"id"];
            BOOL read = ![(NSNumber *)notification[@"unread"] boolValue];
            NSDate *updatedAt = [[SRIssueNotificationSyncer _githubDateFormatter] dateFromString:notification[@"updated_at"]];
            
            
            NSString *url = subject[@"url"];
            NSError *error = NULL;
            NSString *pattern = @"^https:\\/\\/.*?\\/repos\\/.*\\/(\\d*)$";
            NSRange range = NSMakeRange(0, url.length);
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
            NSArray *matches = [regex matchesInString:url options:0 range:range];
            __block BOOL handled = false;
            __block NSNumber *issueNumber = nil;
            [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
                handled = true;
                NSRange issueNumberRange = [match rangeAtIndex:1];
                NSString *issueNumberString = [url substringWithRange:issueNumberRange];
                issueNumber = [formatter numberFromString:issueNumberString];
            }];
            
            NSParameterAssert(handled);
            NSParameterAssert(issueNumber);
            //DDLogDebug(@"notification -> %@", notification);
            //DDLogDebug(@"account=%@  repository=%@  issueNumber=%@ threadId=%@ reason=%@ read=%@ updatedAt=[%@] vs date=[%@]", account.identifier, repositoryId, issueNumber, threadId, reason, @(read), updatedAt, date);
            [QIssueNotificationStore saveIssueNotificationWithAccountId:account.identifier repositoryId:repositoryId issueNumber:issueNumber threadId:threadId reason:reason read:read updatedAt:updatedAt];
        }];
        
        
        if (context.nextPageNumber) {
            DDLogDebug(@"fetching next notification set %@ for account = %@", context.nextPageNumber, account.username);
            [self _fetchNotificationsForAccount:account sinceDate:date pageNumber:context.nextPageNumber.integerValue pageSize:pageSize];
        } else {
            DDLogDebug(@"done fetching notifications for account = %@ lastModified = %@", account.username, context.lastModified);
            if (context.lastModified) {
                [QIssueNotificationStore saveNotificationModifiedOnDate:context.lastModified forAccountId:account.identifier];
            }
        }
        
    }];
}

- (void)store:(Class)store didInsertRecord:(id)record;
{
    if (store == QRepositoryStore.class && [record isKindOfClass:QRepository.class]) {
        QRepository *repository = (QRepository *)record;
        [QIssueNotificationStore resetNotificationModifiedOnForAccountId:repository.account.identifier];
    }
}

- (void)store:(Class)store didUpdateRecord:(id)record;
{
    
}

- (void)store:(Class)store didRemoveRecord:(id)record;
{
    if (store == QRepositoryStore.class && [record isKindOfClass:QRepository.class]) {
        QRepository *repository = (QRepository *)record;
        [QIssueNotificationStore resetNotificationModifiedOnForAccountId:repository.account.identifier];
    }
}

@end
