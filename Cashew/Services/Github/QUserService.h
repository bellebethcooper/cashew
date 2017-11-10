//
//  QUserService.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseService.h"

@interface QUserService : QBaseService

- (void)loginUserOnCompletion:(QServiceOnCompletion)onCompletion;

- (void)currentUserOnCompletion:(QServiceOnCompletion)onCompletion;

// DELETE /applications/:client_id/tokens/:access_token
- (void)logoutUserOnCompletion:(QServiceOnCompletion)onCompletion;

//PUT /authorizations/clients/:client_id
- (void)currentUserAuthTokenWithTwoFactorAuthCode:(NSString *)twoFactorAuthCode onCompletion:(QServiceOnCompletion)onCompletion;

// GET /authorizations
- (void)sendSMSIfNeeded;

// GET /user/orgs
- (void)currentUserOrganizationsOnCompletion:(QServiceOnCompletion)onCompletion;

@end
