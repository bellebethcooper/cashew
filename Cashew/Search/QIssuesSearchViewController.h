//
//  QIssuesSearchViewController.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//
//@interface SRIssuesSearchTokenField : NSTokenField
//@end

@class SRIssuesSearchTokenField;

@interface QIssuesSearchViewController : NSViewController

@property (readonly) IBOutlet SRIssuesSearchTokenField *searchField;

- (void)focus;

@end
