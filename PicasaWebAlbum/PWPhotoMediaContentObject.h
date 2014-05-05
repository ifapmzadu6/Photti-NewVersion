//
//  PWPhotoMediaContentObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PWPhotoMediaObject;

@interface PWPhotoMediaContentObject : NSManagedObject

@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * medium;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) PWPhotoMediaObject *media;

@end
