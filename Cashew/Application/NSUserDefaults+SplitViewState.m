//
//  NSUserDefaults+SplitViewState.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "NSUserDefaults+SplitViewState.h"

NSString * const kQSplitViewState = @"kQSplitViewState";


@implementation NSUserDefaults (SplitViewState)

+ (void)q_setSplitViewState:(NSDictionary *)state;
{
    //[NSUserDefaults fixDefaultsIfNeeded];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:state forKey:kQSplitViewState];
    [userDefaults synchronize];
}

+ (NSDictionary *)q_splitViewState
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults dictionaryForKey:kQSplitViewState];
}

+ (void)fixDefaultsIfNeeded {
    NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES);
    //File should be in library
    NSString *libraryPath = [domains firstObject];
    if (libraryPath) {
        NSString *preferensesPath = [libraryPath stringByAppendingPathComponent:@"Preferences"];
        
        //Defaults file name similar to bundle identifier
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        
        //Add correct extension
        NSString *defaultsName = [bundleIdentifier stringByAppendingString:@".plist"];
        
        NSString *defaultsPath = [preferensesPath stringByAppendingPathComponent:defaultsName];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        
        if (![manager fileExistsAtPath:defaultsPath]) {
            //Create to fix issues
            [manager createFileAtPath:defaultsPath contents:nil attributes:nil];
            
            //And restart defaults at the end
            [NSUserDefaults resetStandardUserDefaults];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

@end
