//
//  SRUserQueryNameViewController.h
//  Issues
//
//  Created by Hicham Bouabdallah on 6/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SRUserQueryNameViewController;
@class QAccount;

@protocol SRUserQueryNameViewControllerDelegate <NSObject>

- (void)didCloseUserQueryNameViewController:(SRUserQueryNameViewController *)controller;

@end

@interface SRUserQueryNameViewController : NSViewController

@property (nonatomic) id<SRUserQueryNameViewControllerDelegate> delegate;

- (instancetype)initWithAccount:(QAccount *)account query:(NSString *)query;

@end
