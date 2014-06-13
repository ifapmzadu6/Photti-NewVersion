//
//  PDWebToLocalAlbumTaskObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PDBaseTaskObject.h"


@interface PDWebToLocalAlbumTaskObject : PDBaseTaskObject

@property (nonatomic, retain) NSString * album_object_id_str;
@property (nonatomic, retain) NSString * destination_album_object_id_str;
@property (nonatomic, retain) NSString * resume_data_url;

@end
