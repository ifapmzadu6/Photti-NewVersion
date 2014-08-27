//
//  PLPhotoObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPhotoObject.h"
#import "PLAlbumObject.h"

#import "PADateFormatter.h"

@implementation PLPhotoObject

@dynamic caption;
@dynamic date;
@dynamic duration;
@dynamic filename;
@dynamic height;
@dynamic id_str;
@dynamic import;
@dynamic latitude;
@dynamic longitude;
@dynamic tag_albumtype;
@dynamic tag_adjusted_date;
@dynamic timestamp;
@dynamic type;
@dynamic update;
@dynamic url;
@dynamic width;
@dynamic albums;
@dynamic thumbnailed;

- (void)addAlbumsObject:(PLAlbumObject *)value {
    self.albums = [self.albums setByAddingObject:value];;
}

- (void)removeAlbumsObject:(PLAlbumObject *)value {
    NSMutableSet *mutableSet = [NSMutableSet setWithSet:self.albums];
    [mutableSet removeObject:value];
    self.albums = mutableSet.copy;
}

- (void)addAlbums:(NSSet *)values {
    self.albums = [self.albums setByAddingObjectsFromSet:values];
}

- (void)removeAlbums:(NSSet *)values {
    NSMutableSet *mutableSet = [NSMutableSet setWithSet:self.albums];
    for (id object in values) {
        [mutableSet removeObject:object];
    }
    self.albums = mutableSet.copy;
}

- (NSString *)tag_adjusted_date {
    return [[PADateFormatter formatter] stringFromDate:[PADateFormatter adjustZeroClock:self.date]];
}

@end
