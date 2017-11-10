//
//  SRTrie.m
//  SRCommons
//
//  Created by Hicham Bouabdallah on 6/16/13.
//  Copyright (c) 2013 SimpleRocket LLC. All rights reserved.
//

#import "SRTrie.h"

@interface SRTrieNode : NSObject<NSCopying>
@property (nonatomic, strong) SRTrieNode *parent;
@property (nonatomic, strong) NSNumber *character;
@property (nonatomic, strong) NSMutableDictionary *children;
@property (nonatomic, strong) NSString *phraseAtEndOfTrie;
@end

@implementation SRTrieNode
+ (id)nodeWithCharacter:(NSNumber *)c {
    SRTrieNode *instance = [SRTrieNode new];
    instance.character = c;
    instance.children = [NSMutableDictionary new];
    return instance;
}

- (SRTrieNode *)addChild:(NSNumber *)c {
    SRTrieNode *node = self.children[c];
    if (!node) {
        node = [SRTrieNode nodeWithCharacter:c];
        node.parent = self;
        self.children[c] = node;
    }
    return node;
}

- (void)add:(NSString *)phrase original:(NSString *)originalPhrase {
    if (!phrase || phrase.length == 0) {
        self.phraseAtEndOfTrie = originalPhrase;
        return;
    }
    
    char firstChar = [phrase characterAtIndex:0];
    NSNumber *childKey = [NSNumber numberWithChar:firstChar];
    SRTrieNode * child = [self addChild:childKey];
    [child add:[phrase substringFromIndex:1] original:originalPhrase];
}

- (void)delete:(NSString *)phrase {
    SRTrieNode *endNode = [self findPrefixNode:phrase];
    [endNode deleteFromParent];
}

- (void)deleteFromParent {
    if (!self.parent) return;
    
    if (self.children.count > 0) {
        self.phraseAtEndOfTrie = nil;
    } else {
        [self.parent.children removeObjectForKey:self.character];
        if (self.parent.children.count == 0) {
            [self.parent deleteFromParent];
        }
    }
}

- (SRTrieNode *)findPrefixNode:(NSString *)prefix {
    if (!prefix || prefix.length == 0) return self;
    
    char firstChar = [prefix characterAtIndex:0];
    NSNumber *childKey = [NSNumber numberWithChar:firstChar];
    SRTrieNode *child = self.children[childKey];
    if (!child) return nil;
    
    return [child findPrefixNode:[prefix substringFromIndex:1]];
}

- (void)loadUpPrefixMatches:(NSMutableArray *)matches maxSize:(int)maxSize {
    if (matches.count >= maxSize) return;
    
    if (self.phraseAtEndOfTrie) {
        [matches addObject:self.phraseAtEndOfTrie];
    }
    
    for (NSNumber *childKey in self.children) {
        SRTrieNode *child = self.children[childKey];
        [child loadUpPrefixMatches:matches maxSize:maxSize];
        if (matches.count >= maxSize) break;
    }
}

- (SRTrieNode *)getChildNode:(NSNumber *)c {
    return self.children[c];
}

-(BOOL)isEqual:(id)object {
    SRTrieNode *node = (SRTrieNode *)object;
    return [self.character isEqual:node.character];
}

-(NSUInteger)hash {
    return self.character.hash;
}

-(id)copyWithZone:(NSZone *)zone {
    SRTrieNode *node = [SRTrieNode new];
    node.character = self.character;
    node.children = self.children;
    return node;
}

@end


@interface SRTrie ()
@property (nonatomic, strong) SRTrieNode *root;
@property (nonatomic, strong) NSMutableSet *items;
@property (nonatomic, copy) dispatch_queue_t accessQueue;
@end

@implementation SRTrie

- (id)init
{
    self = [super init];
    if (self) {
        self.root = [SRTrieNode nodeWithCharacter:nil];
        self.items = [NSMutableSet new];
        self.accessQueue = dispatch_queue_create("com.simplerocket.SRTrie.accessQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

+ (id)trie {
    SRTrie *instance = SRTrie.new;
    return instance;
}

- (void)addEntry:(NSString *)phrase {
    if (!phrase || phrase.length == 0) return;
    NSString *lowerCase = phrase.lowercaseString;
    
    dispatch_barrier_sync(self.accessQueue, ^{
        [self.items addObject:lowerCase];
        [self.root add:lowerCase original:phrase];
    });
}

- (void)removeEntry:(NSString *)phrase {
    dispatch_barrier_sync(self.accessQueue, ^{
        NSString *lowerCase = phrase.lowercaseString;
        if ([self.items containsObject:lowerCase]) {
            [self.items removeObject:lowerCase];
            [self.root delete:lowerCase];
        }
    });
}

- (NSArray *)lookup:(NSString *)prefix {
    return [self lookup:prefix maxSize:INT_MAX];
}

- (NSArray *)lookup:(NSString *)prefix maxSize:(int)maxSize {
    if (!prefix || prefix.length == 0) return @[];
    NSMutableArray *matches = [NSMutableArray new];
    dispatch_sync(self.accessQueue, ^{
        NSString *lowerCasePrefix = prefix.lowercaseString;
        SRTrieNode *matchedPrefixNode = [self.root findPrefixNode:lowerCasePrefix];
        
        if (!matchedPrefixNode) return;
        
        [matchedPrefixNode loadUpPrefixMatches:matches maxSize:maxSize];
    });
    return matches;
}

- (void)removeAllEntries {
    dispatch_barrier_sync(self.accessQueue, ^{
        [self.items removeAllObjects];
        self.root = [SRTrieNode nodeWithCharacter:nil];
    });
}

- (NSUInteger)count {
    __block NSUInteger aCount = 0;
    dispatch_sync(self.accessQueue, ^{
        aCount = self.items.count;
    });
    return aCount;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [self.items countByEnumeratingWithState:state objects:buffer count:len];
}

@end
