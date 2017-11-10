//
//  QPagination.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/15/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QPagination.h"

@implementation QPagination

- (instancetype)initWithPageOffset:(NSNumber *)pageOffset pageSize:(NSNumber *)pageSize
{
    if (self = [super init]) {
        self.pageOffset = pageOffset;
        self.pageSize = pageSize;
    }
    
    return self;
}

@end
