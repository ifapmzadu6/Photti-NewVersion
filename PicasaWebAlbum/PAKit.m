//
//  PAKit.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAKit.h"

#import "PASnowFlake.h"

@interface PAKit ()

@end

@implementation PAKit

+ (NSString *)makeUniquePathInTmpDir {
    NSString *homeDirectory = [NSString stringWithString:NSHomeDirectory()];
    NSString *tmpDirectory = [homeDirectory stringByAppendingPathComponent:@"/tmp"];
    NSString *filePath = [tmpDirectory stringByAppendingFormat:@"/%@", [PASnowFlake generateUniqueIDString]];
    return [filePath stringByStandardizingPath];
}

@end
