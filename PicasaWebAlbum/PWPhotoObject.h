//
//  PWPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/30.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

@class PWGPhotoObject, PWPhotoExitObject, PWPhotoLinkObject, PWPhotoMediaObject;

@interface PWPhotoObject : NSManagedObject

@property (nonatomic, retain) NSString * albumid;
@property (nonatomic, retain) NSString * app_edited;
@property (nonatomic, retain) NSString * category_cheme;
@property (nonatomic, retain) NSString * category_term;
@property (nonatomic, retain) NSString * content_src;
@property (nonatomic, retain) NSString * content_type;
@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSString * pos;
@property (nonatomic, retain) NSString * published;
@property (nonatomic, retain) NSString * rights;
@property (nonatomic, retain) NSNumber * sortIndex;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * updated_str;
@property (nonatomic, retain) NSString * tag_originalimage_url;
@property (nonatomic, retain) NSString * tag_screenimage_url;
@property (nonatomic, retain) NSString * tag_thumbnail_url;
@property (nonatomic, retain) NSNumber * tag_type;
@property (nonatomic, retain) PWPhotoExitObject *exif;
@property (nonatomic, retain) PWGPhotoObject *gphoto;
@property (nonatomic, retain) NSOrderedSet *link;
@property (nonatomic, retain) PWPhotoMediaObject *media;
@end

@interface PWPhotoObject (CoreDataGeneratedAccessors)

- (void)insertObject:(PWPhotoLinkObject *)value inLinkAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLinkAtIndex:(NSUInteger)idx;
- (void)insertLink:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLinkAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLinkAtIndex:(NSUInteger)idx withObject:(PWPhotoLinkObject *)value;
- (void)replaceLinkAtIndexes:(NSIndexSet *)indexes withLink:(NSArray *)values;
- (void)addLinkObject:(PWPhotoLinkObject *)value;
- (void)removeLinkObject:(PWPhotoLinkObject *)value;
- (void)addLink:(NSOrderedSet *)values;
- (void)removeLink:(NSOrderedSet *)values;
@end
