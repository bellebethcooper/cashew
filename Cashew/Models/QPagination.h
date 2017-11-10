//
//  QPagination.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/15/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QPagination : NSObject

@property (nonatomic, strong) NSNumber *pageOffset;
@property (nonatomic, strong) NSNumber *pageSize;

- (instancetype)initWithPageOffset:(NSNumber *)pageOffset pageSize:(NSNumber *)pageSize NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
