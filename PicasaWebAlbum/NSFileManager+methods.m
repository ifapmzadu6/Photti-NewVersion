//
//  NSFileManager+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "NSFileManager+methods.h"

@implementation NSFileManager (methods)

+ (void)cancelProtect:(NSString *)path {
    NSDictionary* attributes =
    [NSDictionary dictionaryWithObject:NSFileProtectionNone forKey:NSFileProtectionKey];
    NSError* error = nil;
    [[NSFileManager alloc] setAttributes:attributes ofItemAtPath:path error:&error];
}

@end
