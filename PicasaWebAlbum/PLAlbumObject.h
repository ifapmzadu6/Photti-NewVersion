//
//  PLAlbumObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PLPhotoObject;

@interface PLAlbumObject : NSManagedObject

@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSDate * import;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) NSNumber * tag_type;
@property (nonatomic, retain) NSDate * tag_date;
@property (nonatomic, retain) NSDate * tag_enddate;
@property (nonatomic, retain) NSNumber * edited;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) PLPhotoObject *thumbnail;
@end

@interface PLAlbumObject (CoreDataGeneratedAccessors)

- (void)insertObject:(PLPhotoObject *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PLPhotoObject *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(PLPhotoObject *)value;
- (void)removePhotosObject:(PLPhotoObject *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
@end
