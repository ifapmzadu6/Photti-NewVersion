//
//  PWOAuthManager.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWOAuthManager.h"

#import "PWColors.h"

static NSString * const PWScope = @"https://picasaweb.google.com/data/";
static NSString * const PWClientID = @"982107973738-pqihuiltucj69o5413n38hm52lj3ubm3.apps.googleusercontent.com";
static NSString * const PWClientSecret = @"5OS58Vf-PA09YGHlFZUc_BtX";
static NSString * const PWKeyChainItemName = @"PWOAuthKeyChainItem";

@interface PWOAuthManager ()

@property (strong, nonatomic) GTMOAuth2Authentication *auth;

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
        [self authRefresh];
    }
    return self;
}

- (void)authRefresh {
    void (^block)() = ^{
        _auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PWKeyChainItemName clientID:PWClientID clientSecret:PWClientSecret];
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)getAuthWithCompletion:(void (^)(GTMOAuth2Authentication *auth))completion {
    void (^block)() = ^() {
        GTMOAuth2Authentication *auth = [[PWOAuthManager sharedManager] auth];
        if (completion) {
            completion(auth);
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)authRefreshWithCompletion:(void (^)())completion {
    void (^block)() = ^() {
        [[PWOAuthManager sharedManager] authRefresh];
        if (completion) {
            completion();
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)getAccessTokenWithCompletion:(void (^)(NSDictionary *, NSError *))completion {
    [PWOAuthManager getAuthWithCompletion:^(GTMOAuth2Authentication *auth) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:auth.tokenURL];
        [auth authorizeRequest:request completionHandler:^(NSError *error) {
            if (error) {
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"com.photti.pwoauthmanager" code:401 userInfo:nil]);
                }
            }
            else {
                if (completion) {
                    completion(request.allHTTPHeaderFields, nil);
                }
            }
        }];
    }];
}

+ (void)getRefreshedAccessTokenWithCompletion:(void (^)(NSDictionary *, NSError *))completion {
    [PWOAuthManager authRefreshWithCompletion:^{
        [PWOAuthManager getAccessTokenWithCompletion:completion];
    }];
}

+ (void)getAuthorizeHTTPHeaderFields:(void (^)(NSDictionary *, NSError *))completion {
    [PWOAuthManager getAccessTokenWithCompletion:^(NSDictionary *headerFields, NSError *error) {
        if (error) {
            [PWOAuthManager getRefreshedAccessTokenWithCompletion:^(NSDictionary *headerFields, NSError *error) {
                if (error) {
                    if (completion) {
                        completion(nil, error);
                    }
                    return;
                }
                
                if (completion) {
                    completion(headerFields, nil);
                }
            }];
            return;
        }
        
        if (completion) {
            completion(headerFields, nil);
        }
    }];
}

+ (BOOL)isLogined {
    return [GTMOAuth2ViewControllerTouch authorizeFromKeychainForName:PWKeyChainItemName authentication:[[PWOAuthManager sharedManager] auth] error:nil];
}

+ (void)logout {
    void (^block)() = ^() {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PWKeyChainItemName];
        [PWOAuthManager getAuthWithCompletion:^(GTMOAuth2Authentication *auth) {
            [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:auth];
        }];
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)loginViewControllerWithCompletion:(void (^)(UINavigationController *))completion finish:(void (^)())finish {
    void (^block)() = ^() {
        GTMOAuth2ViewControllerTouch *viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:PWScope clientID:PWClientID clientSecret:PWClientSecret keychainItemName:PWKeyChainItemName completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
            [viewController dismissViewControllerAnimated:YES completion:^{
                [PWOAuthManager authRefreshWithCompletion:^{
                    [PWOAuthManager getAuthWithCompletion:^(GTMOAuth2Authentication *auth) {
                        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:auth.tokenURL];
                        [auth authorizeRequest:request completionHandler:^(NSError *error) {
                            if (!error) {
                                if (finish) {
                                    finish();
                                }
                            }
                        }];
                    }];
                }];
            }];
        }];
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
        navigationController.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
        navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        if (completion) {
            completion(navigationController);
        }
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end
