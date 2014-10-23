//
//  PWPhotoObject+Methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/12.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoObject+Methods.h"

#import "PWModelObject.h"
#import "PWCoreDataAPI.h"

@implementation PWPhotoObject (Methods)

+ (PWPhotoObject *)getPhotoObjectWithID:(NSString *)id_str {
    __block PWPhotoObject *photoObject = nil;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count > 0) {
            photoObject = objects.firstObject;
        }
    }];
    return photoObject;
}

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
