//
//  Album.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumObject.h"
#import "PWGPhotoObject.h"
#import "PWPhotoLinkObject.h"
#import "PWPhotoMediaObject.h"

@implementation PWAlbumObject

@dynamic id_str;
@dynamic author_url;
@dynamic author_name;
@dynamic timestamp;
@dynamic type;
@dynamic userid;
@dynamic category_scheme;
@dynamic category_term;
@dynamic published;
@dynamic rights;
@dynamic sortIndex;
@dynamic summary;
@dynamic title;
@dynamic updated;
@dynamic edited;
@dynamic gphoto;
@dynamic link;
@dynamic media;

- (void)addLinkObject:(PWPhotoLinkObject *)value {
    NSMutableSet *tempSet = [NSMutableSet setWithSet:self.link];
    [tempSet addObject:value];
    self.link = tempSet;
}

@end
