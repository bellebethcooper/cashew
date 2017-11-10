//
//  QRepository.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QOwner.h"
#import "QAccount.h"

@interface QRepository : NSObject

@property (nonatomic) QAccount *account;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *fullName;
@property (nonatomic) NSNumber *identifier;
@property (nonatomic) NSString *desc;
@property (nonatomic) QOwner *owner;
@property (nonatomic, assign) BOOL initialSyncCompleted;
@property (nonatomic) NSDate *deltaSyncDate;
@property (nonatomic) NSDate *updatedAt;
@property (nonatomic) NSString *externalId;


+ (instancetype)fromJSON:(NSDictionary *)dict;
- (NSDictionary *)toExtensionModel;

@end
