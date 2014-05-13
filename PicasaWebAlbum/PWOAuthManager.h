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

+ (GTMOAuth2Authentication *)authentication;
+ (void)getAccessTokenWithCompletion:(void (^)(NSString *accessToken))completion;
+ (void)logout;
+ (UINavigationController *)loginViewControllerWithCompletion:(void (^)())completion;

@end
