//
//  SRExtensionStore.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QBaseStore.h"
#import "SRExtension.h"


@interface SRExtensionStore : QBaseStore

+ (void)saveExtension:(SRExtension *)extension;
+ (NSArray<SRExtension *> *)extensionsForType:(SRExtensionType)extensionType;
+ (void)deleteExtension:(SRExtension *)extension;
+ (SRExtension *)extensionForName:(NSString *)extensionName extensionType:(SRExtensionType)extensionType;

@end
