//
//  PDBasePhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PDBaseTaskObject;

@interface PDBasePhotoObject : NSManagedObject

@property (nonatomic, retain) PDBaseTaskObject *task;

@end
