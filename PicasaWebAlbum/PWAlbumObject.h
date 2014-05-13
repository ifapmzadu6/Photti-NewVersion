//
//  Album.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PWGPhotoObject, PWPhotoLinkObject, PWPhotoMediaObject;

@interface PWAlbumObject : NSManagedObject

@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSString * author_url;
@property (nonatomic, retain) NSString * author_name;
@property (nonatomic, retain) NSString * timestamp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * userid;
@property (nonatomic, retain) NSString * category_scheme;
@property (nonatomic, retain) NSString * category_term;
@property (nonatomic, retain) NSString * published;
@property (nonatomic, retain) NSString * rights;
@property (nonatomic, retain) NSNumber * sortIndex;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * updated;
@property (nonatomic, retain) NSString * edited;
@property (nonatomic, retain) NSSet *link;
@property (nonatomic, retain) PWGPhotoObject *gphoto;
@property (nonatomic, retain) PWPhotoMediaObject *media;

@end

@interface PWAlbumObject (CoreDataGeneratedAccessors)

- (void)addLinkObject:(PWPhotoLinkObject *)value;
- (void)removeLinkObject:(PWPhotoLinkObject *)value;
- (void)addLink:(NSSet *)values;
- (void)removeLink:(NSSet *)values;

@end
