//
//  QFilter.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueFilter.h"
#import "QissueConstants.h"
//#import "IssueStore.h"
#import "QOwnerStore.h"
#import "Cashew-Swift.h"

NSString * const kQIssueUpdatedDateSortKey = @"updated_at";
NSString * const kQIssueClosedDateSortKey = @"closed_at";
NSString * const kQIssueCreatedDateSortKey = @"created_at";
NSString * const kQIssueIssueNumberSortKey = @"number";
NSString * const kQIssueIssueStateSortKey = @"state";
NSString * const kQIssueTitleSortKey = @"title";
NSString * const kQIssueAssigneeSortKey = @"assignee";

@implementation QIssueFilter {
    NSMutableArray *_searchFilters;
    NSArray *_arguments;
    NSString *_format;
    
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //defaults
        self.sortKey = kQIssueUpdatedDateSortKey;
        self.states = [NSMutableOrderedSet new];
        self.assignees = [NSMutableOrderedSet new];
        self.authors = [NSMutableOrderedSet new];
        self.mentions = [NSMutableOrderedSet new];
        self.repositories = [NSMutableOrderedSet new];
        self.milestones = [NSMutableOrderedSet new];
        self.issueNumbers = [NSMutableOrderedSet new];
        self.labels = [NSMutableOrderedSet new];
        
        self.assigneeExcludes = [NSMutableOrderedSet new];
        self.mentionExcludes = [NSMutableOrderedSet new];
        self.authorExcludes = [NSMutableOrderedSet new];
        self.repositorieExcludes = [NSMutableOrderedSet new];
        self.milestoneExcludes = [NSMutableOrderedSet new];
        self.labelExcludes = [NSMutableOrderedSet new];
        
        
        
        self.ascending = NO;
        self.filterType = SRFilterType_Search;
    }
    return self;
}

+ (instancetype)filterWithSearchTokens:(NSString *)tokens;
{
    NSError *err = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\\w-]+\\:\\\"[[^\\\"]]*\\\"|[\\w-]+:[[^\\s]]*|\\#\\d+|\\w+)" options:NSRegularExpressionCaseInsensitive error:&err];
    NSParameterAssert(err == nil);
    
    // DDLogDebug(@"tokens => %@", tokens);
    NSArray *matches = [regex matchesInString:tokens options:NSMatchingReportProgress range:NSMakeRange(0, tokens.length)];
    NSMutableArray *tokenArray = [NSMutableArray new];
    for (NSTextCheckingResult *match in matches) {
        NSString *token  = [tokens substringWithRange:[match rangeAtIndex:1]];
        [tokenArray addObject:token];
    }
    // DDLogDebug(@"tokens array => %@", tokenArray);
    
    return [QIssueFilter filterWithSearchTokensArray:tokenArray];
}

+ (instancetype)filterWithSearchTokensArray:(NSArray *)tokens;
{
    QIssueFilter *filter = [QIssueFilter new];
    
    [filter _parseTokens:tokens];
    
    return filter;
}

- (void)setQuery:(NSString *)query
{
    if (![_query isEqualToString:query]) {
        NSString *adjusted = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (query && query.length > 0) {
            _query = adjusted;
        } else {
            _query = nil;
        }
    }
}

