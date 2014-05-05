//
//  PWOAuthManager.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GTMOAuth2Authentication.h>
#import <GTMOAuth2ViewControllerTouch.h>

@interface PWOAuthManager : NSObject

+ (PWOAuthManager *)sharedManager;

+ (GTMOAuth2Authentication *)authentication;

+ (BOOL)isLogin;
+ (UINavigationController *)loginViewControllerWithCompletionHandler:(GTMOAuth2ViewControllerCompletionHandler)completionHandler;
+ (void)logout;

@end
