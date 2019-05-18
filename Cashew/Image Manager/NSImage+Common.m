//
//  NSImage+Common.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "NSImage+Common.h"

@implementation NSImage (Common)

- (NSImage *)imageWithTintColor:(NSColor *)tint;
{
    NSImage *image = [self copy];
    [image setTemplate:NO];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
        [image unlockFocus];
    }
    return image;
}

@end
