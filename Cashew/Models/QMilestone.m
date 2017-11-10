//
//  QMilestone.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/20/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QMilestone.h"

@implementation QMilestone

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
    if (_account != account) {
        _account = account;
    }
    [self.repository setAccount:_account];
    [self.creator setAccount:_account];
}

- (NSDictionary *)toExtensionModel
{
    NSMutableDictionary *model = [NSMutableDictionary new];
    
    model[@"createdAt"] = self.createdAt ?: NSNull.null;
    model[@"closedAt"] = self.closedAt ?: NSNull.null;
    model[@"creator"] = [self.creator toExtensionModel];
    model[@"title"] = self.title;
    model[@"description"] = self.desc ?: NSNull.null;
    model[@"identifier"] = self.identifier;
    model[@"dueOn"] = self.dueOn ?: NSNull.null;
    model[@"isOpen"] = @([self.state isEqualToString:@"open"]);
    model[@"updateAt"] = self.updatedAt ?: NSNull.null;
    model[@"number"] = self.number ?: NSNull.null;
    model[@"repository"] = [self.repository toExtensionModel];
    
    return model;
}


+ (instancetype)fromJSON:(NSDictionary *)dict
{
    QMilestone *milestone = [QMilestone new];
    
    milestone.createdAt = (dict[@"created_at"] == [NSNull null]) ? nil : [[QMilestone _githubDateFormatter] dateFromString:dict[@"created_at"]];
    milestone.closedAt = (dict[@"closed_at"] == [NSNull null]) ? nil : [[QMilestone _githubDateFormatter] dateFromString:dict[@"closed_at"]];
    milestone.updatedAt = (dict[@"updated_at"] == [NSNull null]) ? nil : [[QMilestone _githubDateFormatter] dateFromString:dict[@"updated_at"]];
    milestone.dueOn = (dict[@"due_on"] == [NSNull null]) ? nil : [[QMilestone _githubDateFormatter] dateFromString:dict[@"due_on"]];
    milestone.identifier = dict[@"id"];
    if (milestone.identifier && dict[@"creator"]) {
        milestone.creator = [QOwner fromJSON:dict[@"creator"]];
    }
    milestone.title = dict[@"title"];
    milestone.desc = dict[@"description"];
    milestone.number = dict[@"number"];
    milestone.state = dict[@"state"];
    
    return milestone;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"'%@' due by %@", self.title, self.dueOn];
}

- (BOOL)isEqual:(id<NSObject>)other
{
    if (other == self) {
        return YES;
    } else if (other && [other isKindOfClass:QMilestone.class]) {
        QMilestone *otherMilestone = (QMilestone *)other;
        return [self.identifier isEqualToNumber:otherMilestone.identifier] && [self.account isEqualToAccount:otherMilestone.account];
    }
    return false;
}

- (NSUInteger)hash {
    return [self.account.identifier hash] ^ [self.identifier hash];
}

@end

