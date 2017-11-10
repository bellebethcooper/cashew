//
//  QSourceListNode.h
//  Issues
//
//  Created by Hicham Bouabdallah on 2/1/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Cashew-Swift.h"

@class QIssueFilter;

typedef NS_ENUM(NSInteger, QSourceListNodeType)
{
    QSourceListNodeType_OpenIssues,
    QSourceListNodeType_AssignedToMe,
    QSourceListNodeType_ReportedByMe,
    QSourceListNodeType_MentionsMe,
    QSourceListNodeType_Repositories,
    QSourceListNodeType_CustomFilters,
    QSourceListNodeType_CustomFilter,
    QSourceListNodeType_Repository,
    QSourceListNodeType_Milestone,
    QSourceListNodeType_Menu,
    QSourceListNodeType_Notifications,
    QSourceListNodeType_Drafts,
    QSourceListNodeType_Favorites,
    QSourceListNodeType_All
};

@interface QSourceListNode : NSObject

@property (nonatomic, weak) QSourceListNode *parentNode;
@property (nonatomic) NSMutableArray<QSourceListNode *> *children;
@property (nonatomic) NSString *title;
@property (nonatomic) QIssueFilter *issueFilter;
@property (nonatomic) QUserQuery *userQuery;
@property (nonatomic) QSourceListNodeType nodeType;
@property (nonatomic) NSObject *representedObject;

@end

