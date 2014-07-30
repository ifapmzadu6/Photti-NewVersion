//
//  PDCopyPhotoObject+methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDCopyPhotoObject.h"

@interface PDCopyPhotoObject (methods)

- (NSURLSessionTask *)makeSessionTaskWithSession:(NSURLSession *)session;
- (void)finishDownloadWithLocation:(NSURL *)location;
- (void)finishUpload;

@end
