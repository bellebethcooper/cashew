//
//  NSUserDefaults+SplitViewState.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (SplitViewState)

+ (void)q_setSplitViewState:(NSDictionary *)state;

+ (NSDictionary *)q_splitViewState;

+ (void)fixDefaultsIfNeeded;
@end
