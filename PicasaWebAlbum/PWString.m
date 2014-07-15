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
        NSString *localizedString = NSLocalizedString(@"%ld photos, %d videos", nil);
        return [NSString stringWithFormat:localizedString, (long)photoCount, (long)videoCount];
    }
    else if (photoCount > 0) {
        NSString *localizedString = NSLocalizedString(@"%ld photos", nil);
        return [NSString stringWithFormat:localizedString, (long)photoCount];
    }
    else if (photoCount) {
        return NSLocalizedString(@"a photo", nil);
    }
    else if (videoCount > 0) {
        NSString *localizedString = NSLocalizedString(@"%ld videos", nil);
        return [NSString stringWithFormat:localizedString, (long)videoCount];
    }
    else if (videoCount) {
        return NSLocalizedString(@"a video", nil);
    }
    else {
        return nil;
    }
}

@end
