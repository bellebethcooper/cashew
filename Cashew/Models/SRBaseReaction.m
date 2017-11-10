//
//  SRBaseReaction.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRBaseReaction.h"

@implementation SRBaseReaction

+ (NSDateFormatter *)_githubDateFormatter
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    });
    return formatter;
}

- (void)setAccount:(QAccount *)account
{
    _account = account;
    [self.user setAccount:account];
    [self.repository setAccount:account];
}

+ (instancetype)fromJSON:(NSDictionary *)json
{
    SRBaseReaction *reaction = [[self class] new];
    
    reaction.identifier = json[@"id"];
    reaction.user = [QOwner fromJSON:json[@"user"]];
    reaction.content = json[@"content"];
    reaction.createdAt = [[self _githubDateFormatter] dateFromString:json[@"created_at"]];
    
    return reaction;
}

@end
