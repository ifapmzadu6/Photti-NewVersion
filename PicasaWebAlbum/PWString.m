//
//  PWString.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/12.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWString.h"

@implementation PWString

+ (NSString *)itemNameFromPhotoCount:(NSUInteger)photoCount videoCount:(NSUInteger)videoCount {
    if (photoCount > 0 && videoCount > 0) {
        return @"items";
    }
    else if (photoCount > 0) {
        return @"photos";
    }
    else if (photoCount) {
        return @"photo";
    }
    else if (videoCount > 0) {
        return @"videos";
    }
    else if (videoCount) {
        return @"video";
    }
    else {
        return nil;
    }
}

+ (NSString *)photoAndVideoStringWithPhotoCount:(NSUInteger)photoCount videoCount:(NSUInteger)videoCount {
    if (photoCount > 0 && videoCount > 0) {
        NSString *localizedString = NSLocalizedString(@"%d枚の写真、%d本のビデオ", nil);
        return [NSString stringWithFormat:localizedString, photoCount, videoCount];
    }
    else if (photoCount > 0) {
        NSString *localizedString = NSLocalizedString(@"%d枚の写真", nil);
        return [NSString stringWithFormat:localizedString, photoCount];
    }
    else if (photoCount) {
        NSString *localizedString = NSLocalizedString(@"%d枚の写真", nil);
        return [NSString stringWithFormat:localizedString, photoCount];
    }
    else if (videoCount > 0) {
        NSString *localizedString = NSLocalizedString(@"%d本のビデオ", nil);
        return [NSString stringWithFormat:localizedString, videoCount];
    }
    else if (videoCount) {
        NSString *localizedString = NSLocalizedString(@"%d本のビデオ", nil);
        return [NSString stringWithFormat:localizedString, videoCount];
    }
    else {
        return nil;
    }
}

@end
