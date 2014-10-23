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

typedef enum _kPLAlbumObjectTagType {
    kPLAlbumObjectTagTypeImported = (1 << 0),
    kPLAlbumObjectTagTypeAutomatically = (1 << 1),
    kPLAlbumObjectTagTypeMyself = (1 << 2)
} kPLAlbumObjectTagType;

typedef enum _kPLAlbumObjectTagUploadingType {
    kPLAlbumObjectTagUploadingTypeUnknown = 0,
    kPLAlbumObjectTagUploadingTypeYES,
    kPLAlbumObjectTagUploadingTypeNO
} kPLAlbumObjectTagUploadingType;

#import "PLAlbumObject.h"
#import "PLPhotoObject.h"

#import "PLAlbumObject+methods.h"
#import "PLPhotoObject+methods.h"

#endif
