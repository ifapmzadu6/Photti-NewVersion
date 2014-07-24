//
//  PDBasePhotoObject+methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDBasePhotoObject.h"

@interface PDBasePhotoObject (methods)

- (NSURLSessionTask *)makeSessionTaskWithSession:(NSURLSession *)session;

@end
