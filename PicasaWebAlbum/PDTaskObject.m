//
//  PDTaskObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskObject.h"
#import "PDBasePhotoObject.h"


@implementation PDTaskObject

@dynamic error_description;
@dynamic sort_index;
@dynamic to_album_id_str;
@dynamic from_album_id_str;
@dynamic type;
@dynamic photos;

- (void)insertObject:(PDBasePhotoObject *)value inPhotosAtIndex:(NSUInteger)idx {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet insertObject:value atIndex:idx];
    self.photos = mOrderedSet;
}

- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObjectAtIndex:idx];
    self.photos = mOrderedSet;
}

- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet insertObjects:value atIndexes:indexes];
    self.photos = mOrderedSet;
}

- (void)removePhotosAtIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObjectsAtIndexes:indexes];
    self.photos = mOrderedSet;
}

- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet replaceObjectAtIndex:idx withObject:value];
    self.photos = mOrderedSet;
}

- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.photos = mOrderedSet;
}

- (void)addPhotosObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet addObject:value];
    self.photos = mOrderedSet;
}

- (void)removePhotosObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObject:value];
    self.photos = mOrderedSet;
}

- (void)addPhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet addObjectsFromArray:values.array];
    self.photos = mOrderedSet;
}

- (void)removePhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObjectsInArray:values.array];
    self.photos = mOrderedSet;
}

@end
