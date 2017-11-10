//
//  QThrottler.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/20/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QThrottler : NSObject
+ (instancetype)throttlerWithSleepInterval:(NSTimeInterval)sleepInterval batchSize:(NSInteger)batchSize;
- (void)throttle;
@end
