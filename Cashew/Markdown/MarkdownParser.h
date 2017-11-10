//
//  MarkdownParser.h
//  Issues
//
//  Created by Hicham Bouabdallah on 5/21/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QRepository.h"

@interface MarkdownParser : NSObject

- (NSString *)parse:(NSString *)str forRepository:(QRepository *)repo;

@end
