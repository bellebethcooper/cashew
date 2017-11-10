//
//  QMilestone.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/20/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QOwner.h"
#import "QRepository.h"

@interface QMilestone : NSObject

@property (nonatomic, strong) QAccount *account;
@property (nonatomic, strong) QRepository *repository;
@property (nonatomic, strong) QOwner *creator;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *closedAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSDate *dueOn;
@property (nonatomic, strong) NSNumber *identifier;

+ (instancetype)fromJSON:(NSDictionary *)dict;
- (NSDictionary *)toExtensionModel;

@end
