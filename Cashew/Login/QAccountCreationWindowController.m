//
//  QAccountCreationWindowController.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QAccountCreationWindowController.h"
#import "QView.h"
#import "QRepositoriesService.h"
#import "QRepository.h"
#import "QContext.h"
#import "QAccountStore.h"
#import "QUserService.h"
#import "QOwnerStore.h"
#import "QAccountStore.h"
#import "QUserQueryStore.h"
#import "Cashew-Swift.h"
#import "NSUserDefaults+Application.h"
#import <QuartzCore/CAAnimation.h>
#import "QRepositoryStore.h"
@import os.log;

@interface QAccountCreationWindowController () <NSTextFieldDelegate>

@property (weak) IBOutlet QView *passwordFieldContainerView;
@property (weak) IBOutlet QView *loginFieldContainerView;

@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *loginTextField;
@property (weak) IBOutlet NSTextField *accountNameTextField;

@property (weak) IBOutlet NSButton *saveAccountButton;
@property (weak) IBOutlet QView *contentView;
@property (nonatomic, assign) NSModalSession modalSession;
@property (weak) IBOutlet NSImageView *loginImageView;

@property (strong) IBOutlet BaseView *twoFactorAuthContainer;
@property (strong) IBOutlet QView *twoFactorAuthCodeContainerView;
@property (strong) IBOutlet NSTextField *twoFactorAuthCodeTextField;
@property (weak) IBOutlet NSImageView *twoFactorAuthImageView;

@property (weak) IBOutlet NSButton *verifyTwoFactorAuthButton;
@property (weak) IBOutlet NSLayoutConstraint *contentViewLeftConstraint;
@property (weak) IBOutlet NSImageView *backImageButton;
@property (weak) IBOutlet NSTextField *badLoginMessageLabel;

@property (weak) IBOutlet NSTextField *badTwoFactorAuthCodeLabel;

@property (weak) IBOutlet QView *endpointTextFieldContainerView;
@property (weak) IBOutlet NSTextField *endpointTextField;

@property (weak) IBOutlet NSTextField *advancedLabelButton;

@property (weak) IBOutlet NSImageView *repositoryImageView;
@property (weak) IBOutlet BaseView *repositoryPickerContainerView;
@property (strong) IBOutlet BaseView *repositoryContainer;
@property (strong) SRSearchablePickerViewController *searchablePickerController;
@property (nonatomic) SRRepositoriesCloudKitService *repositoriesCloudKitService;
@property (weak) IBOutlet SRBaseLabel *signinToCashewsLabel;
@property (weak) IBOutlet SRBaseLabel *twoFactorAuthenticationLabel;
@property (weak) IBOutlet SRBaseLabel *selectRepositoryToSyncLabel;

@end

@implementation QAccountCreationWindowController