- (void)_parseTokens:(NSArray *)tokens;
{
    if (tokens.count == 0) {
        return;
    }
    
    NSArray<NSString *> *pieces = tokens;
    
    [pieces enumerateObjectsUsingBlock:^(NSString * _Nonnull piece, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *adjustedPiece = [piece stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<NSString *> *keyValues = [adjustedPiece componentsSeparatedByString:@":"];
        
        if (keyValues.count > 2) {
            NSMutableString *str = [NSMutableString new];
            [keyValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx != 0) {
                    [str appendString:obj];
                    
                    if (idx != keyValues.count-1) {
                        [str appendString:@":"];
                    }
                }
            }];
            keyValues = @[keyValues[0], str.copy];
        }
        
        if (keyValues.count == 1) {
            NSError *error = NULL;
            NSString *pattern = @"(^|\\s+)(\\#(\\d+))";
            NSString *value = [keyValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSRange range = NSMakeRange(0, value.length);
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
            NSArray *matches = [regex matchesInString:value options:0 range:range];
            
            //__block BOOL matched = false;
            [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
                // matched = true;
                NSRange range = [match rangeAtIndex:3];
                NSString *issueNumber = [value substringWithRange:range];
                NSMutableOrderedSet *set = _issueNumbers ? [NSMutableOrderedSet orderedSetWithOrderedSet:_issueNumbers] : [NSMutableOrderedSet new];
                [set addObject:issueNumber];
                _issueNumbers = [set copy];
                
            }];
            
            __block NSString *adjustedString = keyValues[0];
            [_issueNumbers enumerateObjectsUsingBlock:^(NSString *num, NSUInteger idx, BOOL * _Nonnull stop) {
                adjustedString = [adjustedString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"#%@", num] withString:@""];
            }];
            
            adjustedString = [adjustedString trimmedString];
            if (adjustedString.length > 0) {
                NSString *currentQueryString = self.query ?: @"";
                self.query = [@[adjustedString, currentQueryString] componentsJoinedByString:@" "];
            }
            
            
        } else if (keyValues.count == 2) {
            
            NSString *key = [keyValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [keyValues[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSString *lowerCaseKey = [key lowercaseString];
            __block NSString *lowerCaseValue = value; //[value lowercaseString];
            
            NSError *error = NULL;
            NSString *pattern = @"\"(.*?)\"";
            NSRange range = NSMakeRange(0, lowerCaseValue.length);
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
            NSArray *matches = [regex matchesInString:lowerCaseValue options:0 range:range];
            
            //DDLogDebug(@"matches=%@", matches);
            [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSRange range = [match rangeAtIndex:1];
                lowerCaseValue = [lowerCaseValue substringWithRange:range];
                *stop = YES;
            }];
            
            
            
            // is
            if ([lowerCaseKey isEqualToString:@"is"]) {
                NSMutableOrderedSet *set = _states ? [NSMutableOrderedSet orderedSetWithOrderedSet:_states] : [NSMutableOrderedSet new];
                if ([lowerCaseValue isEqualToString:@"open"]) {
                    [set addObject:@(IssueStoreIssueState_Open)];
                } else if ([lowerCaseValue isEqualToString:@"closed"]) {
                    [set addObject:@(IssueStoreIssueState_Closed)];
                }
                _states = [set copy];
            }
            
            // no:assignee, no:label, no:milestone
            else if ([lowerCaseKey isEqualToString:@"no"]) {
                if ([lowerCaseValue isEqualToString:@"assignee"]) {
                    NSMutableOrderedSet *set = _assignees ? [NSMutableOrderedSet orderedSetWithOrderedSet:_assignees] : [NSMutableOrderedSet new];
                    [set addObject:NSNull.null];
                    _assignees = [set copy];
                } else if ([lowerCaseValue isEqualToString:@"label"]) {
                    NSMutableOrderedSet *set = _labels ? [NSMutableOrderedSet orderedSetWithOrderedSet:_labels] : [NSMutableOrderedSet new];
                    [set addObject:NSNull.null];
                    _labels = [set copy];
                } else if ([lowerCaseValue isEqualToString:@"milestone"]) {
                    NSMutableOrderedSet *set = _milestones ? [NSMutableOrderedSet orderedSetWithOrderedSet:_milestones] : [NSMutableOrderedSet new];
                    [set addObject:NSNull.null];
                    _milestones = [set copy];
                }
            }
            
            // assignee
            else if ([lowerCaseKey isEqualToString:@"assignee"]) {
                NSMutableOrderedSet *set = _assignees ? [NSMutableOrderedSet orderedSetWithOrderedSet:_assignees] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _assignees = [set copy];
            }
            
            // mentions
            else if ([lowerCaseKey isEqualToString:@"mentions"]) {
                NSMutableOrderedSet *set = _mentions ? [NSMutableOrderedSet orderedSetWithOrderedSet:_mentions] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _mentions = [set copy];
            }
            
            // authors
            else if ([lowerCaseKey isEqualToString:@"author"]) {
                NSMutableOrderedSet *set = _authors ? [NSMutableOrderedSet orderedSetWithOrderedSet:_authors] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _authors = [set copy];
            }
            
            // milestones
            else if ([lowerCaseKey isEqualToString:@"milestone"]) {
                NSMutableOrderedSet *set = _milestones ? [NSMutableOrderedSet orderedSetWithOrderedSet:_milestones] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _milestones = [set copy];
            }
            
            // repos
            else if ([lowerCaseKey isEqualToString:@"repo"]) {
                NSMutableOrderedSet *set = _repositories ? [NSMutableOrderedSet orderedSetWithOrderedSet:_repositories] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _repositories = [set copy];
            }
            
            // labels
            else if ([lowerCaseKey isEqualToString:@"label"]) {
                NSMutableOrderedSet *set = _labels ? [NSMutableOrderedSet orderedSetWithOrderedSet:_labels] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _labels = [set copy];
            }
            
            // -assignee
            else if ([lowerCaseKey isEqualToString:@"-assignee"]) {
                NSMutableOrderedSet *set = _assigneeExcludes ? [NSMutableOrderedSet orderedSetWithOrderedSet:_assigneeExcludes] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _assigneeExcludes = [set copy];
            }
            
            // -mentions
            else if ([lowerCaseKey isEqualToString:@"-mentions"]) {
                NSMutableOrderedSet *set = _mentionExcludes ? [NSMutableOrderedSet orderedSetWithOrderedSet:_mentionExcludes] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _mentionExcludes = [set copy];
            }
            
            // -authors
            else if ([lowerCaseKey isEqualToString:@"-author"]) {
                NSMutableOrderedSet *set = _authorExcludes ? [NSMutableOrderedSet orderedSetWithOrderedSet:_authorExcludes] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _authorExcludes = [set copy];
            }
            
            // -milestones
            else if ([lowerCaseKey isEqualToString:@"-milestone"]) {
                NSMutableOrderedSet *set = _milestoneExcludes ? [NSMutableOrderedSet orderedSetWithOrderedSet:_milestoneExcludes] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _milestoneExcludes = [set copy];
            }
            
            // -repos
            else if ([lowerCaseKey isEqualToString:@"-repo"]) {
                NSMutableOrderedSet *set = _repositorieExcludes ? [NSMutableOrderedSet orderedSetWithOrderedSet:_repositorieExcludes] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _repositorieExcludes = [set copy];
            }
            
            // -labels
            else if ([lowerCaseKey isEqualToString:@"-label"]) {
                NSMutableOrderedSet *set = _labelExcludes ? [NSMutableOrderedSet orderedSetWithOrderedSet:_labelExcludes] : [NSMutableOrderedSet new];
                [set addObject:lowerCaseValue];
                _labelExcludes = [set copy];
            }
            
        }
        
    }];
    
}


