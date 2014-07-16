//
//  PDWebToWebPhotosTask.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/15.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;
#import "PDBaseTaskObject.h"


@interface PDWebToWebPhotosTask : PDBaseTaskObject

@property (nonatomic, retain) NSString * destination_album_id_str;

@end
