//
//  QIssueFavoriteStore.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/23/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QBaseStore.h"

@class QIssue;

@interface QIssueFavoriteStore : QBaseStore

+ (void)favoriteIssue:(QIssue *)issue;
+ (void)unfavoriteIssue:(QIssue *)issue;
+ (BOOL)isFavoritedIssue:(QIssue *)issue;
+ (NSInteger)totalFavoritedOutOfIssues:(NSArray<QIssue *> *)issues;

@end
