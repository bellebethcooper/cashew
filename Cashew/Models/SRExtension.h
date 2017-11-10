//
//  SRExtension.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef enum : NSUInteger {
    SRExtensionTypeIssue
} SRExtensionType;

NS_ASSUME_NONNULL_BEGIN
@interface SRExtension : NSObject

@property (nonatomic) NSString *sourceCode;
@property (nonatomic) NSString *externalId;
@property (nonatomic) NSString *name;
@property (nonatomic, nullable) NSString *draftSourceCode;
@property (nonatomic, nullable) NSString *keyboardShortcut;
@property (nonatomic) SRExtensionType extensionType;
@property (nonatomic) NSDate *updatedAt;

- (nonnull instancetype)initWithSourceCode:(NSString * _Nonnull)sourceCode externalId:(NSString * _Nonnull)externalId name:(NSString * _Nonnull)name extensionType:(SRExtensionType)extensionType draftSourceCode:(NSString * _Nullable)draftSourceCode keyboardShortcut:(NSString * _Nullable)keyboardShortcut updatedAt:(NSDate *)updatedAt NS_DESIGNATED_INITIALIZER;


- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
