//
//  QSourceListNode.m
//  Issues
//
//  Created by Hicham Bouabdallah on 2/1/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QSourceListNode.h"

@implementation QSourceListNode



- (NSString *)description
{
    return [NSString stringWithFormat:@"node.title=%@, node.parent %@", self.title, [self.parentNode title]];
}


@end
