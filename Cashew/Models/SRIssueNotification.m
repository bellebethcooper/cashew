//
//  SRIssueNotification.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRIssueNotification.h"

@implementation SRIssueNotification

- (nonnull instancetype)initWithThreadId:(NSNumber * _Nonnull)threadId read:(BOOL)read reason:(NSString * _Nonnull)reason updatedAt:(NSDate * _Nonnull)updatedAt
{
    if ([self init]) {
        _threadId = threadId;
        _read = read;
        _reason = reason;
        _updatedAt = updatedAt;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"threadId=%@ read=%d, reason=%@, updatedAt=%@", _threadId, _read, _reason, _updatedAt];
}

@end
