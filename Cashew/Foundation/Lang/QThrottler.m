//
//  QThrottler.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/20/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QThrottler.h"
#import "Cashew-Swift.h"
@import os.log;

@implementation QThrottler {
    NSInteger _batchSize;
    NSTimeInterval _sleepInterval;
    dispatch_queue_t _serialQueue;
    NSInteger _currentCount;
}

+ (instancetype)throttlerWithSleepInterval:(NSTimeInterval)sleepInterval batchSize:(NSInteger)batchSize
{
    NSParameterAssert(sleepInterval > 0);
    NSParameterAssert(batchSize > 0);
    QThrottler *thorttler = [QThrottler new];
    
    thorttler->_sleepInterval = sleepInterval;
    thorttler->_batchSize = batchSize;
    thorttler->_serialQueue = dispatch_queue_create("co.hellocode.cashew.throttler", DISPATCH_QUEUE_SERIAL);
    thorttler->_currentCount = 0;
    
    return thorttler;
}

- (void)throttle
{
    dispatch_sync(_serialQueue, ^{
        _currentCount++;
        if (_currentCount % _batchSize == 0) {
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "throttled batchSize=%@ sleepInterval=%@ currentCount=%@", @(_batchSize), @(_sleepInterval), @(_currentCount));
            [NSThread sleepForTimeInterval:_sleepInterval];
        }
    });
}

@end
