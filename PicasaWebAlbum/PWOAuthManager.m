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
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.view.backgroundColor = [UIColor whiteColor];
    
    return navigationController;
}

+ (void)logout {
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PWKeyChainItemName];
    GTMOAuth2Authentication *auth = [PWOAuthManager authentication];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:auth];
}

@end
