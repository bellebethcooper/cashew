//
//  QIssueMarkdownWebView.m
//  Issues
//
//  Created by Hicham Bouabdallah on 5/25/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueMarkdownWebView.h"
#import "Cashew-Swift.h"
#import <WebKit/WebKit.h>



@interface _QIssueMarkdownWebViewBridge : NSObject

@property (nonatomic, copy) void(^didClickImageBlock)(NSURL *url);

- (void)didClickImage:(NSString *)urlString;

@end

@implementation _QIssueMarkdownWebViewBridge


- (void)didClickImage:(NSString *)urlString;
{
    void(^didClickImageBlock)(NSURL *) = self.didClickImageBlock;
    if (didClickImageBlock) {
        didClickImageBlock([NSURL URLWithString:urlString]);
    }
}

+ (NSString *) webScriptNameForSelector:(SEL)sel
{
    NSString *name = nil;
    if (sel == @selector(didClickImage:))
        name = @"didClickImage";
    
    return name;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(didClickImage:)) return NO;
    return YES;
}

@end

@interface QIssueMarkdownWebView () <WebFrameLoadDelegate, WebPolicyDelegate, WebUIDelegate>
@property (nonnull, nonatomic, copy) QIssueMarkdownWebViewFrameLoadCompletion onFrameLoadCompletion;
//@property (nonatomic) NSRect contentFrame;
@property (nonatomic) WebView *webView;
@property (nonatomic) _QIssueMarkdownWebViewBridge *webViewBridge;
@property (nonatomic, readwrite) NSArray<NSURL *> *imageURLs;
@end

@implementation QIssueMarkdownWebView

- (void)dealloc
{
    // DDLogDebug(@"dealloc-ing %@", self);
    [self.webView setFrameLoadDelegate:nil];
    [self.webView setPolicyDelegate:nil];
    [self.webView setUIDelegate:nil];
}

- (void)setDidClickImageBlock:(void (^)(NSURL *))didClickImageBlock
{
    _didClickImageBlock = didClickImageBlock;
    self.webViewBridge.didClickImageBlock = didClickImageBlock;
}

+ (NSString *)_contentForResource:(NSString *)resource ofType:(NSString *)type
{
    NSString *key = [NSString stringWithFormat:@"%@.%@", resource, type];
    static dispatch_once_t onceToken;
    static NSMutableDictionary<NSString *, NSString *> *dictionary = nil;
    static dispatch_queue_t accessQueue = nil;
    dispatch_once(&onceToken, ^{
        accessQueue = dispatch_queue_create("co.cashewapp.QIssueMarkdownWebView.accessQueue", DISPATCH_QUEUE_SERIAL);
        dictionary = [NSMutableDictionary dictionary];
    });
    
    
    __block NSString *content = dictionary[key];
    
    if (!content) {
        dispatch_sync(accessQueue, ^{
            NSString *filepath = [[NSBundle mainBundle] pathForResource:resource ofType:type];
            content = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:NULL];
            dictionary[key] = content;
        });
    }
    
    return content;
}
- (instancetype)initWithHTMLString:(NSString *)html onFrameLoadCompletion:(QIssueMarkdownWebViewFrameLoadCompletion)block
{
    return [self initWithHTMLString:html onFrameLoadCompletion:block scrollingEnabled:NO forceLightMode:false];
}

- (instancetype)initWithHTMLString:(NSString *)html onFrameLoadCompletion:(QIssueMarkdownWebViewFrameLoadCompletion)block scrollingEnabled:(BOOL)scrollingEnabled forceLightMode:(BOOL)forceLightMode;
{
    self = [super init];
    if (self) {
        self.imageURLs = [self _parseImageURLsForHTML:html];
        self.onFrameLoadCompletion = block;
        NSParameterAssert([NSThread isMainThread]);
        self.webView = [WebView new];
        [self addSubview:self.webView];
        
        //turn off scrollbars in the frame
        [[[self.webView mainFrame] frameView] setAllowsScrolling:scrollingEnabled];
        [self.webView setFrameLoadDelegate:self];
        [self.webView setPolicyDelegate:self];
        [self.webView setUIDelegate:self];
        
        
        // setup webview bridge
        self.webViewBridge = [_QIssueMarkdownWebViewBridge new];
        //__weak QIssueMarkdownWebView *weakSelf = self;
        self.webViewBridge.didClickImageBlock = self.didClickImageBlock;
        id win = [self.webView windowScriptObject];
        [win setValue:self.webViewBridge forKey:@"Cashew"];
        
        
        // inject content
        NSString *htmlBody = html;
        NSMutableString *styledHTML = [NSMutableString new];
        [styledHTML appendString:@"<html>"];
        [styledHTML appendString:@"<head>"];
        
        
        [styledHTML appendString:@"\n<style>"];
        SRThemeMode mode = forceLightMode ? SRThemeModeLight : [NSUserDefaults themeMode];
        if (mode == SRThemeModeLight) {
            NSString *cssFileContent = [QIssueMarkdownWebView _contentForResource:@"light-markdown" ofType:@"css"];
            [styledHTML appendString:cssFileContent];
        } else if (mode == SRThemeModeDark) {
            NSString *cssFileContent = [QIssueMarkdownWebView _contentForResource:@"dark-markdown" ofType:@"css"];
            [styledHTML appendString:cssFileContent];
        }
        [styledHTML appendString:@"</style>\n"];
        
        if (!scrollingEnabled) {
            [styledHTML appendString:@"\n<style> \nhtml, body {margin: 0; height: 100%; overflow-y: hidden} \n </style>\n"];
        }
        
        
        if ([htmlBody containsString:@"<code class=\"language"]) {
            // DDLogDebug(@"\n\nhtmlBody = %@\n\n", htmlBody);
            [styledHTML appendString:@"\n<style>\n"];
            NSString *txtFileContents = [QIssueMarkdownWebView _contentForResource:@"prism" ofType:@"css"];
            [styledHTML appendString:@"\n"];
            [styledHTML appendString:txtFileContents];
            [styledHTML appendString:@"\n"];
            [styledHTML appendString:@"\n</style>\n"];
            
            [styledHTML appendString:@"\n<script>\n"];
            txtFileContents = [QIssueMarkdownWebView _contentForResource:@"prism" ofType:@"js"];
            [styledHTML appendString:@"\n"];
            [styledHTML appendString:txtFileContents];
            [styledHTML appendString:@"\n</script>\n"];
        }
        
        [styledHTML appendString:@"\n<script>\n"];
        NSString *jsFileContent = [QIssueMarkdownWebView _contentForResource:@"markdown" ofType:@"js"];
        [styledHTML appendString:jsFileContent];
        [styledHTML appendString:@"\n</script>\n"];
        
        [styledHTML appendString:@"</head>"];
        [styledHTML appendString:@"<body>"];
        [styledHTML appendString:@"<div id='markdown_container'>"];
        [styledHTML appendString:htmlBody];
        [styledHTML appendString:@"</div>"];
        [styledHTML appendString:@"</body>"];
        [styledHTML appendString:@"</html>"];
        
        [self.webView.mainFrame loadHTMLString:styledHTML baseURL:nil];
        self.webView.drawsBackground = false;
    }
    return self;
}

