//
//  QIssueMarkdownWebView.m
//  Issues
//
//  Created by Hicham Bouabdallah on 5/25/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueMarkdownWebView.h"
#import "Cashew-Swift.h"

@import os.log;
@import WebKit;

@interface _QIssueWebViewUserContentController : WKUserContentController
@property (nonatomic, copy) void (^didClickImageBlock)(NSURL *url);
@end

@implementation _QIssueWebViewUserContentController
@end

@interface _QIssueWebViewImageClickHandler : NSObject <WKScriptMessageHandler>
@end

@implementation _QIssueWebViewImageClickHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.body isKindOfClass:[NSString class]] == NO ||
        [userContentController isKindOfClass:[_QIssueWebViewUserContentController class]] == NO)
    {
        return;
    }

    NSString *urlString = (NSString *)message.body;
    _QIssueWebViewUserContentController *controller = (_QIssueWebViewUserContentController *)userContentController;

    void (^didClickImageBlock)(NSURL *) = controller.didClickImageBlock;
    if (didClickImageBlock)
    {
        didClickImageBlock([NSURL URLWithString:urlString]);
    }
}

@end

@interface _QIssueWebView : WKWebView
@end

@implementation _QIssueWebView

- (void)scrollWheel:(NSEvent *)event
{
    // AppKit's version of WKWebView does not expose the internal scroll view, so we just ignore scroll events.
    // This produces the desired effect.
    [[self nextResponder] scrollWheel:event];
}

- (void)willOpenMenu:(NSMenu *)menu withEvent:(NSEvent *)event
{
    if (menu.itemArray.count == 1 && menu.itemArray.firstObject.tag == 12)
    {
        for (NSMenuItem *menuItem in menu.itemArray)
        {
            [menuItem setHidden:YES];
        }
    }
}

@end

@interface QIssueMarkdownWebView () <WKNavigationDelegate, WKUIDelegate>
@property (nonnull, nonatomic, copy) QIssueMarkdownWebViewFrameLoadCompletion onFrameLoadCompletion;

@property (strong) WKWebView *webView;
@property (strong) WKWebViewConfiguration *webViewConfiguration;
@property (strong) _QIssueWebViewUserContentController *userContentController;

@property (nonatomic, readwrite) NSArray<NSURL *> *imageURLs;
@end

@implementation QIssueMarkdownWebView

- (void)dealloc
{
    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
}

- (void)setDidClickImageBlock:(void (^)(NSURL *))didClickImageBlock
{
    _didClickImageBlock = didClickImageBlock;
    self.userContentController.didClickImageBlock = didClickImageBlock;
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

    if (!content)
    {
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
    return [self initWithHTMLString:html onFrameLoadCompletion:block forceLightMode:false];
}

- (instancetype)initWithHTMLString:(NSString *)html onFrameLoadCompletion:(QIssueMarkdownWebViewFrameLoadCompletion)block forceLightMode:(BOOL)forceLightMode;
{
    self = [super init];
    if (self)
    {
        NSParameterAssert([NSThread isMainThread]);

        self.imageURLs = [self _parseImageURLsForHTML:html];
        self.onFrameLoadCompletion = block;

        self.webViewConfiguration = [[WKWebViewConfiguration alloc] init];
        self.webViewConfiguration.suppressesIncrementalRendering = YES;

        self.userContentController = [[_QIssueWebViewUserContentController alloc] init];
        [self.userContentController addScriptMessageHandler:[[_QIssueWebViewImageClickHandler alloc] init] name:@"didClickImage"];
        self.userContentController.didClickImageBlock = self.didClickImageBlock;
        self.webViewConfiguration.userContentController = self.userContentController;

        self.webView = [[_QIssueWebView alloc] initWithFrame:self.bounds configuration:self.webViewConfiguration];
        self.webView.allowsLinkPreview = NO;
        self.webView.navigationDelegate = self;
        self.webView.UIDelegate = self;

        [self addSubview:self.webView];

        NSString *styledHTML = [self modifyHTML:html forceLightMode:forceLightMode];
        [self.webView loadHTMLString:styledHTML baseURL:nil];
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
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *_Nonnull match, NSUInteger idx, BOOL *_Nonnull stop) {

        NSRange sourceRange = [match rangeAtIndex:1];

        NSString *source = [[html substringWithRange:sourceRange] trimmedString];
        if (source.length > 0)
        {
            NSURL *url = [NSURL URLWithString:source];
            if (url)
            {
                [urls addObject:url];
            }
        }
    }];

    return [urls copy];
}