- (NSArray *)searchTokensArray
{
    NSMutableArray *tokens = [NSMutableArray new];
    
    // repo
    [_repositories enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"repo:%@", obj]];
    }];
    
    // -repo
    [_repositorieExcludes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"-repo:%@", obj]];
    }];
    
    // milestone
    [_milestones enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj == NSNull.null) {
            [tokens addObject:@"no:milestone"];
            //return;
        } else {
            
            NSString *milestone = (NSString *)obj;
            NSString *adjusted = [milestone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if ([adjusted rangeOfString:@" "].location != NSNotFound) {
                if (![adjusted hasPrefix:@"\""]) {
                    adjusted = [NSString stringWithFormat:@"\"%@", adjusted];
                }
                if (![adjusted hasSuffix:@"\""]) {
                    adjusted = [NSString stringWithFormat:@"%@\"", adjusted];
                }
            }
            [tokens addObject:[NSString stringWithFormat:@"milestone:%@", adjusted]];
        }
    }];
    
    // -milestone
    [_milestoneExcludes enumerateObjectsUsingBlock:^(NSString * _Nonnull milestone, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *adjusted = [milestone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([adjusted rangeOfString:@" "].location != NSNotFound) {
            if (![adjusted hasPrefix:@"\""]) {
                adjusted = [NSString stringWithFormat:@"\"%@", adjusted];
            }
            if (![adjusted hasSuffix:@"\""]) {
                adjusted = [NSString stringWithFormat:@"%@\"", adjusted];
            }
        }
        [tokens addObject:[NSString stringWithFormat:@"-milestone:%@", adjusted]];
    }];
    
    
    // state
    [_states enumerateObjectsUsingBlock:^(NSNumber * _Nonnull state, NSUInteger idx, BOOL * _Nonnull stop) {
        if (state.integerValue == IssueStoreIssueState_Closed) {
            [tokens addObject:@"is:closed"];
        } else if (state.integerValue == IssueStoreIssueState_Open) {
            [tokens addObject:@"is:open"];
        }
    }];
    
    // assignee
    [_assignees enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj == NSNull.null) {
            [tokens addObject:@"no:assignee"];
            //return;
        } else {
            [tokens addObject:[NSString stringWithFormat:@"assignee:%@", obj]];
        }
    }];
    
    // -assignee
    [_assigneeExcludes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"-assignee:%@", obj]];
    }];
    
    // authors
    [_authors enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"author:%@", obj]];
    }];
    
    // -authors
    [_authorExcludes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"-author:%@", obj]];
    }];
    
    // mentions
    [_mentions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"mentions:%@", obj]];
    }];
    
    // -mentions
    [_mentionExcludes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"-mentions:%@", obj]];
    }];
    
    // labels
    [_labels enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj == NSNull.null) {
            [tokens addObject:@"no:label"];
        } else {
            
            NSString *label = (NSString *)obj;
            NSString *adjusted = [label stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if ([adjusted rangeOfString:@" "].location != NSNotFound) {
                if (![adjusted hasPrefix:@"\""]) {
                    adjusted = [NSString stringWithFormat:@"\"%@", adjusted];
                }
                if (![adjusted hasSuffix:@"\""]) {
                    adjusted = [NSString stringWithFormat:@"%@\"", adjusted];
                }
            }
            [tokens addObject:[NSString stringWithFormat:@"label:%@", adjusted]];
        }
    }];
    
    // -labels
    [_labelExcludes enumerateObjectsUsingBlock:^(NSString * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *adjusted = [label stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([adjusted rangeOfString:@" "].location != NSNotFound) {
            if (![adjusted hasPrefix:@"\""]) {
                adjusted = [NSString stringWithFormat:@"\"%@", adjusted];
            }
            if (![adjusted hasSuffix:@"\""]) {
                adjusted = [NSString stringWithFormat:@"%@\"", adjusted];
            }
        }
        [tokens addObject:[NSString stringWithFormat:@"-label:%@", adjusted]];
    }];
    
    
    [_issueNumbers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tokens addObject:[NSString stringWithFormat:@"#%@", obj]];
    }];
    
    if (self.query) {
        [tokens addObject:self.query];
    }
    
    return tokens;
}

