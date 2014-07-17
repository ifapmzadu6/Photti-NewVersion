//
//  PDModelObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#ifndef PicasaWebAlbum_PDModelObject_h
#define PicasaWebAlbum_PDModelObject_h

static NSString * const kPDTaskObjectName = @"PDTaskObject";

static NSString * const kPDBasePhotoObjectName = @"PDBasePhotoObject";
static NSString * const kPDWebPhotoObjectName = @"PDWebPhotoObject";
static NSString * const kPDLocalPhotoObjectName = @"PDLocalPhotoObject";
static NSString * const kPDCopyPhotoObjectName = @"PDCopyPhotoObject";

typedef enum _PDTaskObjectType {
    PDTaskObjectTypeLocalAlbumToWebAlbum,
    PDTaskObjectTypeWebAlbumToLocalAlbum,
    PDTaskObjectTypePhotosToLocalAlbum,
    PDTaskObjectTypePhotosToWebAlbum
} PDTaskObjectType;


#import "PDTaskObject.h"
#import "PDTaskObject+methods.h"


#import "PDBasePhotoObject.h"
#import "PDWebPhotoObject.h"
#import "PDLocalPhotoObject.h"
#import "PDCopyPhotoObject.h"
#import "PDLocalPhotoObject+methods.h"
#import "PDWebPhotoObject+methods.h"

#endif
