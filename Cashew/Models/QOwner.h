//
//  QOwner.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QAccount.h"

@interface QOwner : NSObject


@property (nonatomic) QAccount *account;
@property (nonatomic) NSString *login;
@property (nonatomic) NSURL *avatarURL;
@property (nonatomic) NSString *type;
@property (nonatomic) NSNumber *identifier;
@property (nonatomic) NSURL *htmlURL;


+ (instancetype)fromJSON:(NSDictionary *)dict;
- (NSDictionary *)toExtensionModel;

@end
