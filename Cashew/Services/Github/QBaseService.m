//
//  QBaseService.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseService.h"
#import "QCommonConstants.h"
#import "QAccountStore.h"
#import "QContext.h"
#import "Cashew-Swift.h"

@interface QServiceResponseContext ()
@property (nonatomic, readwrite) NSDate *nextRateLimitResetDate;
@property (nonatomic, readwrite) NSNumber *rateLimitRemaining;
@property (nonatomic, readwrite) BOOL needTwoFactorAuth;
@property (nonatomic, readwrite) NSNumber *nextPageNumber;
@property (nonatomic, readwrite, nullable) NSHTTPURLResponse *response;
@property (nonatomic, readwrite) NSDate *lastModified;
@end

@implementation QServiceResponseContext

@end

@interface QAFHTTPSessionManager ()
@property (nonatomic, readwrite, nullable) QAccount *account;
@end

@implementation QAFHTTPSessionManager

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
                      progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                  onCompletion:(QServiceOnCompletion)onCompletion
{
    //DDLogDebug(@"POST %@ %@", URLString, parameters);
    return [super POST:URLString
            parameters:parameters
              progress:uploadProgress
               success:[self _decorateSuccessCompletionBlock:onCompletion]
               failure:[self _decorateFailureCompletionBlock:onCompletion]];
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(id)parameters
                 onCompletion:(QServiceOnCompletion)onCompletion
{
    //DDLogDebug(@"PUT %@ %@", URLString, parameters);
    return [super PUT:URLString
           parameters:parameters
              success:[self _decorateSuccessCompletionBlock:onCompletion]
              failure:[self _decorateFailureCompletionBlock:onCompletion]];
}

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(id)parameters
                   onCompletion:(QServiceOnCompletion)onCompletion
{
    //DDLogDebug(@"PATCH %@ %@", URLString, parameters);
    return [super PATCH:URLString
             parameters:parameters
                success:[self _decorateSuccessCompletionBlock:onCompletion]
                failure:[self _decorateFailureCompletionBlock:onCompletion]];
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(id)parameters
                    onCompletion:(QServiceOnCompletion)onCompletion
{
    //DDLogDebug(@"DELETE %@ %@", URLString, parameters);
    return [super DELETE:URLString
              parameters:parameters
                 success:[self _decorateSuccessCompletionBlock:onCompletion]
                 failure:[self _decorateFailureCompletionBlock:onCompletion]];
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(id)parameters
                     progress:(void (^)(NSProgress * _Nonnull))downloadProgress
                 onCompletion:(QServiceOnCompletion)onCompletion
{
    //DDLogDebug(@"GET %@ %@", URLString, parameters);
    return [super GET:URLString
           parameters:parameters
             progress:downloadProgress
              success:[self _decorateSuccessCompletionBlock:onCompletion]
              failure:[self _decorateFailureCompletionBlock:onCompletion]];
}

#pragma mark - completion block
- (void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))_decorateSuccessCompletionBlock:(QServiceOnCompletion)onCompletion
{
    return ^(NSURLSessionDataTask *task, NSArray *responseObject) {
        QServiceResponseContext *context = [QServiceResponseContext new];
        context.response = (NSHTTPURLResponse *)task.response;
        [self _parseTwoFactorFromHTTPURLResponse:(NSHTTPURLResponse *)task.response forContext:context];
        [self _parseRateLimitFromHTTPURLResponse:(NSHTTPURLResponse *)task.response forContext:context];
        [self _parseNextPageNumberFromHTTPURLResponse:(NSHTTPURLResponse *)task.response forContext:context];
        [self _parseLastModifiedFromHTTPURLResponse:(NSHTTPURLResponse *)task.response forContext:context];
        
//        DDLogDebug(@"QBaseService Success - username: [%@] rate limit: [%@] [%@] URL => [%@]", self.account.username, context.rateLimitRemaining, context.nextRateLimitResetDate, task.currentRequest.URL);
        onCompletion(responseObject, context, nil);
    };
}

- (void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))_decorateFailureCompletionBlock:(QServiceOnCompletion)onCompletion
{
    return ^(NSURLSessionDataTask * task, NSError * error) {
        QServiceResponseContext *context = [QServiceResponseContext new];
        context.response = (NSHTTPURLResponse *)task.response;
        [self _parseTwoFactorFromHTTPURLResponse:(NSHTTPURLResponse *)task.response forContext:context];
        [self _parseRateLimitFromHTTPURLResponse:(NSHTTPURLResponse *)task.response forContext:context];
        [self _parseNextPageNumberFromHTTPURLResponse:(NSHTTPURLResponse *)task.response forContext:context];
        onCompletion(nil, context, error);
        NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
//        DDLogDebug(@"QBaseService Error - username: [%@] [%@][%@] - rate limit: [%@] [%@] URL => [%@]", self.account.username, @(statusCode), error && statusCode != 304 ? [[NSString alloc] initWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding] : @"", context.rateLimitRemaining, context.nextRateLimitResetDate, task.currentRequest.URL);
        
        
        if ( statusCode == 401 || statusCode == 403) {
            
            NSData *errJSONData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            BOOL rateLimitExceeded = false;
            BOOL insufficientScope = false;
            if (errJSONData) {
                NSError *jsonErr = nil;
                id object = [NSJSONSerialization JSONObjectWithData:errJSONData options:0 error:&jsonErr];
                if ([object isKindOfClass:NSDictionary.class]) {
                    NSString *errMessage = [object objectForKey:@"message"];
                    rateLimitExceeded = (errMessage && [errMessage containsString:@"API rate limit exceeded"]) || (errMessage && [errMessage containsString:@"Authenticated requests get a higher rate limit"]);
                    //rateLimitExceeded = (errMessage && [errMessage containsString:@"API rate limit exceeded"] && ![errMessage containsString:@"Authenticated requests get a higher rate limit"]);
                    insufficientScope = (errMessage && [errMessage.lowercaseString containsString:@"Insufficient scopes for reacting to this Issue".lowercaseString]);
                    
                }
            }
            
            
            if (!rateLimitExceeded && !insufficientScope) {
                NSArray<QAccount *> *accounts = [QAccountStore accounts];
                if (accounts.count <= 1) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kQForceLoginNotification object:nil];
                } else {
                    QAccount *currentAccount = [QContext sharedContext].currentAccount;
                    if (currentAccount && [currentAccount isEqual:self.account]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kSRShowAddAccountNotification object:currentAccount];
                    }
                }
            }
        }
    };
}