- (NSArray<NSURL *> *)_parseImageURLsForHTML:(NSString *)html
{
    NSError *error = NULL;
    NSString *pattern = @"<img[^>]+src=\"([^\">]+)\"";
    NSRange range = NSMakeRange(0, html.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:html options:0 range:range];
    __block NSMutableArray<NSURL *> *urls = [NSMutableArray new];
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSRange sourceRange = [match rangeAtIndex:1];
        
        NSString *source = [[html substringWithRange:sourceRange] trimmedString];
        if (source.length > 0) {
            NSURL *url = [NSURL URLWithString:source];
            if (url) {
                [urls addObject:url];
            }
        }
    }];
    
    return [urls copy];
}

- (void)layout {
    self.webView.frame = self.bounds;
    
    NSRect newWebViewRect = [self _calculateFrame];
    QIssueMarkdownWebViewDidResize didResize = self.didResizeBlock;
    if (didResize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            didResize(newWebViewRect);
        });
    }
    [super layout];
}

#pragma mark - WebUIDelegate
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems;
{
    if (defaultMenuItems.count == 1) {
        NSMenuItem *menuItem = (NSMenuItem *)defaultMenuItems.firstObject;
        if (menuItem.tag == 12) {
            return @[];
        }
    }
    return defaultMenuItems;
}

- (NSUInteger)webView:(WebView *)sender dragSourceActionMaskForPoint:(NSPoint)point
{
    return WebDragSourceActionNone; // Disable any WebView content drag
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo
{
    return WebDragDestinationActionNone; // Disable any WebView content drop
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger) modifierFlags {
    if ([NSApp currentEvent].type == NSEventTypeLeftMouseUp && [NSApp currentEvent].clickCount == 2) {
        dispatch_block_t didDoubleClick = self.didDoubleClick;
        if (didDoubleClick) {
            didDoubleClick();
        }
    }
}

#pragma mark - WebPolicyDelegate
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    NSString *host = [[request URL] host];
    if (host) {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    } else {
        [listener use];
    }
}

#pragma mark - WebFrameLoadDelegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)webFrame
{
    WebView *webView = sender;
    if (!webView) {
        return;
    }
    if([webFrame isEqual:[webView mainFrame]])
    {
        NSRect newWebViewRect = [self _calculateFrame];
        //  self.contentFrame = newWebViewRect;
        QIssueMarkdownWebViewFrameLoadCompletion completion = self.onFrameLoadCompletion;
        if (completion) {
            completion(newWebViewRect);
        }
        
        //DDLogDebug(@"The dimensions of the page are: %@",NSStringFromRect(webFrameRect));
    }
}

- (NSRect)_calculateFrame
{
    //get the rect for the rendered frame
    NSRect webFrameRect = [[[[self.webView mainFrame] frameView] documentView] frame];
    //get the rect of the current webview
    NSRect webViewRect = [self frame];
    
    //calculate the new frame
    NSRect newWebViewRect = NSMakeRect(webViewRect.origin.x,
                                       webViewRect.origin.y - (NSHeight(webFrameRect) - NSHeight(webViewRect)),
                                       NSWidth(webViewRect),
                                       NSHeight(webFrameRect));
    
    NSString*   heightOutput    = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('markdown_container').scrollHeight;"];
    CGFloat   height          = [heightOutput floatValue];
    newWebViewRect = NSMakeRect(0, 0, newWebViewRect.size.width, height + 12 * 2 );
    
    return newWebViewRect;
}

@end
