//
//  NSColor+Hex.m
//  Issues
//
//  Created by Hicham Bouabdallah on 2/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "NSColor+Hex.h"

@implementation NSColor (Hex)

- (NSString *)hexadecimalValue {
    
    double redFloatValue, greenFloatValue, blueFloatValue;
    int redIntValue, greenIntValue, blueIntValue;
    NSString *redHexValue, *greenHexValue, *blueHexValue;
    
    NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    if(convertedColor) {
        [convertedColor getRed:&redFloatValue green:&greenFloatValue blue:&blueFloatValue alpha:NULL];
        
        redIntValue = redFloatValue*255.99999f;
        greenIntValue = greenFloatValue*255.99999f;
        blueIntValue = blueFloatValue*255.99999f;
        
        redHexValue = [NSString stringWithFormat:@"%02x", redIntValue];
        greenHexValue = [NSString stringWithFormat:@"%02x", greenIntValue];
        blueHexValue = [NSString stringWithFormat:@"%02x", blueIntValue];
        
        return [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
    }
    
    return nil;
}

+ (NSColor *)colorFromHexadecimalValue:(NSString *)hex {
    
    if ([hex hasPrefix:@"#"]) {
        hex = [hex substringWithRange:NSMakeRange(1, [hex length] - 1)];
    }
    
    unsigned int colorCode = 0;
    
    if (hex) {
        NSScanner *scanner = [NSScanner scannerWithString:hex];
        (void)[scanner scanHexInt:&colorCode];
    }
    
    return [NSColor colorWithCalibratedRed:((colorCode>>16)&0xFF)/255.0 green:((colorCode>>8)&0xFF)/255.0 blue:((colorCode)&0xFF)/255.0 alpha:1.0];
}

@end
