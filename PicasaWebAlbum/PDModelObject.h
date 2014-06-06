//
//  PDModelObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#ifndef PicasaWebAlbum_PDModelObject_h
#define PicasaWebAlbum_PDModelObject_h

static NSString * const kPDBaseTaskObjectName = @"PDBaseTaskObject";
static NSString * const kPDLocalToWebAlbumTaskObjectName = @"PDLocalToWebAlbumTaskObject";
static NSString * const kPDLocalToWebPhotosTaskObjectName = @"PDLocalToWebPhotosTaskObject";
static NSString * const kPDWebToLocalPhotosTaskObjectName = @"PDWebToLocalPhotosTaskObject";
static NSString * const kPDWebToLocalAlbumTaskObjectName = @"PDWebToLocalAlbumTaskObject";

static NSString * const kPDBasePhotoObjectName = @"PDBasePhotoObject";
static NSString * const kPDWebPhotoObjectName = @"PDWebPhotoObject";
static NSString * const kPDLocalPhotoObjectName = @"PDLocalPhotoObject";


#import "PDBaseTaskObject.h"
#import "PDLocalToWebAlbumTaskObject.h"
#import "PDLocalToWebPhotosTaskObject.h"
#import "PDWebToLocalPhotosTaskObject.h"
#import "PDWebToLocalAlbumTaskObject.h"

#import "PDBasePhotoObject.h"
#import "PDWebPhotoObject.h"
#import "PDLocalPhotoObject.h"

#endif
