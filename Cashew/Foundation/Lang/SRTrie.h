//
//  SRTrie.h
//  SRCommons
//
//  Created by Hicham Bouabdallah on 6/16/13.
//  Copyright (c) 2013 SimpleRocket LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRTrie : NSObject<NSFastEnumeration>

+ (id)trie;

- (void)addEntry:(NSString *)phrase;
- (void)removeEntry:(NSString *)phrase;
- (NSArray *)lookup:(NSString *)prefix;
- (NSArray *)lookup:(NSString *)prefix maxSize:(int)maxSize;
- (NSUInteger)count;
- (void)removeAllEntries;

@end
