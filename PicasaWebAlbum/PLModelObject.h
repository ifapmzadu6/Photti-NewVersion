//
//  PLModelObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#ifndef PicasaWebAlbum_PLModelObject_h
#define PicasaWebAlbum_PLModelObject_h

static NSString * const kPLAlbumObjectName = @"PLAlbumObject";
static NSString * const kPLPhotoObjectName = @"PLPhotoObject";
typedef enum _PLAlbumObjectTagType {
    PLAlbumObjectTagTypeImported = (1 << 0),
    PLAlbumObjectTagTypeAutomatically = (1 << 1)
} PLAlbumObjectTagType;

#import "PLAlbumObject.h"
#import "PLPhotoObject.h"

#endif
