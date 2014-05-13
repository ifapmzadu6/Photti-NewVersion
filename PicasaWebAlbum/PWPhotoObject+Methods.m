//
//  PWPhotoObject+Methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/12.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoObject+Methods.h"

#import "PWGPhotoObject.h"

@implementation PWPhotoObject (Methods)

+ (void)getCountFromPhotoObjects:(NSArray *)photos completion:(void (^)(NSUInteger, NSUInteger))completion {
    NSUInteger countOfPhoto = 0;
    NSUInteger countOfVideo = 0;
    for (PWPhotoObject *photo in photos) {
        if (photo.gphoto.originalvideo_videoCodec) {
            countOfVideo++;
        }
        else {
            countOfPhoto++;
        }
    }
    if (completion) {
        completion(countOfPhoto, countOfVideo);
    }
}

@end
