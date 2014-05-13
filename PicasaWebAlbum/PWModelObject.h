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

static NSString * const kPWAlbumManagedObjectName = @"PWAlbumManagedObject";
static NSString * const kPWGPhotoManagedObjectName = @"PWGPhotoManagedObject";
static NSString * const kPWLinkManagedObjectName = @"PWLinkManagedObject";
static NSString * const kPWMediaContentManagedObjectName = @"PWMediaContentManagedObject";
static NSString * const kPWMediaManagedObjectName = @"PWMediaManagedObject";
static NSString * const kPWMediaThumbnailManagedObjectName = @"PWMediaThumbnailManagedObject";
static NSString * const kPWPhotoExitManagedObjectName = @"PWPhotoExitManagedObject";
static NSString * const kPWPhotoManagedObjectName = @"PWPhotoManagedObject";

#endif
