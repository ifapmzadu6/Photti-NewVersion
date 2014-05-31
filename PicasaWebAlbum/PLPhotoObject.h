//
//  PLPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/31.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PLAlbumObject;

@interface PLPhotoObject : NSManagedObject

@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSDate * import;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * tag_albumtype;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSSet *albums;
@property (nonatomic, retain) PLAlbumObject *thumbnailed;
@end

@interface PLPhotoObject (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(PLAlbumObject *)value;
- (void)removeAlbumsObject:(PLAlbumObject *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

@end
