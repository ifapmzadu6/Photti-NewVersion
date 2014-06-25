//
//  PDWebPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;
#import "PDBasePhotoObject.h"


@interface PDWebPhotoObject : PDBasePhotoObject

@property (nonatomic, retain) NSString * photo_object_id_str;

@end
