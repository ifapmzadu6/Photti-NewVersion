//
//  PWOAuthManager.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWOAuthManager.h"

#import "PAColors.h"

static NSString * const PWScope = @"https://picasaweb.google.com/data/";
static NSString * const PWClientID = @"982107973738-pqihuiltucj69o5413n38hm52lj3ubm3.apps.googleusercontent.com";
static NSString * const PWClientSecret = @"5OS58Vf-PA09YGHlFZUc_BtX";
static NSString * const PWKeyChainItemName = @"PWOAuthKeyChainItem";

static NSString * const kPWOAuthManagerOAuthErrorDomain = @"com.photti.PWOAuthManager";
static NSUInteger kPWOAuthManagerMaxCounfOfLoginError = 5;

@interface PWOAuthManager ()

@property (strong, nonatomic) GTMOAuth2Authentication *auth;
@property (nonatomic) NSUInteger countOfLoginError;

@end

@implementation PWOAuthManager

+ (PWOAuthManager *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        void (^block)() = ^{
            _auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PWKeyChainItemName clientID:PWClientID clientSecret:PWClientSecret];
            
            _countOfLoginError = 0;
        };
        if ([NSThread isMainThread]) {
            block();
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    }
    return self;
}

+ (void)refreshKeychain {
    void (^block)() = ^{
        [self.class sharedManager].auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PWKeyChainItemName clientID:PWClientID clientSecret:PWClientSecret];
    };
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (void)getAccessTokenWithCompletion:(void (^)(NSDictionary *, NSError *))completion {
    void (^block)() = ^(){
        GTMOAuth2Authentication *auth = [self sharedManager].auth;
        if (![auth canAuthorize]) {
            completion ? completion(nil, [NSError errorWithDomain:kPWOAuthManagerOAuthErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:auth.tokenURL];
        [auth authorizeRequest:request completionHandler:^(NSError *error) {
            if (error) {
                completion ? completion(nil, [NSError errorWithDomain:kPWOAuthManagerOAuthErrorDomain code:0 userInfo:nil]) : 0;
            }
            else {
                completion ? completion(request.allHTTPHeaderFields, nil) : 0;
            }
        }];
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (void)getAuthorizeHTTPHeaderFields:(void (^)(NSDictionary *, NSError *))completion {
    [self getAccessTokenWithCompletion:^(NSDictionary *headerFields, NSError *error) {
        if (error) {
            completion ? completion(nil, [NSError errorWithDomain:kPWOAuthManagerOAuthErrorDomain code:0 userInfo:nil]) : 0;
        }
        else {
            completion ? completion(headerFields, nil) : 0;
        }
    }];
}

+ (void)getUserData:(void (^)(NSString *, NSError *))completion {
    GTMOAuth2Authentication *auth = [self sharedManager].auth;
    if ([auth canAuthorize]) {
        completion ? completion(auth.userEmail, nil) : 0;
    }
    else {
        completion ? completion(nil, [NSError errorWithDomain:kPWOAuthManagerOAuthErrorDomain code:0 userInfo:nil]) : 0;
    }
}

+ (BOOL)isLogined {
    [self refreshKeychain];
    GTMOAuth2Authentication *auth = [self sharedManager].auth;
    return [GTMOAuth2ViewControllerTouch authorizeFromKeychainForName:PWKeyChainItemName authentication:auth error:nil];
}

+ (void)logout {
    void (^block)() = ^() {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PWKeyChainItemName];
        GTMOAuth2Authentication *auth = [self sharedManager].auth;
        [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:auth];
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (void)loginViewControllerWithCompletion:(void (^)(UINavigationController *))completion finish:(void (^)())finish {
    void (^block)() = ^() {
        GTMOAuth2ViewControllerTouch *viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:PWScope clientID:PWClientID clientSecret:PWClientSecret keychainItemName:PWKeyChainItemName completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
            [self sharedManager].auth = auth;
            [viewController dismissViewControllerAnimated:YES completion:^{
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:auth.tokenURL];
                [auth authorizeRequest:request completionHandler:^(NSError *error) {
                    if (!error) {
                        finish ? finish() : 0;
                    }
                }];
            }];
        }];
        viewController.keychainItemAccessibility = kSecAttrAccessibleAfterFirstUnlock;
        viewController.automaticallyAdjustsScrollViewInsets = NO;
        viewController.edgesForExtendedLayout = UIRectEdgeAll;
        viewController.title = NSLocalizedString(@"Login", nil);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            for (UIView *view in viewController.view.subviews) {
                if ([view isKindOfClass:[UIWebView class]]) {
                    UIWebView *webView = (UIWebView *)view;
                    webView.scrollView.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
                    webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
                }
            }
        }
        for (UIView *view in viewController.navigationItem.rightBarButtonItem.customView.subviews) {
            if ([view isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)view;
                button.titleLabel.shadowOffset = CGSizeZero;
                button.titleLabel.shadowColor = [UIColor clearColor];
            }
        }
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        navigationController.view.backgroundColor = [UIColor whiteColor];
        navigationController.automaticallyAdjustsScrollViewInsets = NO;
        navigationController.edgesForExtendedLayout = UIRectEdgeAll;
        navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
        navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PAColors getColor:PAColorsTypeTextColor]};
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        completion ? completion(navigationController) : 0;
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (NSUInteger)countOfLoginError {
    return [self sharedManager].countOfLoginError;
}

+ (BOOL)shouldOpenLoginViewController {
    return ([self sharedManager].countOfLoginError > kPWOAuthManagerMaxCounfOfLoginError) ? YES : NO;
}

+ (void)incrementCountOfLoginError {
    [self sharedManager].countOfLoginError++;
}

+ (void)resetCountOfLoginError {
    [self sharedManager].countOfLoginError = 0;
}

@end