- (NSString *)searchTokens
{
    return [[self searchTokensArray] componentsJoinedByString:@" "];
}

- (BOOL)isEqualToIssueFilter:(QIssueFilter *)filter;
{
    NSString *currentSearchToken = [self searchTokens];
    NSString *otherSearchToken = [filter searchTokens];
    
    return [currentSearchToken isEqualToString:otherSearchToken] && [filter.sortKey isEqualToString:self.sortKey] && filter.ascending == self.ascending;
}


- (id)copy
{
    QIssueFilter *filter = [QIssueFilter new];
    
    filter.account = self.account;
    filter.states = [self.states copy];
    filter.assignees = [self.assignees copy];
    filter.authors = [self.authors copy];
    filter.repositories = [self.repositories copy];
    filter.milestones = [self.milestones copy];
    filter.query = [self.query copy];
    filter.sortKey = self.sortKey;
    filter.ascending = self.ascending;
    filter.mentions = [self.mentions copy];
    filter.labels = [self.labels copy];
    filter.issueNumbers = [self.issueNumbers copy];
    filter.filterType = self.filterType;
    
    filter.assigneeExcludes = [self.assigneeExcludes copy];
    filter.mentionExcludes = [self.mentionExcludes copy];
    filter.authorExcludes = [self.authorExcludes copy];
    filter.repositorieExcludes = [self.repositorieExcludes copy];
    filter.milestoneExcludes = [self.milestoneExcludes copy];
    filter.labelExcludes = [self.labelExcludes copy];
    
    return filter;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"QIssueFilter %@", self.searchTokens];
}

@end
