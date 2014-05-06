//
//  PWPhotoMediaObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoMediaObject.h"
#import "PWPhotoMediaContentObject.h"
#import "PWPhotoMediaThumbnailObject.h"
#import "PWPhotoObject.h"


@implementation PWPhotoMediaObject

@dynamic credit;
@dynamic description_text;
@dynamic keywords;
@dynamic title;
@dynamic content;
@dynamic photo;
@dynamic thumbnail;

- (void)addContentObject:(PWPhotoMediaContentObject *)value {
    NSMutableSet *tempSet = [NSMutableSet setWithSet:self.content];
    [tempSet addObject:value];
    self.content = tempSet;
}

- (void)addThumbnailObject:(PWPhotoMediaThumbnailObject *)value {
    NSMutableSet *tempSet = [NSMutableSet setWithSet:self.thumbnail];
    [tempSet addObject:value];
    self.thumbnail = tempSet;
}

@end
