//
//  PWPhotoObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/30.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoObject.h"
#import "PWGPhotoObject.h"
#import "PWPhotoExitObject.h"
#import "PWPhotoLinkObject.h"
#import "PWPhotoMediaObject.h"


@implementation PWPhotoObject

@dynamic albumid;
@dynamic app_edited;
@dynamic category_cheme;
@dynamic category_term;
@dynamic content_src;
@dynamic content_type;
@dynamic id_str;
@dynamic pos;
@dynamic published;
@dynamic rights;
@dynamic sortIndex;
@dynamic summary;
@dynamic title;
@dynamic updated_str;
@dynamic tag_originalimage_url;
@dynamic tag_screenimage_url;
@dynamic tag_thumbnail_url;
@dynamic tag_type;
@dynamic exif;
@dynamic gphoto;
@dynamic link;
@dynamic media;

- (void)addLinkObject:(PWPhotoLinkObject *)value {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.link];
    [tmpSet addObject:value];
    self.link = tmpSet.copy;
}

@end
