//
//  PDCopyPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;
#import "PDBasePhotoObject.h"


@interface PDCopyPhotoObject : PDBasePhotoObject

@property (nonatomic, retain) NSString * photo_object_id_str;
@property (nonatomic, retain) NSString * downloaded_data_location;

@end
