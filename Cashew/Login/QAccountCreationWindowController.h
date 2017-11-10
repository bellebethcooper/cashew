//
//  QAccountCreationWindowController.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QAccount.h"

@class QAccountCreationWindowController;

@protocol QAccountCreationWindowControllerDelegate <NSObject>

- (void)willCloseAccountCreationWindowController:(QAccountCreationWindowController *)controller;
- (void)creationWindowController:(QAccountCreationWindowController *)controller didSignInToAccount:(QAccount *)account;

@end

@interface QAccountCreationWindowController : NSWindowController

@property (nonatomic, weak) id<QAccountCreationWindowControllerDelegate> delegate;
@property (nonatomic) QAccount *showRepositoryPickerAccount;
@property (nonatomic) QAccount *showSessionExpiredForAccount;
- (void)presentModalWindow;

@end
