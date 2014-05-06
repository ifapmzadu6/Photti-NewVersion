//
//  PWPicasaAPI.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PWPicasaGETRequest : NSObject

// Requesting a list of albums
+ (void)getListOfAlbumsWithIndex:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

+ (void)getTestAccessURL:(NSString *)urlString completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

@end
