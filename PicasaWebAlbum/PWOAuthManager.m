//
//  PWOAuthManager.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWOAuthManager.h"

static NSString * const PWScope = @"https://picasaweb.google.com/data/";
static NSString * const PWClientID = @"982107973738-pqihuiltucj69o5413n38hm52lj3ubm3.apps.googleusercontent.com";
static NSString * const PWClientSecret = @"5OS58Vf-PA09YGHlFZUc_BtX";
static NSString * const PWKeyChainItemName = @"PWOAuthKeyChainItem";

@interface PWOAuthManager ()

@end

@implementation PWOAuthManager

+ (PWOAuthManager *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

+ (GTMOAuth2Authentication *)authentication {
    GTMOAuth2Authentication *auth =  [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PWKeyChainItemName clientID:PWClientID clientSecret:PWClientSecret];
    
    return auth;
}

+ (BOOL)isLogin {
    GTMOAuth2Authentication *auth = [PWOAuthManager authentication];
    BOOL isLogin = [auth canAuthorize];
    if (!isLogin) {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:auth.tokenURL];
        isLogin = [auth authorizeRequest:request];
        [auth authorizeRequest:request completionHandler:^(NSError *error) {
            NSLog(@"%@",error);
        }];
        NSLog(@"Auth was expired. So refresh the token of auth.");
        
        return NO;
    }
    
    return YES;
}

+ (UINavigationController *)loginViewControllerWithCompletionHandler:(GTMOAuth2ViewControllerCompletionHandler)completionHandler {
    GTMOAuth2ViewControllerTouch *viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:PWScope clientID:PWClientID clientSecret:PWClientSecret keychainItemName:PWKeyChainItemName completionHandler:completionHandler];
    viewController.automaticallyAdjustsScrollViewInsets = NO;
    for (UIView *view in viewController.view.subviews) {
        if ([view isKindOfClass:[UIWebView class]]) {
            UIWebView *webView = (UIWebView *)view;
            webView.scrollView.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
        }
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.view.backgroundColor = [UIColor whiteColor];
    navigationController.automaticallyAdjustsScrollViewInsets = NO;
    
    return navigationController;
}

+ (void)authorizeActionWithViewController:(UIViewController *)viewController actionBlock:(void (^)())actionBlock {
    if ([PWOAuthManager isLogin]) {
        if (actionBlock) {
            actionBlock();
        }
    }
    else {
        UINavigationController *navigationController = [PWOAuthManager loginViewControllerWithCompletionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
            [viewController dismissViewControllerAnimated:YES completion:^{
                if (actionBlock) {
                    actionBlock();
                }
            }];
        }];
        [viewController presentViewController:navigationController animated:YES completion:nil];
    }
}

+ (void)logout {
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PWKeyChainItemName];
    GTMOAuth2Authentication *auth = [PWOAuthManager authentication];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:auth];
}

@end
