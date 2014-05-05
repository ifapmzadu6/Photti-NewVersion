//
//  PWPhotoExitObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PWPhotoObject;

@interface PWPhotoExitObject : NSManagedObject

@property (nonatomic, retain) NSString * distance;
@property (nonatomic, retain) NSString * exposure;
@property (nonatomic, retain) NSString * flash;
@property (nonatomic, retain) NSString * focallength;
@property (nonatomic, retain) NSString * fstop;
@property (nonatomic, retain) NSString * imageUniqueID;
@property (nonatomic, retain) NSString * iso;
@property (nonatomic, retain) NSString * make;
@property (nonatomic, retain) NSString * model;
@property (nonatomic, retain) NSString * time;
@property (nonatomic, retain) PWPhotoObject *photo;

@end
