//
//  QBaseWindowController.h
//  Issues
//
//  Created by Hicham Bouabdallah on 3/26/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QBaseWindowController;

@protocol QBaseWindowControllerDelegate <NSObject>
- (void)willCloseBaseWindowController:(QBaseWindowController *)baseWindowController;
@end


@interface QBaseWindowController : NSWindowController

@property (nonatomic, weak) id<QBaseWindowControllerDelegate> baseWindowControllerDelegate;
@property (nonatomic, strong) NSViewController *viewController;
@end