+ (NSDateFormatter *)lastModifiedDateFormatter
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [formatter setDateFormat:@"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"];
    });
    return formatter;
}

#pragma mark - Header Parsers
- (void)_parseTwoFactorFromHTTPURLResponse:(NSHTTPURLResponse *)httpResponse forContext:(QServiceResponseContext *)context
{
    if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        //DDLogDebug(@"dictionary => %@", dictionary);
        NSString *twoFactor = dictionary[@"X-GitHub-OTP"];
        //DDLogDebug(@"rateLimitRemaining = %@", rateLimitRemaining);
        if (twoFactor && [twoFactor hasPrefix:@"required"]) {
            context.needTwoFactorAuth = true;
        }
        
        NSNumber *rateLimitReset = dictionary[@"X-RateLimit-Reset"];
        if (rateLimitReset) {
            context.nextRateLimitResetDate = [NSDate dateWithTimeIntervalSince1970:rateLimitReset.doubleValue];
        }
    }
}

- (void)_parseRateLimitFromHTTPURLResponse:(NSHTTPURLResponse *)httpResponse forContext:(QServiceResponseContext *)context
{
    NSParameterAssert(context);
    
    if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        //DDLogDebug(@"dictionary => %@", dictionary);
        NSNumber *rateLimitRemaining = dictionary[@"X-RateLimit-Remaining"];
        //DDLogDebug(@"rateLimitRemaining = %@", rateLimitRemaining);
        if (rateLimitRemaining) {
            context.rateLimitRemaining = rateLimitRemaining;
        }
        
        NSNumber *rateLimitReset = dictionary[@"X-RateLimit-Reset"];
        if (rateLimitReset) {
            context.nextRateLimitResetDate = [NSDate dateWithTimeIntervalSince1970:rateLimitReset.doubleValue];
        }
    }
}

