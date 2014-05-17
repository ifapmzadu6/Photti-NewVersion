//
//  PWPicasaPOSTRequest.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

#import "PWModelObject.h"

@interface PWPicasaPOSTRequest : NSObject

+ (void)postCreatingNewAlbumRequestWithTitle:(NSString *)title
                            summary:(NSString *)summary
                           location:(NSString *)location
                             access:(NSString *)access
                          timestamp:(NSString *)timestamp
                           keywords:(NSString *)keywords
                         completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

+ (void)putModifyingAlbumWithID:(NSString *)albumID
                          title:(NSString *)title
                        summary:(NSString *)summary
                       location:(NSString *)location
                         access:(NSString *)access
                      timestamp:(NSString *)timestamp
                       keywords:(NSString *)keywords
                     completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

+ (void)deleteAlbumWithID:(NSString *)albumID completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

@end
