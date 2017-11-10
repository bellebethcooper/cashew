//
//  QRepository.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QRepository.h"

@implementation QRepository

+ (instancetype)fromJSON:(NSDictionary *)dict
{
    NSNumber *identifier = dict[@"id"];
    NSString *name = dict[@"name"];
    NSString *fullName = dict[@"full_name"];
    NSString *desc = dict[@"description"];
    
    QRepository *repo = [QRepository new];
    [repo setIdentifier:identifier];
    [repo setName:name];
    [repo setFullName:fullName];
    
    if (![desc isKindOfClass:NSNull.class]) {
        [repo setDesc:desc];
    }
    
    QOwner *owner = [QOwner fromJSON:dict[@"owner"]];
    repo.owner = owner;
    
    return repo;
}

- (NSDictionary *)toExtensionModel
{
    NSMutableDictionary *model = [NSMutableDictionary new];
    
    model[@"fullName"] = self.fullName;
    model[@"identifier"] = self.identifier;
    model[@"description"] = self.desc ?: NSNull.null;
    model[@"name"] = self.name;
    model[@"owner"] = [self.owner toExtensionModel];
    
    return model;
}

- (void)setAccount:(QAccount *)account
{
    if (_account != account) {
        _account = account;
    }
    self.owner.account = _account;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"id=%@ fullName=%@", _identifier, _fullName];
}

- (BOOL)isEqual:(id<NSObject>)other
{
    if (other == self) {
        return YES;
    } else if (other && [other isKindOfClass:QRepository.class]) {
        QRepository *otherRepo = (QRepository *)other;
        return [self.identifier isEqualToNumber:otherRepo.identifier] && [self.account isEqualToAccount:otherRepo.account];
    }
    return false;
}

- (NSUInteger)hash {
    return [self.account.identifier hash] ^ [self.identifier hash];
}

@end
