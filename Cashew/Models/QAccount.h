//
//  QAccount.h
//  Queues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QAccount : NSObject

@property (nonatomic) NSString *accountName;
@property (nonatomic) NSURL *baseURL;
@property (nonatomic) NSString *username;
@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSNumber *identifier;
@property (nonatomic) NSString *authToken;

- (BOOL)isEqualToAccount:(id)object;

@end
