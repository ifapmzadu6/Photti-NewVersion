//
//  PDLocalToWebAlbumTaskObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;
#import "PDBaseTaskObject.h"


@interface PDLocalToWebAlbumTaskObject : PDBaseTaskObject

@property (nonatomic, retain) NSString * album_object_id_str;
@property (nonatomic, retain) NSNumber * is_auto_upload;
@property (nonatomic, retain) NSString * destination_album_id_str;

@end
