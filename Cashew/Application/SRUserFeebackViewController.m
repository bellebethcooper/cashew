//
//  SRUserFeebackViewController.m
//  Issues
//
//  Created by Hicham Bouabdallah on 6/12/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRUserFeebackViewController.h"
#import "Cashew-Swift.h"
#import <AFNetworking/AFNetworking.h>
#import "QAccount.h"
#import "QContext.h"

@interface SRUserFeebackViewController ()
@property (nonatomic) BaseButton *sendButton;
@property (weak) IBOutlet BaseView *bottomLineSeparatorView;
@property (unsafe_unretained) IBOutlet NSTextView *feedbackDescriptionTextView;
@property (weak) IBOutlet NSTextField *feedbackTitleTextField;
@end

@implementation SRUserFeebackViewController

- (void)dealloc
{
    [[SRThemeObserverController sharedInstance] removeThemeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.feedbackDescriptionTextView.hidePlaceholder = true;

    self.sendButton = [BaseButton greenButton];
    
    self.sendButton.text = @"Send";
    
    [self.view addSubview:self.sendButton];
    
    self.feedbackDescriptionTextView.font = [NSFont systemFontOfSize:14];
    //self.feedbackDescriptionTextView.collapseToolbar = false;
    
    self.sendButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.sendButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant: -10].active = true;
    [self.sendButton.heightAnchor constraintEqualToConstant:30].active = true;
    [self.sendButton.widthAnchor constraintEqualToConstant:92].active = true;
    [self.sendButton.topAnchor constraintEqualToAnchor:self.bottomLineSeparatorView.bottomAnchor constant:10].active = true;
    
    __weak SRUserFeebackViewController *weakSelf = self;
    self.sendButton.onClick = ^{
        [weakSelf _didClickSend];
    };
    
//    self.feedbackDescriptionTextView.onEnterKeyPressed = ^{
//        [weakSelf _didClickSend];
//    };
    
    
    [[SRThemeObserverController sharedInstance] addThemeObserver:self block:^(SRThemeMode mode) {
        SRUserFeebackViewController *strongSelf = weakSelf;
        strongSelf.feedbackDescriptionTextView.textColor = [SRCashewColor foregroundSecondaryColor];
    }];
}

- (void)_didClickSend
{
    [self.view.window orderOut:nil];
    QAccount *account = [QContext sharedContext].currentAccount;
    
    if (!account) {
        [self.view.window close];
        return;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.github.com"];
    
    if ([account.baseURL isEqual:baseURL]) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        [sessionConfig setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
        QAFHTTPSessionManager *manager = [[QAFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:sessionConfig];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"token %@", account.authToken] forHTTPHeaderField:@"Authorization"];
        [manager.requestSerializer setTimeoutInterval:60.0];
        
        NSMutableDictionary *params = [NSMutableDictionary new];
        
        params[@"title"] = self.feedbackTitleTextField.stringValue.trimmedString.length > 0 ? self.feedbackTitleTextField.stringValue : [NSString stringWithFormat:@"Feedback from %@", account.username];
        
        NSString *body = [self.feedbackDescriptionTextView.string trimmedString];
        if (body && body.length > 0) {
            params[@"body"] = body;
        }
        params[@"assignee"] = @"hishboy";
        params[@"labels"] = @[@"user feedback"];
        
        [manager POST:@"repos/simplerocket-llc/dear-cashew/issues"
           parameters:params progress:nil onCompletion:^(NSDictionary *json, QServiceResponseContext * _Nonnull context, NSError *error) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   [self.view.window close];
               });
           }];
    } else {
        
        NSString *title = self.feedbackTitleTextField.stringValue.trimmedString.length > 0 ?  self.feedbackTitleTextField.stringValue : [NSString stringWithFormat:@"Feedback from %@", account.username];
        NSString *body = [NSString stringWithFormat:@"Feedback from %@ @ %@: \n %@", account.username, account.baseURL, self.feedbackDescriptionTextView.string];
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        [sessionConfig setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://cashew-api.herokuapp.com"] sessionConfiguration:sessionConfig];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        NSDictionary *params = @{ @"body": body, @"title": title};
        
        [manager POST:@"app/feedback" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window close];
            });
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window close];
            });
        }];
    }
}

@end
