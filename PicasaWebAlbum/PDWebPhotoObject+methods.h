//
//  PDWebPhotoObject+methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDWebPhotoObject.h"

@interface PDWebPhotoObject (methods)

- (void)finishDownloadWithData:(NSData *)data completion:(void (^)(NSError *error))completion;

@end
