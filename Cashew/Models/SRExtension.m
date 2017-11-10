//
//  SRExtension.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRExtension.h"

@implementation SRExtension

- (nonnull instancetype)initWithSourceCode:(NSString * _Nonnull)sourceCode externalId:(NSString * _Nonnull)externalId name:(NSString * _Nonnull)name extensionType:(SRExtensionType)extensionType draftSourceCode:(NSString * _Nullable)draftSourceCode keyboardShortcut:(NSString * _Nullable)keyboardShortcut updatedAt:(NSDate *)updatedAt;
{
    if (self = [super init]) {
        self.sourceCode = sourceCode;
        self.externalId = externalId;
        self.name = name;
        self.extensionType = extensionType;
        self.draftSourceCode = draftSourceCode;
        self.keyboardShortcut = keyboardShortcut;
        self.updatedAt = updatedAt;
    }
    
    return self;
}


- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:SRExtension.class]) {
        return false;
    }
    SRExtension *other = (SRExtension *)object;
    
    return [other.externalId isEqual:self.externalId];
}

- (NSUInteger)hash
{
    return self.externalId.hash;
}

@end
