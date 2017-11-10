//
//  NSUserDefaults+Application.h
//  Issues
//
//  Created by Hicham Bouabdallah on 3/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (Application)


+ (void)q_setCurrentAccountId:(NSNumber *)accountId;
+ (void)q_deleteCurrentAccountId;

+ (NSNumber *)q_currentAccountId;


@end
