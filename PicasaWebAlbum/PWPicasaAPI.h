//
//  PWPicasaAPI.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

#import "PWModelObject.h"
#import "PWOAuthManager.h"
#import "PWCoreDataAPI.h"

@interface PWPicasaAPI : NSObject

+ (void)getListOfAlbumsWithIndex:(NSUInteger)index completion:(void (^)(NSArray *albums, NSUInteger nextIndex, NSError *error))completion;

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSArray *photos, NSUInteger nextIndex, NSError *error))completion;

+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completion:(void (^)(PWPhotoObject *photo, NSError *error))completion;



@end
