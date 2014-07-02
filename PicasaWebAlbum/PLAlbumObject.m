//
//  PLAlbumObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumObject.h"
#import "PLPhotoObject.h"


@implementation PLAlbumObject

@dynamic id_str;
@dynamic type;
@dynamic name;
@dynamic url;
@dynamic timestamp;
@dynamic import;
@dynamic update;
@dynamic tag_type;
@dynamic tag_uploading_type;
@dynamic tag_date;
@dynamic tag_enddate;
@dynamic edited;
@dynamic photos;
@dynamic thumbnail;

- (void)insertObject:(PLPhotoObject *)value inPhotosAtIndex:(NSUInteger)idx {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet insertObject:value atIndex:idx];
    self.photos = tmpSet;
}

- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet removeObjectAtIndex:idx];
    self.photos = tmpSet;
}

- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet insertObjects:value atIndexes:indexes];
    self.photos = tmpSet;
}

- (void)removePhotosAtIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet removeObjectsAtIndexes:indexes];
    self.photos = tmpSet;
}

- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PLPhotoObject *)value {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet replaceObjectAtIndex:idx withObject:value];
    self.photos = tmpSet;
}

- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.photos = tmpSet;
}

- (void)addPhotosObject:(PLPhotoObject *)value {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet addObject:value];
    self.photos = tmpSet;
}

- (void)removePhotosObject:(PLPhotoObject *)value {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet removeObject:value];
    self.photos = tmpSet;
}

- (void)addPhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet addObjectsFromArray:values.array];
    self.photos = tmpSet;
}

- (void)removePhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *tmpSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tmpSet removeObjectsInArray:values.array];
    self.photos = tmpSet;
}

@end
