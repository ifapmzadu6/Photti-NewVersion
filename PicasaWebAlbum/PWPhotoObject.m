//
//  PWPhotoObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoObject.h"
#import "PWGPhotoObject.h"
#import "PWPhotoExitObject.h"
#import "PWPhotoLinkObject.h"
#import "PWPhotoMediaObject.h"


@implementation PWPhotoObject

@dynamic app_edited;
@dynamic category_cheme;
@dynamic category_term;
@dynamic content_src;
@dynamic content_type;
@dynamic id_str;
@dynamic published;
@dynamic rights;
@dynamic summary;
@dynamic title;
@dynamic updated;
@dynamic exif;
@dynamic gphoto;
@dynamic link;
@dynamic media;

- (void)addLinkObject:(PWPhotoLinkObject *)value {
    NSMutableSet *tempSet = [NSMutableSet setWithSet:self.link];
    [tempSet addObject:value];
    self.link = tempSet;
}

@end
