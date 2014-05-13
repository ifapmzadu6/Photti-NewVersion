//
//  PWPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

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
@property (nonatomic, retain) NSString * updated;
@property (nonatomic, retain) PWPhotoExitObject *exif;
@property (nonatomic, retain) PWGPhotoObject *gphoto;
@property (nonatomic, retain) NSSet *link;
@property (nonatomic, retain) PWPhotoMediaObject *media;
@end

@interface PWPhotoObject (CoreDataGeneratedAccessors)

- (void)addLinkObject:(PWPhotoLinkObject *)value;
- (void)removeLinkObject:(PWPhotoLinkObject *)value;
- (void)addLink:(NSSet *)values;
- (void)removeLink:(NSSet *)values;

@end