- (void)windowDidLoad {
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation windowDidLoad");
    [super windowDidLoad];
    
    self.signinToCashewsLabel.font = [NSFont systemFontOfSize:20];
    self.signinToCashewsLabel.stringValue = @"Sign in to Cashew";
    
    self.twoFactorAuthenticationLabel.font = [NSFont systemFontOfSize:20];
    self.twoFactorAuthenticationLabel.stringValue = @"Two-factor Authentication";
    
    self.selectRepositoryToSyncLabel.stringValue = @"SELECT REPOSITORIES TO SYNC LOCALLY";
    self.selectRepositoryToSyncLabel.font = [NSFont systemFontOfSize:20];
    
    
    NSParameterAssert([NSThread isMainThread]);
    
    self.repositoriesCloudKitService = [SRRepositoriesCloudKitService new];
    
    [_saveAccountButton setWantsLayer:YES];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (NSButton *button in @[self.verifyTwoFactorAuthButton, self.saveAccountButton]) {
        [button.layer setBackgroundColor:[NSColor colorWithWhite:244/255. alpha:1].CGColor];
        [button.layer setCornerRadius:3];
    }
    [CATransaction commit];
    [self _setupFields];
    
    self.window.titlebarAppearsTransparent = YES;
    
    //NSView *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    NSView *zoomButton = [self.window standardWindowButton:NSWindowZoomButton];
    NSView *miniaturizeButton = [self.window standardWindowButton:NSWindowMiniaturizeButton];
    zoomButton.hidden = YES;
    miniaturizeButton.hidden = YES;
    
    NSImage *img = [[NSImage imageNamed:@"AppIcon"] copy];
    img.size = NSMakeSize(120, 120);
    self.loginImageView.image = img;
    self.twoFactorAuthImageView.image = img;
    
    [self _setupBackButton];
    [self _setupBadLoginLabel];
    [self _setupBadTwoFactorAuthCodeLabel];
    [self _setupEndpointTextFieldContainerView];
    [self _setupAdvancedLabelButton];
    
    if (self.showSessionExpiredForAccount) {
        
        dispatch_block_t showExpiredSessionBlock = ^{
            if (self.showSessionExpiredForAccount) {
                [self _showExpiredSessionForAccount:self.showSessionExpiredForAccount];
            }
        };
        
        if ([NSThread isMainThread]) {
            showExpiredSessionBlock();
        } else {
            dispatch_async(dispatch_get_main_queue(), showExpiredSessionBlock);
        }
        
    } else if (self.showRepositoryPickerAccount) {
        dispatch_block_t showRepositoryBlock = ^{
            if (self.showRepositoryPickerAccount) {
                [self _showRepositoryPickerForAccount:self.showRepositoryPickerAccount animated:NO];
            }
        };
        
        if ([NSThread isMainThread]) {
            showRepositoryBlock();
        } else {
            dispatch_async(dispatch_get_main_queue(), showRepositoryBlock);
        }
    }
    
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        if (mode == SRThemeModeDark) {
            NSImage *image = [NSImage imageNamed:@"repo"];
            CGFloat aspectRatio = 9/12.0;
            image.size = CGSizeMake(aspectRatio * self.repositoryImageView.frame.size.height, self.repositoryImageView.frame.size.height);
            self.repositoryImageView.image = [image imageWithTintColor:NSColor.whiteColor];
            self.backImageButton.image = [[NSImage imageNamed:NSImageNameGoLeftTemplate] imageWithTintColor:NSColor.whiteColor];
        } else {
            NSImage *image = [NSImage imageNamed:@"repo"];
            CGFloat aspectRatio = 9/12.0;
            image.size = CGSizeMake(aspectRatio * self.repositoryImageView.frame.size.height, self.repositoryImageView.frame.size.height);
            self.repositoryImageView.image = image;
            self.backImageButton.image = [NSImage imageNamed:NSImageNameGoLeftTemplate];
        }
    }];
}

- (void)_showExpiredSessionForAccount:(QAccount *)account
{
    if (!account) {
        return;
    }
    QOwner *owner = [QOwnerStore ownerForAccountId:account.identifier identifier:account.userId];
    if (!owner) {
        return;
    }
    self.loginTextField.stringValue = owner.login;
    self.badLoginMessageLabel.stringValue = @"User session expired. Please login.";
    self.badLoginMessageLabel.alphaValue = 1.0;
    [self.contentView.window makeFirstResponder:self.passwordTextField];
}

- (void)presentModalWindow {
    NSParameterAssert([NSThread isMainThread]);
    
    [self.window center];
    
    NSWindow *mainAppWindow = NSApp.windows[0];
    CGFloat windowLeft = mainAppWindow.frame.origin.x + mainAppWindow.frame.size.width/2.0 - self.window.frame.size.width/2.0;
    CGFloat windowTop = mainAppWindow.frame.origin.y + mainAppWindow.frame.size.height/2.0 - self.window.frame.size.height/2.0;
    [self.window setFrameOrigin:NSMakePoint(windowLeft, windowTop)];
    self.modalSession = [[NSApplication sharedApplication] beginModalSessionForWindow:self.window]; //runModalForWindow(self.window!)
}

/**
 Returns QAccount created from self.loginTextField contents

 @return QAccount
 */
