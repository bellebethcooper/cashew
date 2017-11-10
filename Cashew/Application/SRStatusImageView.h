//
//  SRStatusImageView.h
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/24/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SRStatusImageView;

@protocol SRStatusImageViewDelegate <NSObject>

- (void)statusItemImageView:(SRStatusImageView *)imageView didPastePaths:(NSArray<NSString *> *)paths;

@end

@interface SRStatusImageView : NSImageView

@property (nonatomic) BOOL showNotificationDot;
@property (nonatomic, weak) NSStatusItem *statusItem;
@property (nonatomic, weak) id<SRStatusImageViewDelegate> statusImageImageViewDelegate;

@end
