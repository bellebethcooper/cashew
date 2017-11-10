//
//  SRUserQueryNameViewController.m
//  Issues
//
//  Created by Hicham Bouabdallah on 6/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRUserQueryNameViewController.h"
#import "Cashew-Swift.h"
#import "QUserQueryStore.h"
#import "QContext.h"

@interface _SRUserQueryTextField : NSTextField

@end

@implementation _SRUserQueryTextField

- (BOOL)allowsVibrancy
{
    return false;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.wantsLayer = true;
    //    self.layer.masksToBounds = true;
    //    self.layer.cornerRadius = 3.0;
    [self setFocusRingType:NSFocusRingTypeNone];
    //self.hidden = true;
}

@end

@interface SRUserQueryNameViewController ()

@property (weak) IBOutlet BaseView *containerView;
@property (weak) IBOutlet _SRUserQueryTextField *searchField;
@property (nonatomic) BaseButton *submitButton;

@property (nonatomic) QAccount *account;
@property (nonatomic) NSString *query;

@end

@interface SRUserQueryNameViewController () <NSTextFieldDelegate>
@end

@implementation SRUserQueryNameViewController

- (void)dealloc
{
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
}

- (instancetype)initWithAccount:(QAccount *)account query:(NSString *)query
{
    self = [super initWithNibName:@"SRUserQueryNameViewController" bundle:nil];
    if (self) {
        self.account = account;
        self.query = query;
    }
    DDLogDebug(@"query-> %@", query);
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _setupFields];
    [self _setupSubmitButton];
    
    [self.containerView setDisableThemeObserver:YES];
    [self.containerView setShouldAllowVibrancy:NO];
    [(BaseView *)self.view setDisableThemeObserver:YES];
    [self.submitButton setDisableThemeObserver:YES];
    [(BaseView *)self.view setPopoverBackgroundColorFixEnabed:YES];
    [(BaseView *)self.view setShouldAllowVibrancy:NO];
    
    __weak SRUserQueryNameViewController *weakSelf = self;
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        SRUserQueryNameViewController *strongSelf = weakSelf;
        
        if (!strongSelf) {
            return;
        }
        
        if (mode == SRThemeModeDark) {
            [(BaseView *)strongSelf.view setBackgroundColor:[[SRDarkModeColor sharedInstance] popoverBackgroundColor]];
            //strongSelf.containerView.layer.borderWidth = 0;
            strongSelf.containerView.backgroundColor = NSColor.whiteColor;
            strongSelf.searchField.backgroundColor = NSColor.whiteColor;
            
        } else if (mode == SRThemeModeLight) {
            [(BaseView *)strongSelf.view setBackgroundColor:[NSColor clearColor]];
            strongSelf.containerView.backgroundColor = NSColor.whiteColor;
            strongSelf.searchField.backgroundColor = NSColor.whiteColor;
            
//            strongSelf.containerView.layer.borderWidth = 1;
//            strongSelf.containerView.layer.borderColor = [[SRLightModeColor sharedInstance] separatorColor].CGColor;
        }
        
        strongSelf.searchField.textColor = NSColor.blackColor;
    }];
}


- (void)_setupSubmitButton
{
    self.submitButton = [BaseButton greenButton];
    self.submitButton.text = @"Save";
    [self.view addSubview:self.submitButton];
    self.submitButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.submitButton.rightAnchor constraintEqualToAnchor:self.containerView.rightAnchor].active = true;
    [self.submitButton.topAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:10].active = true;
    [self.submitButton.heightAnchor constraintEqualToConstant:24].active = true;
    [self.submitButton.widthAnchor constraintEqualToConstant:80].active = true;
    
    __weak SRUserQueryNameViewController *weakSelf = self;
    self.submitButton.onClick = ^{
        [weakSelf _didClickSave];
    };
}

- (void)_didClickSave
{
    if (self.searchField.stringValue.trimmedString.length == 0 || self.query.trimmedString.length == 0 || !self.account) {
        return;
    }
    
    [QUserQueryStore saveUserQueryWithQuery:self.query account:self.account name:self.searchField.stringValue externalId: nil updatedAt: nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didCloseUserQueryNameViewController:self];
    });
}

- (void)_setupFields
{
    NSParameterAssert([NSThread isMainThread]);
    
    [@[self.containerView] enumerateObjectsUsingBlock:^(QView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        //[view setBackgroundColor:bgColor];
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:view.bounds xRadius:3 yRadius:3];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = view.bounds;
        maskLayer.path = path.toCGPath;
        self.containerView.layer.mask = maskLayer;
        
        //  [CATransaction begin];
        //        [CATransaction setDisableActions:YES];
        //        [view.layer setCornerRadius:3];
        //        [view.layer setMasksToBounds:YES];
        
        //        let bezierPath = NSBezierPath(roundedRect: bounds, xRadius: CGRectGetWidth(bounds), yRadius: CGRectGetHeight(bounds))
        //        let maskLayer = CAShapeLayer()
        //        wantsLayer = true
        //        maskLayer.frame = bounds
        //        maskLayer.fillColor = NSColor.whiteColor().CGColor
        //        maskLayer.path = bezierPath.toCGPath()
        //        maskLayer.backgroundColor = NSColor.clearColor().CGColor
        //        roundedCornerMask = maskLayer
        //        self.layer?.mask = maskLayer //addSublayer(maskLayer)
        //        CATransaction.commit()
        
        //  [CATransaction commit];
    }];
    [self.searchField setDelegate:self];
    //
    //    [@[self.searchField] enumerateObjectsUsingBlock:^(NSTextField *field, NSUInteger idx, BOOL * _Nonnull stop) {
    //        field.wantsLayer = true;
    //        [field setFocusRingType:NSFocusRingTypeNone];
    ////        [CATransaction begin];
    ////        [CATransaction setDisableActions:YES];
    ////        [field.layer setCornerRadius:3];
    ////        [field.layer setMasksToBounds:YES];
    ////        [CATransaction commit];
    ////        [field setDelegate:self];
    //    }];
}


- (IBAction)searchField:(id)sender {
    
}

#pragma mark - NSTextFieldDelegate
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    if (commandSelector == @selector(insertNewline:)) {
        NSString *name = self.searchField.stringValue.trimmedString;
        if (name.length > 0) {
            [self _didClickSave];
            return YES;
        }
    }
    
    return NO;
}

@end
