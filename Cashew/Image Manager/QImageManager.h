//
//  QImageManager.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^QImageDowloadCompletion)(NSImage *image, NSURL *URL, NSError *error);

@interface QImageManager : NSObject

- (void)downloadImageURL:(NSURL *)URL onCompletion:(QImageDowloadCompletion)onCompletion;

- (NSImage *)cachedImageForURL:(NSURL *)URL;

+ (instancetype)sharedImageManager;

@end
