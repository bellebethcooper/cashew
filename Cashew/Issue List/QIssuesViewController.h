//
//  QIssuesViewController.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QRepository.h"
#import "QIssue.h"
#import "QIssueFilter.h"

@class QIssuesViewController;

@protocol QIssuesViewControllerDelegate <NSObject>

- (void)issuesViewController:(QIssuesViewController *)controller didSelectIssue:(QIssue *)issue;
- (void)issuesViewController:(QIssuesViewController *)controller keyUp:(NSEvent *)event;

@end

@interface QIssuesViewController : NSViewController

@property (nonatomic) QIssueFilter *filter;
@property (nonatomic, weak) id<QIssuesViewControllerDelegate> delegate;

- (void)focus;
- (void)reloadContextIssueSelection;

@end
