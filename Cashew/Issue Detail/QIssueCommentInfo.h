//
//  QIssueCommentInfo.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRIssueDetailItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol QIssueCommentInfo <NSObject, SRIssueDetailItem>

- (NSString *)username;
- (NSDate *)commentedOn;
- (NSDate *)commentUpdatedAt;
- (NSString *)commentBody;
- (NSURL *)usernameAvatarURL;
- (NSString *)markdownCacheKey;
- (QRepository *)repo;
- (NSNumber *)issueNum;
- (nullable QOwner *)author;


@property (nonatomic, readonly, nullable) NSURL *htmlURL;

@end

NS_ASSUME_NONNULL_END