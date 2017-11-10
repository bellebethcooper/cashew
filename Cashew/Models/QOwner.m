//
//  QOwner.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QOwner.h"

@implementation QOwner

+ (instancetype)fromJSON:(NSDictionary *)dict
{
    QOwner *owner = [QOwner new];
    
    owner.login = dict[@"login"];
    owner.avatarURL = [NSURL URLWithString:dict[@"avatar_url"]];
    owner.identifier = dict[@"id"];
    owner.type = dict[@"type"];
    owner.htmlURL = [NSURL URLWithString:dict[@"html_url"]];
    
    NSParameterAssert(owner.login);
    NSParameterAssert(owner.avatarURL);
    NSParameterAssert(owner.identifier);
    NSParameterAssert(owner.type);
    
    return owner;
}

- (NSDictionary *)toExtensionModel
{
    NSMutableDictionary *model = [NSMutableDictionary new];
    
    model[@"login"] = self.login;
    model[@"avatarURL"] = self.avatarURL ?: NSNull.null;
    model[@"identifier"] = self.identifier;
    model[@"type"] = self.type;
    //model[@"htmlURL"] = self.htmlURL ?: NSNull.null;
    
    return model;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"'%@' -> %@", self.login, self.type];
}

- (BOOL)isEqual:(id<NSObject>)other
{
    if (other == self) {
        return YES;
    } else if (other && [other isKindOfClass:QOwner.class]) {
        QOwner *otherOwner = (QOwner *)other;
        return [self.identifier isEqualToNumber:otherOwner.identifier] && [self.account isEqualToAccount:otherOwner.account];
    }
    return false;
}

- (NSUInteger)hash {
    return [self.account.identifier hash] ^ [self.identifier hash];
}


@end
