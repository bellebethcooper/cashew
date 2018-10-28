//
//  QImageManager.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QImageManager.h"
#import <Cocoa/Cocoa.h>
#import "Cashew-Swift.h"
#import "AppDelegate.h"

@interface QImageManager ()

@property (nonatomic) dispatch_queue_t accessQueue;

@end

@implementation QImageManager  {
    NSOperationQueue *_operationQueue;
    NSURLCache *_cache;
    NSMutableDictionary<NSString *, NSMutableArray<QImageDowloadCompletion> *> *_completionBlocks;
}



+ (instancetype)sharedImageManager
{
    static dispatch_once_t onceToken;
    static QImageManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [QImageManager new];
        manager->_operationQueue = [NSOperationQueue new];
        [manager->_operationQueue setMaxConcurrentOperationCount:5];
        
        
        // image cache
        AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
        NSURL *dbURL = [[appDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:@"imagecache"];
        
        if (![NSFileManager.defaultManager fileExistsAtPath:dbURL.path]) {
            NSError *err;
            [NSFileManager.defaultManager createDirectoryAtURL:dbURL withIntermediateDirectories:YES attributes:nil error:&err];
            NSParameterAssert(!err);
        }
        
        manager->_cache = [[NSURLCache alloc] initWithMemoryCapacity:300 * 1024 * 1024 diskCapacity:500 * 1024 * 1024 diskPath:dbURL.path];
        
        manager->_completionBlocks = [NSMutableDictionary new];
        
        manager.accessQueue = dispatch_queue_create("co.hellocode.cashew.image.downloader", DISPATCH_QUEUE_CONCURRENT);
        
    });
    
    return manager;
}

- (NSImage *)cachedImageForURL:(NSURL *)URL {
    __block NSImage *img = nil;
    dispatch_sync(self.accessQueue, ^{
        NSCachedURLResponse *response = [_cache cachedResponseForRequest:[NSURLRequest requestWithURL:URL]];
        img = [[NSImage alloc] initWithData:response.data];
    });
    
    return img;
}
- (void)downloadImageURL:(NSURL *)URL onCompletion:(QImageDowloadCompletion)onCompletion
{
    if (!URL) {
        return;
    }
    
    dispatch_barrier_async(self.accessQueue, ^{
        NSMutableArray<QImageDowloadCompletion> * completions = _completionBlocks[URL.absoluteString];
        BOOL imageDownloadRequestSubmitted = NO;
        if (!completions) {
            completions = [NSMutableArray new];
            _completionBlocks[URL.absoluteString] = completions;
        } else if (completions.count > 0) {
            imageDownloadRequestSubmitted = YES;
        }
        if (onCompletion) {
            [completions addObject:onCompletion];
        }
        
        if (imageDownloadRequestSubmitted == NO) {
            
            [_operationQueue addOperationWithBlock:^{
                NSURLRequest *cacheKey = [NSURLRequest requestWithURL:URL];
                NSCachedURLResponse *response = [_cache cachedResponseForRequest:cacheKey];
                NSImage *image = [[NSImage alloc] initWithData:response.data];
                
                if (!image) {
                   // DDLogDebug(@"download image = %@", URL);
                    
                    
                    NSURLResponse *aResponse = [[NSURLResponse alloc] initWithURL:URL MIMEType:nil expectedContentLength:0 textEncodingName:nil];
                    image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:URL]];
                    if (image){
                        NSCachedURLResponse *cacheURLResponse = [[NSCachedURLResponse alloc] initWithResponse:aResponse data:image.TIFFRepresentation userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
                        [_cache storeCachedResponse:cacheURLResponse forRequest:cacheKey];
                    }
                }
                
                if (image) {
                    [_completionBlocks[URL.absoluteString] enumerateObjectsUsingBlock:^(QImageDowloadCompletion completion, NSUInteger idx, BOOL * _Nonnull stop) {
                        QImageDowloadCompletion aCompletion = completion;
                        if (aCompletion) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                aCompletion(image, URL, nil);
                            });
                        }
                    }];
                } else {
                    [_completionBlocks[URL.absoluteString] enumerateObjectsUsingBlock:^(QImageDowloadCompletion completion, NSUInteger idx, BOOL * _Nonnull stop) {
                        QImageDowloadCompletion aCompletion = completion;
                        if (aCompletion) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                aCompletion(nil, URL, [NSError errorWithDomain:@"co.hellocode.cashew" code:404 userInfo:@{}]);
                            });
                        }
                    }];
                }
                
                dispatch_barrier_async(self.accessQueue, ^{
                    [_completionBlocks[URL.absoluteString] removeAllObjects];
                });
                
            }];
        }
    });
    
    
}

@end
