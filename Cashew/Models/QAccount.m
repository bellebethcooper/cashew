//
//  QAccount.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QAccount.h"

@implementation QAccount


- (BOOL)isEqualToAccount:(id)object
{
    if (![object isKindOfClass:QAccount.class]) {
        return NO;
    }
    
    QAccount *otherAccount = (QAccount *)object;
//    if (![self.accountName isEqualToString:otherAccount.accountName]) {
//        return NO;
//    }
    if ( self.baseURL != otherAccount.baseURL && ![self.baseURL isEqual:otherAccount.baseURL]) {
        return NO;
    }
    
    if (![self.username isEqualToString:otherAccount.username]) {
        return NO;
    }
    
//    if (![self.password isEqualToString:otherAccount.password]) {
//        return NO;
//    }
    
    if ( self.userId != otherAccount.userId && ![self.userId isEqualTo:otherAccount.userId]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:QAccount.class]) {
        return false;
    }
    QAccount *other = (QAccount *)object;
    return [self isEqualToAccount:other] && [self.identifier isEqualToNumber:[other identifier]];
}

- (NSUInteger)hash
{
    return [self.identifier hash] ^ [self.baseURL hash] ^ [self.username hash] ^ [self.userId hash];
}

@end
