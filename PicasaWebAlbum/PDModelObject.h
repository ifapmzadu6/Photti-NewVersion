//
//  PDModelObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#ifndef PicasaWebAlbum_PDModelObject_h
#define PicasaWebAlbum_PDModelObject_h

typedef NS_ENUM(NSUInteger, PDTaskObjectType) {
    PDTaskObjectTypeLocalAlbumToWebAlbum,
    PDTaskObjectTypeWebAlbumToLocalAlbum,
    PDTaskObjectTypePhotosToLocalAlbum,
    PDTaskObjectTypePhotosToWebAlbum
};


static NSString * const kPDTaskObjectName = @"PDTaskObject";
static NSString * const kPDBasePhotoObjectName = @"PDBasePhotoObject";
static NSString * const kPDWebPhotoObjectName = @"PDWebPhotoObject";
static NSString * const kPDLocalPhotoObjectName = @"PDLocalPhotoObject";
static NSString * const kPDCopyPhotoObjectName = @"PDCopyPhotoObject";
static NSString * const kPDLocalCopyPhotoObjectName = @"PDLocalCopyPhotoObject";

#import "PDTaskObject.h"
#import "PDTaskObjectFactoryMethods.h"

#import "PDBasePhotoObject.h"
#import "PDWebPhotoObject.h"
#import "PDLocalPhotoObject.h"
#import "PDCopyPhotoObject.h"
#import "PDLocalCopyPhotoObject.h"

#import "PDBasePhotoObject+methods.h"
#import "PDLocalPhotoObject+methods.h"
#import "PDWebPhotoObject+methods.h"
#import "PDCopyPhotoObject+methods.h"
#import "PDLocalCopyPhotoObject+methods.h"

#endif
