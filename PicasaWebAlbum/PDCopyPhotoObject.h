//
//  PDCopyPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;


@interface PDCopyPhotoObject : NSManagedObject

@property (nonatomic, retain) NSString * web_photo_id_str;
@property (nonatomic, retain) NSString * prepared_body_filepath;

@end