- (QAccount *)_createAccountFromFields {
    NSParameterAssert([NSThread isMainThread]);
    QAccount *account = [QAccount new];
    
    [account setAccountName:self.loginTextField.stringValue];
    [account setUsername:self.loginTextField.stringValue];
    
    NSString *baseURLString = [self.endpointTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (baseURLString && baseURLString.length > 0) {
        [account setBaseURL:[NSURL URLWithString:baseURLString]];
    } else {
        [account setBaseURL:[NSURL URLWithString:@"https://api.github.com"]];
    }
    
    return account;
}

- (void)_fetchCurrentUserAuthToken {
    NSLog(@"QAccountCreation fetchCurrentUserAuthToken");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *twoFactorAuthCode = self.twoFactorAuthCodeTextField.stringValue;
        BOOL isTwoFactorAuthRequest = twoFactorAuthCode && twoFactorAuthCode.length > 0;
        
        if (isTwoFactorAuthRequest) {
            [self _transitionTwoAuthButtonToVerifyingState];
        }
        
        __block QAccount *account = [self _createAccountFromFields];
        QUserService *service = [QUserService serviceForAccount:account];
        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fetchCurrentUserAuth - service: %@", service);

        [service currentUserAuthTokenWithTwoFactorAuthCode:twoFactorAuthCode onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fetchCurrentUserAuth - completion");
            dispatch_async(dispatch_get_main_queue(), ^{
                //                if (isTwoFactorAuthRequest) {
                //                    self.verifyTwoFactorAuthButton.enabled = true;
                //                    self.verifyTwoFactorAuthButton.stringValue = @"Verify";
                //                }
                
                if (error) {
                    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fetchCurrentUserAuthToken - error: %@", error);
                    if (isTwoFactorAuthRequest) {
                        [self _flashTwoFactorAuthCodeError];
                    } else {
                        [self _hideTwoFactorAuthView];
                    }
                    [self _transitionTwoAuthButtonToNormalState];
                    return;
                }
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fetchCurrentUserAuthToken - no error");
                NSString *token = json[@"token"];
                QOwner *owner = json[@"owner"];
                NSParameterAssert(token && token.length > 0);
                NSParameterAssert(owner);
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fetchCurrentUserAuthToken - no error, about to set account stuff");

                account.username = owner.login;
                account.authToken = token;
                account.userId = owner.identifier;
                account.accountName = account.username;

                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fetchCurrentUserAuthToken - about to add account");

                [[QContext sharedContext] addAccount:account withPassword:self.passwordTextField.stringValue];
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fetchCurrentUserAuthToken - just added account");
                [QAccountStore saveAccount:account];
                account = [QAccountStore accountForUserId:account.userId baseURL:account.baseURL];
                
                NSParameterAssert(account);
                [NSUserDefaults q_setCurrentAccountId:account.identifier];
                
                owner.account = account;
                [QOwnerStore saveOwner:owner];
                [self _checkForExistingRepositoriesForAccount:account];
            });
        }];
        
    });
}


