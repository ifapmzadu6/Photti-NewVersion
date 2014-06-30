//
//  PWOAuthManager.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

#import <GTMOAuth2Authentication.h>
#import <GTMOAuth2ViewControllerTouch.h>

@interface PWOAuthManager : NSObject

+ (void)getAuthorizeHTTPHeaderFields:(void (^)(NSDictionary *headerFields, NSError *error))completion;
+ (void)getUserData:(void (^)(NSString *email, NSError *error))completion;
+ (BOOL)isLogined;
+ (void)logout;
+ (void)loginViewControllerWithCompletion:(void (^)(UINavigationController *))completion finish:(void (^)())finish;

@end
