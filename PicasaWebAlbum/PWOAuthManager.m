//
//  PWOAuthManager.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWOAuthManager.h"

//#import <GTMOAuth2Authentication.h>
//#import <GTMOAuth2ViewControllerTouch.h>

static NSString * const PWScope = @"https://picasaweb.google.com/data/";
static NSString * const PWClientID = @"982107973738-pqihuiltucj69o5413n38hm52lj3ubm3.apps.googleusercontent.com";
static NSString * const PWClientSecret = @"5OS58Vf-PA09YGHlFZUc_BtX";
static NSString * const PWKeyChainItemName = @"PWOAuthKeyChainItem";

#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
block();\
}\
else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}

@interface PWOAuthManager ()

@end

@implementation PWOAuthManager
+ (GTMOAuth2Authentication *)authentication {
    return [PWOAuthManager authenticationWithRefresh:NO];
}

+ (GTMOAuth2Authentication *)authenticationWithRefresh:(BOOL)refresh {
    static dispatch_once_t once;
    static id auth;
    if (refresh) {
        dispatch_main_sync_safe(^{
            auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PWKeyChainItemName clientID:PWClientID clientSecret:PWClientSecret];
        });
    }
    else {
        dispatch_once(&once, ^{
            dispatch_main_sync_safe(^{
                auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PWKeyChainItemName clientID:PWClientID clientSecret:PWClientSecret];
            });
        });
    }
    return auth;
}

+ (void)getAccessTokenWithCompletion:(void (^)(NSString *))completion {
    dispatch_main_sync_safe(^{
        GTMOAuth2Authentication *auth = [PWOAuthManager authentication];
        NSString *accessToken = [auth accessToken];
        if (accessToken) {
            if (completion) {
                completion(accessToken);
            }
            return;
        }
        
        if (![auth canAuthorize]) {
            auth = [PWOAuthManager authenticationWithRefresh:YES];
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:auth.tokenURL];
        [auth authorizeRequest:request completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"AuthorizeRequest Error!");
                NSLog(@"%@", error.description);
                return;
            }
            
            if (completion) {
                completion([auth accessToken]);
            }
        }];
    });
}

+ (void)authorizeRequestWithCompletion:(void (^)(NSError *error))completion {
    dispatch_main_sync_safe(^{
        GTMOAuth2Authentication *newAuth = [PWOAuthManager authenticationWithRefresh:YES];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:newAuth.tokenURL];
        [newAuth authorizeRequest:request completionHandler:completion];
    });
}

+ (void)logout {
    dispatch_main_sync_safe(^{
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PWKeyChainItemName];
        [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:[PWOAuthManager authentication]];
    });
}

+ (UINavigationController *)loginViewControllerWithCompletion:(void (^)())completion {
    __block UINavigationController *navigationController = nil;
    dispatch_main_sync_safe(^{
        GTMOAuth2ViewControllerTouch *viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:PWScope clientID:PWClientID clientSecret:PWClientSecret keychainItemName:PWKeyChainItemName completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
            [viewController dismissViewControllerAnimated:YES completion:^{
                [PWOAuthManager authorizeRequestWithCompletion:^(NSError *error) {
                    if (!error) {
                        if (completion) {
                            completion();
                        }
                    }
                }];
            }];
        }];
        viewController.automaticallyAdjustsScrollViewInsets = NO;
        for (UIView *view in viewController.view.subviews) {
            if ([view isKindOfClass:[UIWebView class]]) {
                UIWebView *webView = (UIWebView *)view;
                webView.scrollView.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
                webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
            }
        }
        
        navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        navigationController.view.backgroundColor = [UIColor whiteColor];
        navigationController.automaticallyAdjustsScrollViewInsets = NO;
    });
    return navigationController;
}

@end
