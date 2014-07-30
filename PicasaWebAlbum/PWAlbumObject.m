//
//  Album.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/31.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumObject.h"
#import "PWGPhotoObject.h"
#import "PWPhotoLinkObject.h"
#import "PWPhotoMediaObject.h"


@implementation PWAlbumObject

@dynamic author_name;
@dynamic author_url;
@dynamic category_scheme;
@dynamic category_term;
@dynamic edited;
@dynamic id_str;
@dynamic published;
@dynamic rights;
@dynamic sortIndex;
@dynamic summary;
@dynamic timestamp;
@dynamic title;
@dynamic type;
@dynamic updated;
@dynamic userid;
@dynamic tag_thumbnail_url;
@dynamic tag_updated;
@dynamic gphoto;
@dynamic link;
@dynamic media;

- (void)addLinkObject:(PWPhotoLinkObject *)value {
    NSMutableSet *tempSet = [NSMutableSet setWithSet:self.link];
    [tempSet addObject:value];
    self.link = tempSet;
}

- (void)removeLinkObject:(PWPhotoLinkObject *)value {
    NSMutableSet *tempSet = [NSMutableSet setWithSet:self.link];
    [tempSet removeObject:value];
    self.link = tempSet;
}

@end
