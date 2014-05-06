//
//  PWPhotoMediaObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PWPhotoMediaContentObject, PWPhotoMediaThumbnailObject, PWPhotoObject;

@interface PWPhotoMediaObject : NSManagedObject

@property (nonatomic, retain) NSString * credit;
@property (nonatomic, retain) NSString * description_text;
@property (nonatomic, retain) NSString * keywords;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *content;
@property (nonatomic, retain) PWPhotoObject *photo;
@property (nonatomic, retain) NSSet *thumbnail;
@end

@interface PWPhotoMediaObject (CoreDataGeneratedAccessors)

- (void)addContentObject:(PWPhotoMediaContentObject *)value;
- (void)removeContentObject:(PWPhotoMediaContentObject *)value;
- (void)addContent:(NSSet *)values;
- (void)removeContent:(NSSet *)values;

- (void)addThumbnailObject:(PWPhotoMediaThumbnailObject *)value;
- (void)removeThumbnailObject:(PWPhotoMediaThumbnailObject *)value;
- (void)addThumbnail:(NSSet *)values;
- (void)removeThumbnail:(NSSet *)values;

@end
