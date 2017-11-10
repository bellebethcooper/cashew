//
//  NSMutableAttributedString+Trimmer.m
//  Issues
//
//  Created by Hicham Bouabdallah on 2/17/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "NSMutableAttributedString+Trimmer.h"

@implementation NSMutableAttributedString (Trimmer)

- (void)trimWhitespaces
{
    NSMutableAttributedString *attString = self;
    // Trim leading whitespace and newlines.
    NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSRange range           = [attString.string rangeOfCharacterFromSet:charSet];
    
    while (range.length != 0 && range.location == 0)
    {
        [attString replaceCharactersInRange:range withString:@""];
        range = [attString.string rangeOfCharacterFromSet:charSet];
    }
    
    // Trim trailing whitespace and newlines.
    range = [attString.string rangeOfCharacterFromSet:charSet options:NSBackwardsSearch];
    while (range.length != 0 && NSMaxRange(range) == attString.length)
    {
        [attString replaceCharactersInRange:range withString:@""];
        range = [attString.string rangeOfCharacterFromSet:charSet options:NSBackwardsSearch];
    }
    
}

@end
