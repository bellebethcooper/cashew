//
//  SRMenuUtilities.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRMenuUtilities.h"
#import "QContext.h"
#import "QIssue.h"
#import "AppDelegate.h"
#import "SRExtensionStore.h"
#import "Cashew-Swift.h"

@implementation SRMenuUtilities


+ (void)setupCloseOrOpenIssueMenuItem:(NSMenuItem *)menuItem openIssuesCount:(NSUInteger)openIssues closedIssuesCount:(NSInteger)closedIssues
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    NSInteger issueCount = openIssues + closedIssues;
    if (menuItem.action == @selector(sr_closeIssues:) || menuItem.action == @selector(sr_reopenIssues:)) {
        menuItem.target = [AppDelegate sharedCashewAppDelegate];
        if (openIssues > closedIssues) {
            menuItem.action = @selector(sr_closeIssues:);
            if (issueCount > 1) {
                menuItem.title = [NSString stringWithFormat:@"Close %ld Issues", issueCount];
            } else {
                menuItem.title = @"Close Issue";
            }
//            [menuItem setKeyEquivalentModifierMask: NSCommandKeyMask];
//            [menuItem setKeyEquivalent:@"d"];
        } else {
            menuItem.action = @selector(sr_reopenIssues:);
            if (issueCount > 1) {
                menuItem.title = [NSString stringWithFormat:@"Open %ld Issues", issueCount];
            } else {
                menuItem.title = @"Open Issue";
            }
//            [menuItem setKeyEquivalentModifierMask: NSShiftKeyMask | NSCommandKeyMask];
//            [menuItem setKeyEquivalent:@"o"];
        }
    }
#pragma clang diagnostic pop
}

+ (void)setupFavoriteIssueMenuItem:(NSMenuItem *)menuItem favoriteIssuesCount:(NSUInteger)favoriteIssuesCount unfavoriteIssuesCount:(NSInteger)unfavoriteIssuesCount;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    NSInteger issueCount = favoriteIssuesCount + unfavoriteIssuesCount;
    if (menuItem.action == @selector(sr_favoriteIssues:) || menuItem.action == @selector(sr_unfavoriteIssues:)) {
        
        if (favoriteIssuesCount > unfavoriteIssuesCount) {
            menuItem.action = @selector(sr_unfavoriteIssues:);
            if (issueCount > 1) {
                menuItem.title = [NSString stringWithFormat:@"Unfavorite %ld Issues", issueCount];
            } else {
                menuItem.title = @"Unfavorite Issue";
            }
            //            [menuItem setKeyEquivalentModifierMask: NSCommandKeyMask];
            //            [menuItem setKeyEquivalent:@"d"];
        } else {
            menuItem.action = @selector(sr_favoriteIssues:);
            if (issueCount > 1) {
                menuItem.title = [NSString stringWithFormat:@"Favorite %ld Issues", issueCount];
            } else {
                menuItem.title = @"Favorite Issue";
            }
            //            [menuItem setKeyEquivalentModifierMask: NSShiftKeyMask | NSCommandKeyMask];
            //            [menuItem setKeyEquivalent:@"o"];
        }
    }
#pragma clang diagnostic pop
}

+ (NSArray *)selectedIssueItemsForSharingService
{
    NSArray<QIssue *> *currentIssues = [QContext sharedContext].currentIssues;
    if (currentIssues.count != 1) {
        return @[];
    }
    QIssue *issue = currentIssues[0];
    if (!issue.htmlURL) {
        return @[];
    }
    return @[ @"\n Shared via @cashewappco\n", issue.htmlURL ];
}

+ (void)setupExtensionMenuItem:(NSMenuItem *)extensionMenuItem;
{
    extensionMenuItem.submenu = [SRMenuUtilities menuForExtensions];
}

+ (NSURL *)_codeExtensionLogsURL
{
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    NSURL *url = [[[appDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:@"extensions"] URLByAppendingPathComponent:@"logs"];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:url.path]) {
        NSError *err;
        [NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&err];
        NSParameterAssert(!err);
    }
    
    return url;
}

+ (NSMenu *)menuForExtensions
{
    SRMenu *menu = [SRMenu new];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //  NSString *separator = [NSString stringWithFormat:@"%c", 12];
    //private static let separator = String(UnicodeScalar(12))
    NSArray<SRExtension *> *codeExtensions = [SRExtensionStore extensionsForType:SRExtensionTypeIssue];
    [codeExtensions enumerateObjectsUsingBlock:^(SRExtension *codeExtension, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSMenuItem *codeExtensionMenuItem = [[NSMenuItem alloc] initWithTitle:codeExtension.name action:@selector(sr_executeIssueCodeExtension:) keyEquivalent:@""];
        codeExtensionMenuItem.representedObject = codeExtension;
        codeExtensionMenuItem.target = [AppDelegate sharedCashewAppDelegate];
        
        // NSArray<NSString *> *pieces = [codeExtension.keyboardShortcut componentsSeparatedByString:separator];
        //        if (pieces.count == 3) {
        //            codeExtensionMenuItem.keyEquivalent = pieces[2];
        //            codeExtensionMenuItem.keyEquivalentModifierMask = [pieces[0] integerValue];
        //        }
        //
        [menu addItem:codeExtensionMenuItem];
    }];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *viewLogsExtensions = [[NSMenuItem alloc] initWithTitle:@"View Extension Logs" action:@selector(sr_viewExtensionLogs:) keyEquivalent:@""];
    viewLogsExtensions.representedObject = [SRMenuUtilities _codeExtensionLogsURL];
    viewLogsExtensions.target = [AppDelegate sharedCashewAppDelegate];
    [menu addItem:viewLogsExtensions];
    
    NSMenuItem *manageExtensions = [[NSMenuItem alloc] initWithTitle:@"Manage Extensions" action:@selector(sr_manageExtensions:) keyEquivalent:@""];
    manageExtensions.target = [AppDelegate sharedCashewAppDelegate];
    [menu addItem:manageExtensions];
    
#pragma clang diagnostic pop
    
    return menu;
}

+ (void)setupShareMenuItem:(NSMenuItem *)issueShareMenuItem;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSArray *itemsForSharingService = [SRMenuUtilities selectedIssueItemsForSharingService];
    if (itemsForSharingService.count > 0) {
        NSArray<NSSharingService *> *sharingServices = [NSSharingService sharingServicesForItems:itemsForSharingService];
        
        if (sharingServices.count > 0) {
            SRMenu *sharingSubmenu = [SRMenu new];
            [sharingServices enumerateObjectsUsingBlock:^(NSSharingService * _Nonnull service, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:service.title action:nil keyEquivalent:@""];
                item.representedObject = service;
                item.target = [AppDelegate sharedCashewAppDelegate];
                item.action = @selector(sr_shareFromService:);
                item.image = service.image;
                [sharingSubmenu addItem:item];
            }];
            issueShareMenuItem.submenu = sharingSubmenu;
        }
    }
    #pragma clang diagnostic pop
}

@end
