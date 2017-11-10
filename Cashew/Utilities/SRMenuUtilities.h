//
//  SRMenuUtilities.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface SRMenuUtilities : NSObject

+ (void)setupCloseOrOpenIssueMenuItem:(NSMenuItem *)menuItem openIssuesCount:(NSUInteger)openIssues closedIssuesCount:(NSInteger)closedIssues;
+ (void)setupFavoriteIssueMenuItem:(NSMenuItem *)menuItem favoriteIssuesCount:(NSUInteger)favoriteIssuesCount unfavoriteIssuesCount:(NSInteger)unfavoriteIssuesCount;

+ (NSArray *)selectedIssueItemsForSharingService;
+ (void)setupShareMenuItem:(NSMenuItem *)issueShareMenuItem;
+ (void)setupExtensionMenuItem:(NSMenuItem *)extensionMenuItem;
+ (NSMenu *)menuForExtensions;

@end
