//
//  PWPhotoMediaObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/30.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

@class Album, PWPhotoMediaContentObject, PWPhotoMediaThumbnailObject, PWPhotoObject;

@interface PWPhotoMediaObject : NSManagedObject

@property (nonatomic, retain) NSString * credit;
@property (nonatomic, retain) NSString * description_text;
@property (nonatomic, retain) NSString * keywords;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Album *album;
@property (nonatomic, retain) NSOrderedSet *content;
@property (nonatomic, retain) PWPhotoObject *photo;
@property (nonatomic, retain) NSOrderedSet *thumbnail;
@end

@interface PWPhotoMediaObject (CoreDataGeneratedAccessors)

- (void)insertObject:(PWPhotoMediaContentObject *)value inContentAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContentAtIndex:(NSUInteger)idx;
- (void)insertContent:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContentAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContentAtIndex:(NSUInteger)idx withObject:(PWPhotoMediaContentObject *)value;
- (void)replaceContentAtIndexes:(NSIndexSet *)indexes withContent:(NSArray *)values;
- (void)addContentObject:(PWPhotoMediaContentObject *)value;
- (void)removeContentObject:(PWPhotoMediaContentObject *)value;
- (void)addContent:(NSOrderedSet *)values;
- (void)removeContent:(NSOrderedSet *)values;
- (void)insertObject:(PWPhotoMediaThumbnailObject *)value inThumbnailAtIndex:(NSUInteger)idx;
- (void)removeObjectFromThumbnailAtIndex:(NSUInteger)idx;
- (void)insertThumbnail:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeThumbnailAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInThumbnailAtIndex:(NSUInteger)idx withObject:(PWPhotoMediaThumbnailObject *)value;
- (void)replaceThumbnailAtIndexes:(NSIndexSet *)indexes withThumbnail:(NSArray *)values;
- (void)addThumbnailObject:(PWPhotoMediaThumbnailObject *)value;
- (void)removeThumbnailObject:(PWPhotoMediaThumbnailObject *)value;
- (void)addThumbnail:(NSOrderedSet *)values;
- (void)removeThumbnail:(NSOrderedSet *)values;
@end
