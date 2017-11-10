//
//  QView+ImageManager.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QView.h"

@interface QView (ImageManager)

- (void)setImageURL:(NSURL *)url;


+ (NSImage *)closedIssueImage;
+ (NSImage *)openIssueImage;

+ (NSImage *)closedPullRequestImage;
+ (NSImage *)openPullRequestImage;

+ (NSImage *)defaultAvatarImage;

@end
