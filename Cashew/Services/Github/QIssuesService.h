//
//  QIssuesService.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QBaseService.h"
#import "QRepository.h"

NS_ASSUME_NONNULL_BEGIN

@class QIssue;
@class QIssueComment;
@class QMilestone;

@interface QIssuesService : QBaseService


- (void)issuesForRepository:(QRepository *)repository pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize sortKey:(NSString * )sortKey ascending:(BOOL)ascending since:(nullable NSDate *)since onCompletion:(QServiceOnCompletion)onCompletion;


//GET /repos/:owner/:repo/issues/:number
- (void)issueForRepository:(QRepository *)repository
               issueNumber:(NSNumber *)issueNumber
              onCompletion:(QServiceOnCompletion)onCompletion;

// GET /repos/:owner/:repo/issues/:number/comments
- (void)issuesCommentsForRepository:(QRepository *)repository
                        issueNumber:(NSNumber *)issueNumber
                         pageNumber:(NSInteger)pageNumber
                           pageSize:(NSInteger)pageSize
                              since:(NSDate *)since
                       onCompletion:(QServiceOnCompletion)onCompletion;


// GET /repos/:owner/:repo/issues/:issue_number/events
- (void)issuesEventsForRepository:(QRepository *)repository
                      issueNumber:(NSNumber *)issueNumber
                       pageNumber:(NSInteger)pageNumber
                         pageSize:(NSInteger)pageSize
                            since:(nullable NSDate *)since
                     onCompletion:(QServiceOnCompletion)onCompletion;

// GET /repos/:owner/:repo/issues/:issue_number/events
- (void)fetchAllIssuesEventsForRepository:(QRepository *)repository
                              issueNumber:(NSNumber *)issueNumber
                               pageNumber:(NSInteger)pageNumber
                                    since:(nullable NSDate *)since
                             onCompletion:(QServiceOnCompletion)onCompletion;


// POST /repos/:owner/:repo/issues
- (void)createIssueForRepository:(QRepository *)repository
                           title:(NSString *)title
                            body:(nullable NSString *)body
                        assignee:(nullable NSString *)assignee
                       milestone:(nullable NSNumber *)milestoneNumber
                          labels:(nullable NSArray<NSString *> *)labels
                    onCompletion:(QServiceOnCompletion)onCompletion;


// PATCH /repos/:owner/:repo/issues/:number
- (void)closeIssueForRepository:(QRepository *)repository
                         number:(NSNumber *)number
                   onCompletion:(QServiceOnCompletion)onCompletion;

// PATCH /repos/:owner/:repo/issues/:number
- (void)reopenIssueForRepository:(QRepository *)repository
                          number:(NSNumber *)number
                    onCompletion:(QServiceOnCompletion)onCompletion;

// POST /repos/:owner/:repo/issues/:number/comments
- (void)createCommentForRepository:(QRepository *)repository
                       issueNumber:(NSNumber *)number
                              body:(NSString *)body
                      onCompletion:(QServiceOnCompletion)onCompletion;


//PUT /repos/:owner/:repo/issues/:number/labels
- (void)saveLabels:(NSArray<NSString *> *)labels
     forRepository:(QRepository *)repository
       issueNumber:(NSNumber *)number
      onCompletion:(QServiceOnCompletion)onCompletion;


// PATCH /repos/:owner/:repo/issues/:number
- (void)saveMilestoneNumber:(nullable NSNumber *)milestoneNumber
              forRepository:(QRepository *)repository
                     number:(NSNumber *)number
               onCompletion:(QServiceOnCompletion)onCompletion;

// PATCH /repos/:owner/:repo/issues/:number
- (void)saveAssigneeLogin:(nullable NSString *)assignee
            forRepository:(QRepository *)repository
                   number:(NSNumber *)number
             onCompletion:(QServiceOnCompletion)onCompletion;

// PATCH /repos/:owner/:repo/issues/:number
- (void)saveIssueTitle:(NSString *)title
         forRepository:(QRepository *)repository
                number:(NSNumber *)number
          onCompletion:(QServiceOnCompletion)onCompletion;

// PATCH /repos/:owner/:repo/issues/:number
- (void)saveIssueBody:(nullable NSString *)body
        forRepository:(QRepository *)repository
               number:(NSNumber *)number
         onCompletion:(QServiceOnCompletion)onCompletion;


// DELETE /repos/:owner/:repo/issues/comments/:id
- (void)deleteIssueComment:(QIssueComment *)comment
              onCompletion:(QServiceOnCompletion)onCompletion;

// PATCH /repos/:owner/:repo/issues/comments/:id
- (void)updateCommentText:(NSString *)body forRepository:(QRepository *)repository
              issueNumber:(NSNumber *)issueNumber
        commentIdentifier:(NSNumber *)identifier
             onCompletion:(QServiceOnCompletion)onCompletion;

//- (void)saveIssue:(QIssue *)issue
//     onCompletion:(QServiceOnCompletion)onCompletion;


//PATCH /repos/:owner/:repo/milestones/:number
- (void)closeMilestone:(QMilestone *)milestone
          onCompletion:(QServiceOnCompletion)onCompletion;
@end

NS_ASSUME_NONNULL_END
