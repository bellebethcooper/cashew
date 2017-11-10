//
//  SRIssueCommentReaction.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRIssueCommentReaction.h"

@implementation SRIssueCommentReaction


- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:SRIssueCommentReaction.class]) {
        return false;
    }
    
    SRIssueCommentReaction *otherReaction = (SRIssueCommentReaction *)object;
    
    
    return [otherReaction.identifier isEqualToNumber:self.identifier] && [otherReaction.account isEqual:self.account];
}

- (NSUInteger)hash
{
    return self.account.hash ^ self.identifier.hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"SRIssueReaction - %@ %@ %@ %@", self.identifier, self.account.identifier, self.repository.identifier, self.content];
}

@end