- (void)_parseLastModifiedFromHTTPURLResponse:(NSHTTPURLResponse *)httpResponse forContext:(QServiceResponseContext *)context
{
    NSParameterAssert(context);
    
    if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        //DDLogDebug(@"dictionary => %@", dictionary);
        NSString *lastModifiedString = dictionary[@"Last-Modified"];
        //DDLogDebug(@"rateLimitRemaining = %@", rateLimitRemaining);
        if (lastModifiedString) {
            context.lastModified = [[QAFHTTPSessionManager lastModifiedDateFormatter] dateFromString:lastModifiedString];
        }
    }
}

- (void)_parseNextPageNumberFromHTTPURLResponse:(NSHTTPURLResponse *)httpResponse forContext:(QServiceResponseContext *)context
{
    NSParameterAssert(context);
    NSString *link = nil;
    if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        link = dictionary[@"Link"];
    }
    
    if (!link) {
        context.nextPageNumber = nil;
        return;
    }
    
    NSError *error = NULL;
    NSString *pattern = @".*?page\\=(\\d+).*?\\;\\s*?rel\\=\\\"(.*?)\\\"";
    NSRange range = NSMakeRange(0, link.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:link options:0 range:range];
    
    //DDLogDebug(@"matches=%@", matches);
    __block NSNumber *number = nil;
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSRange relRange = [match rangeAtIndex:2];
        NSString *rel = [link substringWithRange:relRange];
        if ([rel isEqualToString:@"next"]) {
            NSRange pageRange = [match rangeAtIndex:1];
            NSString *page = [link substringWithRange:pageRange];
            if (page != nil) {
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                number = [f numberFromString:page];
                *stop = YES;
            }
        }
    }];
    
    context.nextPageNumber = number;
}

@end




@implementation QBaseService {
    // AFHTTPSessionManager *_httpSessionManager;
}

+ (NSCache *)_servicesCache
{
    static dispatch_once_t onceToken;
    static NSCache *cache;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    return cache;
}

+ (dispatch_queue_t)_httpBackgroundQueue
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("co.hellocode.cashew.http.background", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

+ (instancetype)serviceForAccount:(QAccount *)account;
{
    NSParameterAssert(account);
    NSCache *cache = [[self class] _servicesCache];
//    DDLogDebug(@"QBaseService serviceForAccount - account id = %@", account.identifier);
    NSString *key = [NSString stringWithFormat:@"%@_%@", account.identifier, NSStringFromClass([self class])];
    QBaseService *service = [cache objectForKey:key];
    
    if (service == nil) {
        service = [[[self class] alloc] init];
        [cache setObject:service forKey:key];
    }
    
    [service setAccount:account];
    
    return service;
}

+ (void)removeServiceForAccount:(QAccount *)account
{
    NSString *key = [NSString stringWithFormat:@"%@_%@", account.identifier, NSStringFromClass([self class])];
    NSCache *cache = [[self class] _servicesCache];
    [cache removeObjectForKey:key];
}

- (QAFHTTPSessionManager *)httpSessionManager
{
    return [self httpSessionManagerForRequestSerializer:nil];
}

- (QAFHTTPSessionManager *)httpSessionManagerForRequestSerializer:(AFHTTPRequestSerializer *)requestSerializer
{
    return [self httpSessionManagerForRequestSerializer:requestSerializer skipAuthToken:false];
}

- (QAFHTTPSessionManager *)httpSessionManagerForRequestSerializer:(AFHTTPRequestSerializer *)requestSerializer skipAuthToken:(BOOL)skipAuthToken
{
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    [sessionConfig setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    QAFHTTPSessionManager *manager = [[QAFHTTPSessionManager alloc] initWithBaseURL:self.account.baseURL sessionConfiguration:sessionConfig];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.account = self.account;
    if (requestSerializer) {
        [manager setRequestSerializer:requestSerializer];
    }
    
    if (!skipAuthToken && self.account && self.account.authToken) {
        //NSParameterAssert(self.account.authToken);
        //DDLogDebug(@" --> Using auth token = [%@]", self.account.authToken);
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"token %@", self.account.authToken] forHTTPHeaderField:@"Authorization"];
    }
    
    
    [manager.requestSerializer setTimeoutInterval:60.0];
    manager.completionQueue = [QBaseService _httpBackgroundQueue];
    return manager;
}

- (void)setAccount:(QAccount *)account
{
    if (_account != account) {
        _account = account;
        NSString *password = [[QContext sharedContext] passwordForLogin:self.account.username];
        [self.httpSessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:_account.username password:password];
    }
}

@end
