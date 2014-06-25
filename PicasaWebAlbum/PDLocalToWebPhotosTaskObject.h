//
//  PDLocalToWebPhotosTaskObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;
#import "PDBaseTaskObject.h"


@interface PDLocalToWebPhotosTaskObject : PDBaseTaskObject

@property (nonatomic, retain) NSString * destination_album_id_str;

@end
