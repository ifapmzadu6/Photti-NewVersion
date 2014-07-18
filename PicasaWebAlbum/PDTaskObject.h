//
//  PDTaskObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

@class PDBasePhotoObject;

@interface PDTaskObject : NSManagedObject

@property (nonatomic, retain) NSString * error_description;
@property (nonatomic, retain) NSString * from_album_id_str;
@property (nonatomic, retain) NSNumber * sort_index;
@property (nonatomic, retain) NSString * to_album_id_str;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSOrderedSet *photos;
@end

@interface PDTaskObject (CoreDataGeneratedAccessors)

- (void)insertObject:(PDBasePhotoObject *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PDBasePhotoObject *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(PDBasePhotoObject *)value;
- (void)removePhotosObject:(PDBasePhotoObject *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
@end
