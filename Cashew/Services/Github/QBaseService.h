//
//  QBaseService.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QAccount.h"
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface QServiceResponseContext: NSObject

@property (nonatomic, nullable) NSNumber *contextId;

@property (nonatomic, readonly, nullable) NSDate *nextRateLimitResetDate;
@property (nonatomic, readonly, nullable) NSNumber *rateLimitRemaining;
@property (nonatomic, readonly, nullable) NSNumber *nextPageNumber;
@property (nonatomic, readonly) BOOL needTwoFactorAuth;
@property (nonatomic, readonly, nullable) NSHTTPURLResponse *response;
@property (nonatomic, readonly, nullable) NSDate *lastModified;
@end

NS_ASSUME_NONNULL_END

typedef void (^QServiceOnCompletion)(id _Nullable obj, QServiceResponseContext * _Nonnull context, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface QAFHTTPSessionManager : AFHTTPSessionManager

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable id)parameters
                      progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
                  onCompletion:(QServiceOnCompletion)onCompletion;

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(nullable id)parameters
                   onCompletion:(QServiceOnCompletion)onCompletion;

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(nullable id)parameters
                     progress:(nullable void (^)(NSProgress * _Nonnull))downloadProgress
                 onCompletion:(QServiceOnCompletion)onCompletion;

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(nullable id)parameters
                 onCompletion:(QServiceOnCompletion)onCompletion;

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(nullable id)parameters
                    onCompletion:(QServiceOnCompletion)onCompletion;


@property (nonatomic, readonly, nullable) QAccount *account;

+ (NSDateFormatter *)lastModifiedDateFormatter;

@end

@interface QBaseService : NSObject

@property (nonatomic, readonly) QAccount *account;

- (QAFHTTPSessionManager *)httpSessionManager;

- (QAFHTTPSessionManager *)httpSessionManagerForRequestSerializer:(nullable AFHTTPRequestSerializer *)requestSerializer;

- (QAFHTTPSessionManager *)httpSessionManagerForRequestSerializer:(nullable AFHTTPRequestSerializer *)requestSerializer skipAuthToken:(BOOL)skipAuthToken;

+ (instancetype)serviceForAccount:(QAccount *)account;

@end

NS_ASSUME_NONNULL_END