//
//  PDBaseTaskObject.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDBaseTaskObject.h"
#import "PDBasePhotoObject.h"


@implementation PDBaseTaskObject

@dynamic count;
@dynamic sortIndex;
@dynamic photos;

- (void)insertObject:(PDBasePhotoObject *)value inPhotosAtIndex:(NSUInteger)idx {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet insertObject:value atIndex:idx];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObjectAtIndex:idx];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet insertObjects:value atIndexes:indexes];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)removePhotosAtIndexes:(NSIndexSet *)indexes {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObjectsAtIndexes:indexes];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet replaceObjectAtIndex:idx withObject:value];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)addPhotosObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet addObject:value];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)removePhotosObject:(PDBasePhotoObject *)value {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObject:value];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)addPhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet addObjectsFromArray:values.array];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

- (void)removePhotos:(NSOrderedSet *)values {
    NSMutableOrderedSet *mOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [mOrderedSet removeObjectsInArray:values.array];
    self.photos = mOrderedSet;
    
    self.count = @(self.photos.count);
}

@end
