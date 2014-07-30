//
//  PDLocalPhotoObject+methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDLocalPhotoObject.h"

@interface PDLocalPhotoObject (methods)

- (void)setUploadTaskToWebAlbumID:(NSString *)webAlbumID completion:(void(^)(NSError *error))completion;
- (void)finishMakeNewAlbumSessionWithResponse:(NSURLResponse *)response data:(NSData *)data;

@end
