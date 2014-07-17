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
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet insertObject:value atIndex:idx];
    self.photos = orderedSet;
    
    value.task = self;
}

- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet removeObjectAtIndex:idx];
    self.photos = orderedSet;
}

- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet insertObjects:value atIndexes:indexes];
    self.photos = orderedSet;
    
    for (PDBasePhotoObject *photo in value) {
        photo.task = self;
    }
}

- (void)removePhotosAtIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet removeObjectsAtIndexes:indexes];
    self.photos = orderedSet;
}

- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet replaceObjectAtIndex:idx withObject:value];
    self.photos = orderedSet;
    
    value.task = self;
}

- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.photos = orderedSet;
    
    for (PDBasePhotoObject *photo in values) {
        photo.task = self;
    }
}

- (void)addPhotosObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet addObject:value];
    self.photos = orderedSet;
    
    value.task = self;
}

- (void)removePhotosObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet removeObject:value];
    self.photos = orderedSet;    
}

- (void)addPhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet addObjectsFromArray:values.array];
    self.photos = orderedSet;
    
    for (PDBasePhotoObject *photo in values) {
        photo.task = self;
    }
}

- (void)removePhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [orderedSet removeObjectsInArray:values.array];
    self.photos = orderedSet;
}

@end
