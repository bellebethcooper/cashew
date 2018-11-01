//
//  QView+ImageManager.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QView+ImageManager.h"
#import "QImageManager.h"
#import "NSImage+Common.h"
#import <QuartzCore/QuartzCore.h>

@implementation QView (ImageManager)

- (void)setImageURL:(NSURL *)url;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self.layer setContents:nil];
        [CATransaction commit];
    });
    if (!url) {
        return;
    }
    
    [[QImageManager sharedImageManager] downloadImageURL:url onCompletion:^(NSImage *image, NSURL *downloadURL, NSError *error) {
        if ([url isEqualTo:downloadURL]) {
            NSAssert([NSThread isMainThread] == false, @"not in main thread");
            
            NSImage *smallImage = [[NSImage alloc] initWithSize: self.bounds.size];
            [smallImage lockFocus];
            [image setSize: self.bounds.size];
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
            [image drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) operation:NSCompositeCopy fraction:1.0];
            [smallImage unlockFocus];
            dispatch_async(dispatch_get_main_queue(), ^{
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                [self.layer setContents:smallImage];
                [CATransaction commit];
            });
        }
    }];
}


+ (NSImage *)closedIssueImage;
{
    static dispatch_once_t onceToken;
    static NSImage *img;
    dispatch_once(&onceToken, ^{
        img = [[NSImage imageNamed:@"issue-closed"] imageWithTintColor:[NSColor colorWithRed:145/255.0 green:145/255.0 blue:145/255.0 alpha:1.0]];
                                                                        //colorWithCalibratedRed:175/255. green:25/255. blue:0 alpha:1]];
    });
    return img;
}

+ (NSImage *)openIssueImage;
{
    static dispatch_once_t onceToken;
    static NSImage *img;
    dispatch_once(&onceToken, ^{
        img = [[NSImage imageNamed:@"issue-opened"] imageWithTintColor:[NSColor colorWithCalibratedRed:90/255. green:193/255. blue:44/255. alpha:1]];
    });
    return img;
}

+ (NSImage *)defaultAvatarImage;
{
    static dispatch_once_t onceToken;
    static NSImage *img;
    dispatch_once(&onceToken, ^{
        img = [[NSImage imageNamed:@"octoface"] imageWithTintColor:[NSColor colorWithCalibratedRed:122/255. green:122/255. blue:122/255. alpha:1]];
    });
    return img;
}

+ (NSImage *)closedPullRequestImage;
{
    static dispatch_once_t onceToken;
    static NSImage *img;
    dispatch_once(&onceToken, ^{
        img = [[NSImage imageNamed:@"pull-request"] imageWithTintColor:[NSColor colorWithCalibratedRed:175/255. green:25/255. blue:0 alpha:1]];
    });
    return img;
}

+ (NSImage *)openPullRequestImage;
{
    static dispatch_once_t onceToken;
    static NSImage *img;
    dispatch_once(&onceToken, ^{
        img = [[NSImage imageNamed:@"pull-request"] imageWithTintColor:[NSColor colorWithCalibratedRed:90/255. green:193/255. blue:44/255. alpha:1]];
    });
    return img;
}

@end
