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

@interface PWOAuthManager ()

@property (strong, nonatomic) GTMOAuth2Authentication *auth;

@end

@implementation PWOAuthManager

+ (id)sharedManager {
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
    _auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PWKeyChainItemName clientID:PWClientID clientSecret:PWClientSecret];
}

+ (void)getAuthWithCompletion:(void (^)(GTMOAuth2Authentication *auth))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion([[PWOAuthManager sharedManager] auth]);
        }
    });
}

+ (void)authRefreshWithCompletion:(void (^)())completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PWOAuthManager sharedManager] authRefresh];
        if (completion) {
            completion();
        }
    });
}

+ (void)getAccessTokenWithCompletion:(void (^)(NSString *, NSError *))completion {
    [PWOAuthManager getAuthWithCompletion:^(GTMOAuth2Authentication *auth) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:auth.tokenURL];
        
        [auth authorizeRequest:request completionHandler:^(NSError *error) {
            if (error) {
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"com.photti.pwoauthmanager" code:401 userInfo:nil]);
                }
                return;
            }
            
            NSDictionary *headerFields = request.allHTTPHeaderFields;
            if (completion) {
                completion(headerFields[@"Authorization"], nil);
            }
        }];
    }];
}

+ (void)logout {
    dispatch_async(dispatch_get_main_queue(), ^{
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PWKeyChainItemName];
        [PWOAuthManager getAuthWithCompletion:^(GTMOAuth2Authentication *auth) {
            [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:auth];
        }];
    });
}

+ (void)loginViewControllerWithCompletion:(void (^)(UINavigationController *))completion finish:(void (^)())finish {
    dispatch_async(dispatch_get_main_queue(), ^{
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
        
        if (completion) {
            completion(navigationController);
        }
    });
}

@end
