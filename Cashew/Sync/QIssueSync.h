//
//  QIssueSync.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QRepository;

@interface QIssueSync : NSObject

+ (instancetype)sharedIssueSync;

//- (void)stop;
//- (void)start;
//- (void)runInitialPullSyncher;
- (void)refreshIssueEventsAndCommentsForIssueNumber:(NSNumber *)issueNumber repository:(QRepository *)repo skipIssueCheck:(BOOL)skipIssueCheck;

@end
