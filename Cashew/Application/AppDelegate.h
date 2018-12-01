//
//  AppDelegate.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CashewAppDelegate <NSObject>

- (void)fadeOutModalOverlayOnCompletion:(nullable dispatch_block_t)onCompletion;
- (void)fadeInModalOverlayOnCompletion:(nullable dispatch_block_t)onCompletion animated:(BOOL)animated;
- (void)presentWindowWithViewController:(nonnull NSViewController *)viewController title:(nonnull NSString *)title onCompletion:(nullable dispatch_block_t)onCompletion;
- (void)dismissWindowWithViewController:(nonnull NSViewController *)viewController;
- (void)syncForced:(BOOL)forced;
- (void)didUseNewIssueHotKey;

@end

@interface AppDelegate : NSObject <NSApplicationDelegate, CashewAppDelegate>

- (nonnull NSURL *)applicationDocumentsDirectory;

+ (nonnull id<CashewAppDelegate>)sharedCashewAppDelegate;

@end

