//
//  PDLocalPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PDBasePhotoObject.h"


@interface PDLocalPhotoObject : PDBasePhotoObject

@property (nonatomic, retain) NSString * photo_object_id_str;
@property (nonatomic, retain) NSString * prepared_body_filepath;

@end