- (NSString *)modifyHTML:(NSString *)html forceLightMode:(BOOL)forceLightMode
{
    NSMutableString *styledHTML = [NSMutableString new];
    [styledHTML appendString:@"<html>"];
    [styledHTML appendString:@"<head>"];

    [styledHTML appendString:@"\n<style>"];
    SRThemeMode mode = forceLightMode ? SRThemeModeLight : [NSUserDefaults themeMode];
    if (mode == SRThemeModeLight)
    {
        NSString *cssFileContent = [QIssueMarkdownWebView _contentForResource:@"light-markdown" ofType:@"css"];
        [styledHTML appendString:cssFileContent];
    }
    else if (mode == SRThemeModeDark)
    {
        NSString *cssFileContent = [QIssueMarkdownWebView _contentForResource:@"dark-markdown" ofType:@"css"];
        [styledHTML appendString:cssFileContent];
    }
    [styledHTML appendString:@"</style>\n"];

    [styledHTML appendString:@"\n<style> \nhtml, body {margin: 0; height: 100%; overflow-y: hidden} \n </style>\n"];

    if ([html containsString:@"<code class=\"language"])
    {
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
    [styledHTML appendString:html];
    [styledHTML appendString:@"</div>"];
    [styledHTML appendString:@"</body>"];
    [styledHTML appendString:@"</html>"];

    return [styledHTML copy];
}

- (void)layout
{
    self.webView.frame = self.bounds;

    QIssueMarkdownWebViewDidResize didResize = self.didResizeBlock;
    if (didResize != nil)
    {
        [self retrieveBoundsFromWebView:self.webView
                      completionHandler:^(CGRect viewBounds) {
                          didResize(viewBounds);
                      }];
    }

    [super layout];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
{
    NSURL *requestURL = navigationAction.request.URL;
    NSString *host = requestURL.host;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated && [host isKindOfClass:[NSString class]])
    {
        [[NSWorkspace sharedWorkspace] openURL:requestURL];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    else
    {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    QIssueMarkdownWebViewFrameLoadCompletion completion = self.onFrameLoadCompletion;
    if (completion != nil)
    {
        [self retrieveBoundsFromWebView:webView
                      completionHandler:^(CGRect viewBounds) {
                          completion(viewBounds);
                      }];
    }
}

#pragma mark - Private Implementation

- (void)retrieveBoundsFromWebView:(WKWebView *)webView completionHandler:(void (^_Nullable)(CGRect viewBounds))completionHandler
{
    CGSize currentWebViewSize = webView.enclosingScrollView.contentSize;

    __weak typeof(self) weakSelf = self;
    [webView evaluateJavaScript:@"document.getElementById('markdown_container').scrollHeight"
              completionHandler:^(id response, NSError *error) {
                  __weak typeof(weakSelf) strongSelf = weakSelf;
                  CGRect webViewBounds = [strongSelf webViewBoundsFromJavascriptResponse:response currentSize:currentWebViewSize];
                  dispatch_async(dispatch_get_main_queue(), ^{
                      completionHandler(webViewBounds);
                  });
              }];
}

- (CGRect)webViewBoundsFromJavascriptResponse:(id)response currentSize:(CGSize)currentSize
{
    CGSize modifiedSize = currentSize;
    float height = [self calculateScrollHeightFromJavascriptResponse:response];
    if (height > 0)
    {
        modifiedSize.height = height;
    }

    CGRect webViewRect = [self paddedWebViewFrameForSize:modifiedSize];
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "%@: wants to resize to %@", NSStringFromSelector(_cmd), NSStringFromRect(webViewRect));
    return webViewRect;
}

- (float)calculateScrollHeightFromJavascriptResponse:(id)response
{
    NSAssert(response == nil || [response isKindOfClass:[NSNumber class]], @"Scroll height evaluation returned an unexpected response type.");

    NSNumber *heightOutput = (NSNumber *)response ?: @(0);
    float height = heightOutput.floatValue;

    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "%@: %g", NSStringFromSelector(_cmd), height);

    return height;
}

- (CGRect)paddedWebViewFrameForSize:(CGSize)size
{
    return CGRectMake(0, 0, size.width, size.height + 12 * 2);
}

@end
