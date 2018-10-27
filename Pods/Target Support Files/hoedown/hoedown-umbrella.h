#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "autolink.h"
#import "buffer.h"
#import "document.h"
#import "escape.h"
#import "html.h"
#import "stack.h"
#import "version.h"

FOUNDATION_EXPORT double hoedownVersionNumber;
FOUNDATION_EXPORT const unsigned char hoedownVersionString[];

