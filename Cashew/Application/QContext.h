//
//  QSession.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QAccount.h"
#import "QIssueFilter.h"

@class QIssue;

extern NSString * const kQContextChangeNotification;
extern NSString * const kQShowCreateNewIssueNotification;
extern NSString * const kQContextIssueSelectionChangeNotification;

@interface QContext : NSObject

+ (instancetype)sharedContext;

- (void)addAccount:(QAccount *)account withPassword:(NSString *)password;
- (void)removeAccount:(QAccount *)account;
- (NSString *)passwordForLogin:(NSString *)login;
- (NSString *)authTokenForLogin:(NSString *)login;

@property (nonatomic, strong) QIssueFilter *currentFilter;
@property (nonatomic, readonly) QAccount *currentAccount;
@property (nonatomic, strong) NSArray<QIssue *> *currentIssues;

- (void)setCurrentFilter:(QIssueFilter *)currentFilter sender:(id)sender;
- (void)setCurrentFilter:(QIssueFilter *)currentFilter sender:(id)sender postNotification:(BOOL)postNotification;

@end
