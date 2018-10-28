//
//  QUserService.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QUserService.h"
#import "QOwner.h"
#import "Cashew-Swift.h"

static NSString * const kGithubClientSecret = @"83352b2a1a5e3c33d234d4c92f225cb9d3d6d7f3";
static NSString * const kGithubClientId = @"93db7ca9566294386a8c";

@implementation QUserService

// GET /user
- (void)loginUserOnCompletion:(QServiceOnCompletion)onCompletion
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    
    if (self.account) {
        NSString *password = [[QContext sharedContext] passwordForLogin:self.account.username];
        DDLogDebug(@"QUserService loginUserOnCompl - password: %@", password);
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.account.username password:password];
    }
    
    //    if (twoFactorAuthCode) {
    //        [manager.requestSerializer setValue:twoFactorAuthCode forHTTPHeaderField:@"X-GitHub-OTP"];
    //    }
    [manager GET:@"user"
      parameters:@{} progress:nil onCompletion:^(NSDictionary *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              
              QOwner *owner = [QOwner fromJSON:responseObject];
              owner.account = self.account;
              
              //DDLogDebug(@"responseObject %@", responseObject);
              onCompletion(owner, context, nil);
          }
      }];
}

- (void)currentUserOnCompletion:(QServiceOnCompletion)onCompletion
{
    QAFHTTPSessionManager *manager = [self httpSessionManager];
    [manager GET:@"user"
      parameters:@{} progress:nil onCompletion:^(NSDictionary *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              QOwner *owner = [QOwner fromJSON:responseObject];
              owner.account = self.account;
              onCompletion(owner, context, nil);
          }
      }];
}



// DELETE /applications/:client_id/tokens/:access_token
- (void)logoutUserOnCompletion:(QServiceOnCompletion)onCompletion;
{
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:nil skipAuthToken:NO];
    
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:kGithubClientId password:kGithubClientSecret];
    
    // NSParameterAssert(self.account.authToken);
    [manager DELETE:[NSString stringWithFormat:@"applications/%@/tokens/%@", kGithubClientId, self.account.authToken]
         parameters:@{} onCompletion:^(NSDictionary *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
             onCompletion(nil, context, error);
         }];
}

//PUT /authorizations/clients/:client_id
- (void)currentUserAuthTokenWithTwoFactorAuthCode:(NSString *)twoFactorAuthCode onCompletion:(QServiceOnCompletion)onCompletion {
    DDLogDebug(@"QUserService currentUserAuthTokenWithTwoFactor");
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer] skipAuthToken: true];
    
    if (self.account) {
        NSString *password = [[QContext sharedContext] passwordForLogin:self.account.username];
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.account.username password:password];
    }
    
    if (twoFactorAuthCode && twoFactorAuthCode.length > 0) {
        [manager.requestSerializer setValue:twoFactorAuthCode forHTTPHeaderField:@"X-GitHub-OTP"];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    params[@"client_secret"] = kGithubClientSecret;
    params[@"client_id"] = kGithubClientId;
    params[@"note"] = [[[NSUUID alloc] init] UUIDString];
    params[@"scopes"] =  @[@"repo", @"read:org"];
    
    
    [manager POST:@"authorizations" //[NSString stringWithFormat:@"/authorizations/clients/%@", kGithubClientId]
       parameters:params progress:nil onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
           DDLogDebug(@"QUserService currentUserAuthToken - POST completion");
           if (error) {
               DDLogDebug(@"json %@", error ? [[NSString alloc] initWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding] : json);
               onCompletion(nil, context, error);
           } else {
               
               dispatch_async(dispatch_get_main_queue(), ^{
                   [manager POST:@"user"
                      parameters:@{} progress:nil onCompletion:^(NSDictionary *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
                          if (error && !json[@"token"]) {
                              onCompletion(nil, context, error);
                          } else {
                              
                              QOwner *owner = [QOwner fromJSON:responseObject];
                              owner.account = self.account;
                              
                              DDLogDebug(@"QUSerService currentUserAuthToken - responseObject %@", responseObject);
                              onCompletion(@{@"owner": owner, @"token": json[@"token"]}, context, nil);
                          }
                      }];
               });
           }
       }];
}

- (void)sendSMSIfNeeded;
{
    [self currentUserAuthTokenWithTwoFactorAuthCode:nil onCompletion:^(id  _Nullable obj, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
        DDLogDebug(@"error_json %@", error ? [[NSString alloc] initWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding] : obj);
    }];
}

// GET /user/orgs
- (void)currentUserOrganizationsOnCompletion:(QServiceOnCompletion)onCompletion;
{
    [self _currentUserOrganizationsOnCompletion:onCompletion pageNumber:0 pageSize:100 orgs:[NSMutableArray new]];
}

- (void)_currentUserOrganizationsOnCompletion:(QServiceOnCompletion)onCompletion pageNumber:(NSUInteger)pageNumber pageSize:(NSUInteger)pageSize orgs:(NSMutableArray *)orgs
{
    //NSMutableDictionary *params = params = @{ @"page": @(pageNumber), @"per_page": @(pageSize) }.mutableCopy;
    NSDictionary *params = params = @{ @"page": @(pageNumber) };
//    QAFHTTPSessionManager *manager = [self httpSessionManager];
    QAFHTTPSessionManager *manager = [self httpSessionManagerForRequestSerializer:[AFJSONRequestSerializer serializer] skipAuthToken: true];
    
    if (self.account) {
        NSString *password = [[QContext sharedContext] passwordForLogin:self.account.username];
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.account.username password:password];
    }
    [manager GET:@"user/orgs"
      parameters:params progress:nil onCompletion:^(NSArray *responseObject, QServiceResponseContext * _Nonnull context, NSError *error) {
          if (error) {
              onCompletion(nil, context, error);
          } else {
              for (NSDictionary *json in responseObject) {
                  Organization *org = [Organization fromJSON:json account: self.account];
                  [orgs addObject:org];
              }
              
              if (context.nextPageNumber) {
                  [self _currentUserOrganizationsOnCompletion:onCompletion pageNumber:context.nextPageNumber.unsignedIntegerValue pageSize:pageSize orgs:orgs];
              } else {
                  onCompletion(orgs, context, nil);
              }
          }
      }];
}



@end
