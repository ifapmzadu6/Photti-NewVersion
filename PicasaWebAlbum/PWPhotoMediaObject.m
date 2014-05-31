//
//  PWPhotoMediaObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/30.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoMediaObject.h"
#import "PWAlbumObject.h"
#import "PWPhotoMediaContentObject.h"
#import "PWPhotoMediaThumbnailObject.h"
#import "PWPhotoObject.h"


@implementation PWPhotoMediaObject

@dynamic credit;
@dynamic description_text;
@dynamic keywords;
@dynamic title;
@dynamic album;
@dynamic content;
@dynamic photo;
@dynamic thumbnail;

- (void)addContentObject:(PWPhotoMediaContentObject *)value {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tmpSet addObject:value];
    self.content = tmpSet.copy;
}

- (void)addThumbnailObject:(PWPhotoMediaThumbnailObject *)value {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.thumbnail];
    [tmpSet addObject:value];
    self.thumbnail = tmpSet.copy;
}

@end
