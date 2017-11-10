//
//  SRIssueNotification.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRIssueNotification : NSObject
@property (nonatomic, readonly, strong) NSNumber * _Nonnull threadId;
@property (nonatomic, readonly) BOOL read;
@property (nonatomic, readonly, copy) NSString * _Nonnull reason;
@property (nonatomic, readonly, copy) NSDate * _Nonnull updatedAt;
- (nonnull instancetype)initWithThreadId:(NSNumber * _Nonnull)threadId read:(BOOL)read reason:(NSString * _Nonnull)reason updatedAt:(NSDate * _Nonnull)updatedAt;
@end