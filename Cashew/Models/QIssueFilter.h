//
//  QFilter.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QAccount.h"
#import "QRepository.h"

extern NSString * const kQIssueUpdatedDateSortKey;
extern NSString * const kQIssueClosedDateSortKey;
extern NSString * const kQIssueCreatedDateSortKey;
extern NSString * const kQIssueIssueNumberSortKey;
extern NSString * const kQIssueIssueStateSortKey;
extern NSString * const kQIssueTitleSortKey;
extern NSString * const kQIssueAssigneeSortKey;

typedef enum : NSUInteger {
    SRFilterType_Notifications,
    SRFilterType_Drafts,
    SRFilterType_Favorites,
    SRFilterType_Search,
} SRFilterType;


@interface QIssueFilter : NSObject

+ (instancetype)filterWithSearchTokensArray:(NSArray *)tokens;
+ (instancetype)filterWithSearchTokens:(NSString *)tokens;


@property (nonatomic) SRFilterType filterType;
@property (nonatomic) QAccount *account;
@property (nonatomic) NSOrderedSet *states;
@property (nonatomic) NSOrderedSet *assignees;
@property (nonatomic) NSOrderedSet *authors;
@property (nonatomic) NSOrderedSet *mentions;
@property (nonatomic) NSOrderedSet *repositories;
@property (nonatomic) NSOrderedSet *milestones;
@property (nonatomic) NSOrderedSet *labels;
@property (nonatomic) NSOrderedSet *issueNumbers;

@property (nonatomic) NSOrderedSet *assigneeExcludes;
@property (nonatomic) NSOrderedSet *mentionExcludes;
@property (nonatomic) NSOrderedSet *authorExcludes;
@property (nonatomic) NSOrderedSet *repositorieExcludes;
@property (nonatomic) NSOrderedSet *milestoneExcludes;
@property (nonatomic) NSOrderedSet *labelExcludes;


@property (nonatomic) NSString *query;
@property (nonatomic) NSString *sortKey;
@property (nonatomic) BOOL ascending;


- (NSString *)searchTokens;
- (NSArray *)searchTokensArray;

- (BOOL)isEqualToIssueFilter:(QIssueFilter *)filter;

@end
