//
//  QIssue.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QOwner.h"
#import "QLabel.h"
#import "QRepository.h"
#import "QMilestone.h"
#import "QIssueCommentInfo.h"
#import "SRIssueDetailItem.h"
#import "SRIssueNotification.h"

NS_ASSUME_NONNULL_BEGIN

@class SRIssueNotification;

@interface QIssue : NSObject<QIssueCommentInfo, SRIssueDetailItem, NSCopying>

@property (nonatomic) QAccount *account;
@property (nonatomic) QRepository *repository;
@property (nonatomic) QOwner *user;
@property (nonatomic, nullable) QOwner *assignee;
@property (nonatomic, nullable) QMilestone *milestone;
@property (nonatomic, nullable) NSArray<QLabel *> *labels;
@property (nonatomic) NSString *title;
@property (nonatomic) NSNumber *number;
@property (nonatomic) NSNumber *identifier;
@property (nonatomic) NSDate *createdAt;
@property (nonatomic, nullable) NSDate *closedAt;
@property (nonatomic) NSDate *updatedAt;
@property (nonatomic, nullable) NSString *body;
@property (nonatomic) NSString *state;
@property (nonatomic, nullable) SRIssueNotification *notification;
@property (nonatomic, nullable) NSURL *htmlURL;

@property (nonatomic) NSInteger thumbsUpCount;
@property (nonatomic) NSInteger thumbsDownCount;
@property (nonatomic) NSInteger laughCount;
@property (nonatomic) NSInteger hoorayCount;
@property (nonatomic) NSInteger confusedCount;
@property (nonatomic) NSInteger heartCount;
@property (nonatomic) NSString *type;

// Temporary for fixing crash on launch
@property (nonatomic, readonly) NSString *createdAtTimeAgo;
@property (nonatomic, readonly) NSString *authorUsername;
@property (nonatomic, readonly) NSString *repositoryName;
@property (nonatomic, readonly) NSString *milestoneTitle;


+ (instancetype)fromJSON:(NSDictionary *)dict;

- (BOOL)isEqualToIssue:(QIssue *)issue;
- (NSDictionary *)toExtensionModel;

@end

NS_ASSUME_NONNULL_END
