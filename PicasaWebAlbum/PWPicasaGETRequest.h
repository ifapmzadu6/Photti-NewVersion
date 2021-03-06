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

// Requesting a list of photos
+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

// Requesting a list of photos that is recently uploaded
+ (void)getListOfRecentlyUploadedPhotosWithCompletion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

// Requesting a photo
+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

// Requesting a test URL
+ (void)getTestAccessURL:(NSString *)urlString completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

// Authorize
+ (void)getAuthorizedURLRequest:(NSURL *)url completion:(void (^)(NSMutableURLRequest *, NSError *))completion;

// Authorize + Requesting
+ (void)authorizedGETRequestWithURL:(NSURL *)url completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion;
@end
