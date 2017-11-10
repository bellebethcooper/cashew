//
//  QIssueMarkdownWebView.h
//  Issues
//
//  Created by Hicham Bouabdallah on 5/25/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QView.h"


typedef void(^QIssueMarkdownWebViewFrameLoadCompletion)(NSRect rect);
typedef void(^QIssueMarkdownWebViewDidResize)(NSRect rect);

@interface QIssueMarkdownWebView : QView

@property (nonatomic, copy) QIssueMarkdownWebViewDidResize didResizeBlock;
@property (nonatomic, copy) dispatch_block_t didDoubleClick;
@property (nonatomic, readonly) NSArray<NSURL *> *imageURLs;
@property (nonatomic, copy) void(^didClickImageBlock)(NSURL *url);
//@property (nonatomic) BOOL scrollingEnabled;

- (instancetype)initWithHTMLString:(NSString *)html onFrameLoadCompletion:(QIssueMarkdownWebViewFrameLoadCompletion)block;
- (instancetype)initWithHTMLString:(NSString *)html onFrameLoadCompletion:(QIssueMarkdownWebViewFrameLoadCompletion)block scrollingEnabled:(BOOL)scrollingEnabled forceLightMode:(BOOL)foreLightMode;

@end
