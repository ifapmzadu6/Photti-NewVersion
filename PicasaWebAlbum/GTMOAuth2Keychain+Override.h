//
//  GTMOAuth2Keychain+Override.h.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

#import <GTMOAuth2ViewControllerTouch.h>

@interface GTMOAuth2Keychain (override)

+ (void)switchOverrideMethods;


+ (NSMutableDictionary *)overrideKeychainQueryForService:(NSString *)service account:(NSString *)account;

@end