- (void)_showRepositoryPickerForAccount:(QAccount *)account animated:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        QIssueFilter *filter = [QIssueFilter new];
        filter.account = account;
        [[QContext sharedContext] setCurrentFilter:filter];

        
        [self.contentView.superview addSubview:self.repositoryContainer];
        
        [self.repositoryContainer.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor].active = true;
        [self.repositoryContainer.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor].active = true;
        [self.repositoryContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = true;
        
        if (self.twoFactorAuthContainer.superview == nil) {
            [self.repositoryContainer.leftAnchor constraintEqualToAnchor:self.contentView.rightAnchor].active = true;
        } else {
            [self.repositoryContainer.leftAnchor constraintEqualToAnchor:self.twoFactorAuthContainer.rightAnchor].active = true;
        }
        
        SRRepositorySearchablePickerDataSource *dataSource = [SRRepositorySearchablePickerDataSource new];
        SRPickerSearchFieldViewModel *pickerSearchFieldViewModel = [[SRPickerSearchFieldViewModel alloc] initWithPlaceHolderText:@"Search"];
        SRSearchablePickerViewModel *viewModel = [[SRSearchablePickerViewModel alloc] initWithPickerSearchFieldViewModel:pickerSearchFieldViewModel];
        SRSearchablePickerViewController *searchablePickerController = [[SRSearchablePickerViewController alloc] initWithViewModel:viewModel dataSource:dataSource];
        
        [searchablePickerController registerAdapter:[[SRRepositorySearchablePickerTableViewAdapter alloc] initWithDataSource:dataSource] clazz:QRepository.class];
        [searchablePickerController registerAdapter:[[SRRepositorySearchablePickerTableViewAdapter alloc] initWithDataSource:dataSource] clazz:OrganizationPrivateRepositoryPermissionViewModel.class];
        searchablePickerController.showNumberOfSelections = true;
        
        __weak SRSearchablePickerViewController *weakSearchablePickerController;
        __weak SRRepositorySearchablePickerDataSource *weakDataStore = dataSource;
        searchablePickerController.onDoneButtonClick = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                weakSearchablePickerController.loading = true;
                NSArray<id<SRRepositoryPickerItem>> *repositories = weakDataStore.selectedRepositories;
                
                for (id<SRRepositoryPickerItem> repositoryPickerItem in repositories) {
                    if ([repositoryPickerItem isKindOfClass:QRepository.class]) {
                        QRepository *repository = (QRepository *)repositoryPickerItem;
                        [QRepositoryStore saveRepository:repository];
                    }
                }
                
                [_delegate creationWindowController:self didSignInToAccount:account];
                [self.window close];
            });
        };
        
        [self.repositoryPickerContainerView addSubview:searchablePickerController.view];
        [searchablePickerController.view pinAnchorsToSuperview];
        self.searchablePickerController = searchablePickerController;
        
        if (animated) {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                self.contentViewLeftConstraint.animator.constant = -self.contentView.frame.size.width *  ((self.twoFactorAuthContainer.superview == nil) ? 1 : 2);
            } completionHandler:^{
                [self.window makeFirstResponder:searchablePickerController.pickerSearchField];
                [self _transitionTwoAuthButtonToNormalState];
                [self _transitionSignInButtonToNormalState];
            }];
            
        } else {
            self.contentViewLeftConstraint.constant = -self.contentView.frame.size.width *  ((self.twoFactorAuthContainer.superview == nil) ? 1 : 2);
            //[self.window makeFirstResponder:searchablePickerController.pickerSearchField];
        }
    });
    
}

- (void)_checkForExistingRepositoriesForAccount:(QAccount *)account {
        
        NSArray<QRepository *> *repositories = [QRepositoryStore repositoriesForAccountId:account.identifier];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (repositories.count > 0) {
                [_delegate creationWindowController:self didSignInToAccount:account];
                [self.window close];
            } else {
                [self _showRepositoryPickerForAccount:account animated:YES];
            }
        });
}

- (void)_showTwoFactorAuthView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.verifyTwoFactorAuthButton.enabled = true;
        self.verifyTwoFactorAuthButton.stringValue = @"Verify";
        if (self.twoFactorAuthContainer.superview == nil) {
            [self.contentView.superview addSubview:self.twoFactorAuthContainer];
            
            [self.twoFactorAuthContainer.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor].active = true;
            [self.twoFactorAuthContainer.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor].active = true;
            [self.twoFactorAuthContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = true;
            [self.twoFactorAuthContainer.leftAnchor constraintEqualToAnchor:self.contentView.rightAnchor].active = true;
        }
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            self.contentViewLeftConstraint.animator.constant = -self.contentView.frame.size.width;
        } completionHandler:^{
            [self.window makeFirstResponder:self.twoFactorAuthCodeTextField];
            [self _transitionSignInButtonToNormalState];
        }];
    });
}

- (void)_hideTwoFactorAuthView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _transitionSignInButtonToNormalState];
        self.twoFactorAuthCodeTextField.stringValue = @"";
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            self.contentViewLeftConstraint.animator.constant = 0;
        } completionHandler:^{
            [self.window makeFirstResponder:self.loginTextField];
        }];
    });
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSArray *accounts = [QAccountStore accounts];
    if (accounts.count > 0) {
        [_delegate willCloseAccountCreationWindowController:self];
        [NSApp endModalSession:self.modalSession];
    } else {
        [NSApp terminate:nil];
    }
}

#pragma mark - General Setup

- (void)_setupBackButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(didClickBackInTwoFactorAuthContainerView:)];
        
        recognizer.numberOfClicksRequired = 1;
        [self.backImageButton addGestureRecognizer:recognizer];
    });
}

- (void)_setupBadLoginLabel
{
    NSParameterAssert([NSThread isMainThread]);
    self.badLoginMessageLabel.alphaValue = 0.0;
}

