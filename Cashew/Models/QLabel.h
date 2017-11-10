//
//


//  Issues
//
//  Created by Hicham Bouabdallah on 1/11/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QAccount.h"
#import "QRepository.h"

NS_ASSUME_NONNULL_BEGIN
@interface QLabel : NSObject

@property (nullable, nonatomic, retain) QAccount *account;
@property (nullable, nonatomic, retain) QRepository *repository;
@property (nullable, nonatomic, retain) NSString *color;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, strong) NSDate *createdAt;
@property (nullable, nonatomic, strong) NSDate *updatedAt;

+ (instancetype)fromJSON:(NSDictionary *)dict;
- (NSDictionary *)toExtensionModel;

@end
NS_ASSUME_NONNULL_END
