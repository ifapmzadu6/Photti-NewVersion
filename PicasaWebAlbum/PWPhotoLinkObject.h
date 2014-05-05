//
//  PWPhotoLinkObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PWPhotoObject;

@interface PWPhotoLinkObject : NSManagedObject

@property (nonatomic, retain) NSString * href;
@property (nonatomic, retain) NSString * rel;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) PWPhotoObject *photo;

@end