- (void)_setupBadTwoFactorAuthCodeLabel
{
    NSParameterAssert([NSThread isMainThread]);
    self.badTwoFactorAuthCodeLabel.alphaValue = 0.0;
}

- (void)_setupEndpointTextFieldContainerView
{
    NSParameterAssert([NSThread isMainThread]);
    self.endpointTextFieldContainerView.alphaValue = 0.0;
}

- (void)_setupAdvancedLabelButton
{
    NSParameterAssert([NSThread isMainThread]);
    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_didClickAdvancedLabel:)];
    
    recognizer.numberOfClicksRequired = 1;
    [self.advancedLabelButton addGestureRecognizer:recognizer];
}

- (void)_didClickAdvancedLabel:(id)sender
{
    NSParameterAssert([NSThread isMainThread]);
    self.advancedLabelButton.hidden = true;
    self.endpointTextFieldContainerView.alphaValue = 1.0;
    [self.window makeFirstResponder:self.endpointTextField];
}

- (void)_setupFields
{
    NSParameterAssert([NSThread isMainThread]);
    NSColor *bgColor = [NSColor colorWithWhite:0.95 alpha:1];
    [@[_passwordFieldContainerView, _loginFieldContainerView, _twoFactorAuthCodeContainerView] enumerateObjectsUsingBlock:^(QView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        [view setBackgroundColor:bgColor];
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [view.layer setCornerRadius:3];
        [view.layer setMasksToBounds:YES];
        [CATransaction commit];
    }];
    
    [@[_passwordTextField, _loginTextField, _twoFactorAuthCodeTextField] enumerateObjectsUsingBlock:^(NSTextField *field, NSUInteger idx, BOOL * _Nonnull stop) {
        [field setFocusRingType:NSFocusRingTypeNone];
        [field setBackgroundColor:bgColor];
        [field setDelegate:self];
        [field setTarget:self];
        [field setAction:@selector(_didTriggerActionOnField:)];
    }];
}

#pragma mark - Actions

- (IBAction)didClickBackInTwoFactorAuthContainerView:(id)sender {
    NSParameterAssert([NSThread isMainThread]);
    [self _hideTwoFactorAuthView];
}

- (void)_didTriggerActionOnField:(id)sender
{
    NSParameterAssert([NSThread isMainThread]);
    
    if (sender == self.passwordTextField) {
        [self _fireLogin];
    } else if (sender == self.twoFactorAuthCodeTextField) {
        [self _fetchCurrentUserAuthToken];
    } else if (sender == self.loginTextField) {
        [self.window makeFirstResponder:self.passwordTextField];
    }
}

- (IBAction)didClickSaveAccountButton:(id)sender
{
    NSParameterAssert([NSThread isMainThread]);
    [self _fireLogin];
}

- (void)_fireLogin
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.saveAccountButton.enabled) {
            return;
        }
        
        [self.window makeFirstResponder:nil];
        [self _transitionSignInButtonToLoggingInState];
        
        QAccount *account = [self _createAccountFromFields];
        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreation fireLogin - password field: %{private}@", self.passwordTextField.stringValue);
        [[QContext sharedContext] addAccount:account withPassword:self.passwordTextField.stringValue];
        QUserService *service = [QUserService serviceForAccount:account];
        
        [service loginUserOnCompletion:^(QOwner *currentUser, QServiceResponseContext *context, NSError *error) {
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreationWindowCont fireLogin - loginUserOnCompletion");
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (context.needTwoFactorAuth) {// && statusCode != 401 && statusCode != 403) {
                    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreationWindow fireLogin - needs 2FA");
                    [service sendSMSIfNeeded];
                    [self _showTwoFactorAuthView];
                    return;
                } else if (error) {
                    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEBUG, "QAccountCreationWindow fireLogin - error: %@", error);
                    [self _flashLoginError];
                    [self _transitionSignInButtonToNormalState];
                    return;
                }
                
                [self _fetchCurrentUserAuthToken];
            });
        }];
        
        
    });
}

