//
//  QLabel.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/11/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QLabel.h"


@implementation QLabel

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

+ (instancetype)fromJSON:(NSDictionary *)dict
{
    QLabel *label = [QLabel new];
    
    NSParameterAssert(dict[@"name"] && [dict[@"name"] isKindOfClass:NSString.class]);
    NSParameterAssert(dict[@"color"] && [dict[@"color"] isKindOfClass:NSString.class]);
    
    [label setColor:dict[@"color"]];
    [label setName:dict[@"name"]];
    label.createdAt = [[QLabel _githubDateFormatter] dateFromString:dict[@"created_at"]];
    label.updatedAt = [[QLabel _githubDateFormatter] dateFromString:dict[@"updated_at"]];
    
    return label;
}

- (NSDictionary *)toExtensionModel
{
    NSMutableDictionary *model = [NSMutableDictionary new];
    
    model[@"name"] = self.name;
    model[@"color"] = self.color;
    
    return model;
}

- (BOOL)isEqual:(id<NSObject>)other
{
    if (other == self) {
        return YES;
    } else if (other && [other isKindOfClass:QLabel.class]) {
        QLabel *otherLabel = (QLabel *)other;
        return [self.name isEqualToString:otherLabel.name] && [self.account isEqualToAccount:otherLabel.account];
    }
    return false;
}

- (NSUInteger)hash {
    return [self.account.identifier hash] ^ [self.name hash];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ [%@]", self.name, self.color];
}

@end
