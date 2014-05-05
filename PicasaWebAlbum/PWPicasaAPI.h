//
//  PWPicasaAPI.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWPicasaAPI : NSObject

// Requesting a list of albums
+ (void)getListOfAlbumsWithCompletionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (void)getTestAccessURL:(NSString *)urlString completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end