- (void)_flashTwoFactorAuthCodeError
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.badTwoFactorAuthCodeLabel.alphaValue != 0) {
            return;
        }
        // [@[self.passwordFieldContainerView, self.loginFieldContainerView] enumerateObjectsUsingBlock:^(QView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        
        QView *view = self.twoFactorAuthCodeContainerView;
        
        view.layer.borderColor = self.badTwoFactorAuthCodeLabel.textColor.CGColor;
        [CATransaction begin];
        CABasicAnimation *borderWidthAnimation = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
        
        borderWidthAnimation.fromValue = @0.0;
        borderWidthAnimation.toValue = @1.0;
        
        
        [view.layer addAnimation:borderWidthAnimation forKey:@"borderWidth"];
        
        [CATransaction commit];
        self.badTwoFactorAuthCodeLabel.animator.alphaValue = 1.0;
        view.layer.borderWidth = 1;
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //  [@[self.passwordFieldContainerView, self.loginFieldContainerView] enumerateObjectsUsingBlock:^(QView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        QView *view = self.twoFactorAuthCodeContainerView;
        view.layer.borderColor = self.badTwoFactorAuthCodeLabel.textColor.CGColor;
        [CATransaction begin];
        CABasicAnimation *borderWidthAnimation = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
        
        borderWidthAnimation.fromValue = @1.0;
        borderWidthAnimation.toValue = @0.0;
        
        
        [view.layer addAnimation:borderWidthAnimation forKey:@"borderWidth"];
        
        [CATransaction commit];
        self.badTwoFactorAuthCodeLabel.animator.alphaValue = 0.0;
        view.layer.borderWidth = 0;
        
        // }];
    });
}

- (void)_showBadLoginMessageAnimated
{
    self.badLoginMessageLabel.stringValue = @"Bad username or password. Try again.";
    self.badLoginMessageLabel.animator.alphaValue = 1.0;
}

- (void)_flashLoginError
{
    NSParameterAssert([NSThread isMainThread]);
    if (self.badLoginMessageLabel.alphaValue != 0) {
        return;
    }
    [@[self.passwordFieldContainerView, self.loginFieldContainerView] enumerateObjectsUsingBlock:^(QView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        
        view.layer.borderColor = self.badLoginMessageLabel.textColor.CGColor;
        [CATransaction begin];
        CABasicAnimation *borderWidthAnimation = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
        
        borderWidthAnimation.fromValue = @0.0;
        borderWidthAnimation.toValue = @1.0;
        
        [view.layer addAnimation:borderWidthAnimation forKey:@"borderWidth"];
        
        [CATransaction commit];
        [self _showBadLoginMessageAnimated];
        view.layer.borderWidth = 1;
        
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [@[self.passwordFieldContainerView, self.loginFieldContainerView] enumerateObjectsUsingBlock:^(QView *view, NSUInteger idx, BOOL * _Nonnull stop) {
            
            view.layer.borderColor = self.badLoginMessageLabel.textColor.CGColor;
            [CATransaction begin];
            CABasicAnimation *borderWidthAnimation = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
            
            borderWidthAnimation.fromValue = @1.0;
            borderWidthAnimation.toValue = @0.0;
            
            
            [view.layer addAnimation:borderWidthAnimation forKey:@"borderWidth"];
            
            [CATransaction commit];
            self.badLoginMessageLabel.animator.alphaValue = 0.0;
            view.layer.borderWidth = 0;
            
        }];
    });
}

- (IBAction)didClickVerifyTwoFactorAuthButton:(id)sender {
    NSLog(@"QAccountCreation didClickVerifyTwoFactor");
    NSParameterAssert([NSThread isMainThread]);
    [self _fetchCurrentUserAuthToken];
}


#pragma mark - State Transitions

- (void)_transitionSignInButtonToLoggingInState
{
    self.saveAccountButton.enabled = false;
    self.saveAccountButton.title = @"Signing in...";
}

- (void)_transitionSignInButtonToNormalState
{
    self.saveAccountButton.enabled = true;
    self.saveAccountButton.title = @"Sign in";
}

- (void)_transitionTwoAuthButtonToVerifyingState
{
    self.verifyTwoFactorAuthButton.enabled = false;
    self.verifyTwoFactorAuthButton.stringValue = @"Verifying...";
}

- (void)_transitionTwoAuthButtonToNormalState
{
    self.verifyTwoFactorAuthButton.enabled = true;
    self.verifyTwoFactorAuthButton.stringValue = @"Verify";
}


@end
