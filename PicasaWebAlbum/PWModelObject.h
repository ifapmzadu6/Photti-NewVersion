//
//  PWModelObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

#ifndef PicasaWebAlbum_PWModelObject_h
#define PicasaWebAlbum_PWModelObject_h

#import "PWAlbumObject.h"
#import "PWGPhotoObject.h"
#import "PWPhotoMediaContentObject.h"
#import "PWPhotoLinkObject.h"
#import "PWPhotoMediaObject.h"
#import "PWPhotoObject.h"
#import "PWPhotoExitObject.h"
#import "PWPhotoMediaThumbnailObject.h"

#import "PWAlbumObject+Methods.h"
#import "PWPhotoObject+Methods.h"

static NSString * const kPWAlbumObjectName = @"PWAlbumManagedObject";
static NSString * const kPWGPhotoObjectName = @"PWGPhotoManagedObject";
static NSString * const kPWLinkObjectName = @"PWLinkManagedObject";
static NSString * const kPWMediaContentObjectName = @"PWMediaContentManagedObject";
static NSString * const kPWMediaObjectName = @"PWMediaManagedObject";
static NSString * const kPWMediaThumbnailObjectName = @"PWMediaThumbnailManagedObject";
static NSString * const kPWPhotoExitObjectName = @"PWPhotoExitManagedObject";
static NSString * const kPWPhotoObjectName = @"PWPhotoManagedObject";

typedef NS_ENUM(NSUInteger, kPWPhotoObjectType) {
    kPWPhotoObjectTypeUnknown,
    kPWPhotoObjectTypePhoto,
    kPWPhotoObjectTypeVideo
};

static NSString * const kPWPhotoObjectContentType_mp4 = @"video/mp4";
static NSString * const kPWPhotoObjectContentType_jpeg = @"image/jpeg";
static NSString * const kPWPhotoObjectContentType_gif = @"image/gif";
static NSString * const kPWPhotoObjectContentType_png = @"image/png";

#endif
