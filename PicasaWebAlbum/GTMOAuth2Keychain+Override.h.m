//
//  GTMOAuth2Keychain+Override.h.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "GTMOAuth2Keychain+Override.h"

@import Security;

@implementation GTMOAuth2Keychain (override)

+ (NSMutableDictionary *)keychainQueryForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                                  @"OAuth", (__bridge id)kSecAttrGeneric,
                                  account, (__bridge id)kSecAttrAccount,
                                  service, (__bridge id)kSecAttrService,
                                  kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
                                  nil];
    return query;
}

@end
