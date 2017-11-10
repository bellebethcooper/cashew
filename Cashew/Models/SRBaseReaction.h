//
//  SRBaseReaction.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QOwner.h"
#import "QRepository.h"


NS_ASSUME_NONNULL_BEGIN

@interface SRBaseReaction : NSObject

@property (nonatomic) NSNumber *identifier;
@property (nonatomic) QOwner *user;
@property (nonatomic) QRepository *repository;
@property (nonatomic) NSString *content;
@property (nonatomic) NSDate *createdAt;
@property (nonatomic) QAccount *account;

+ (instancetype)fromJSON:(NSDictionary *)json;
@end


NS_ASSUME_NONNULL_END