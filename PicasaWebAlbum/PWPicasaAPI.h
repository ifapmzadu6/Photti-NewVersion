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

static NSString * const kPWPicasaAPIGphotoAccessPrivate = @"private";
static NSString * const kPWPicasaAPIGphotoAccessPublic = @"public";
static NSString * const kPWPicasaAPIGphotoAccessProtected = @"protected";

static NSString * const kPWPicasaAPILinkRelShare = @"alternate";

@interface PWPicasaAPI : NSObject

+ (void)getListOfAlbumsWithIndex:(NSUInteger)index completion:(void (^)(NSArray *albums, NSUInteger nextIndex, NSError *error))completion;

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSArray *photos, NSUInteger nextIndex, NSError *error))completion;

//+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completion:(void (^)(PWPhotoObject *photo, NSError *error))completion;

+ (void)getAuthorizedURLRequest:(NSURL *)url completion:(void (^)(NSMutableURLRequest *request, NSError *error))completion;

+ (void)authorizedURLRequest:(NSURL *)url completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

+ (void)postCreatingNewAlbumRequestWithTitle:(NSString *)title
                            summary:(NSString *)summary
                           location:(NSString *)location
                             access:(NSString *)access
                          timestamp:(NSString *)timestamp
                           keywords:(NSString *)keywords
                                  completion:(void (^)(PWAlbumObject *album, NSError *error))completion;

+ (void)putModifyingAlbumWithID:(NSString *)albumID
                          title:(NSString *)title
                        summary:(NSString *)summary
                       location:(NSString *)location
                         access:(NSString *)access
                      timestamp:(NSString *)timestamp
                       keywords:(NSString *)keywords
                     completion:(void (^)(NSString *newAccess, NSSet *link, NSError *error))completion;

+ (void)deleteAlbum:(PWAlbumObject *)album completion:(void (^)(NSError *error))completion;


+ (void)deletePhoto:(PWPhotoObject *)photo completion:(void (^)(NSError *error))completion;

@end
