//
//  PWTask.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;


//test
#import "PDModelObject.h"

@class PDBaseTaskObject;

@interface PDTask : NSObject

@property (copy, nonatomic) void (^willProcessBlock)(PDBasePhotoObject *photoObject);
@property (copy, nonatomic) void (^processingBlock)(PDBasePhotoObject *photoObject, int64_t bytesWritten, int64_t totalBytes);
@property (copy, nonatomic) void (^doneProcessBlock)(PDBasePhotoObject *photoObject, NSError *error);

@property (strong, nonatomic) PDBaseTaskObject *taskObject;
@property (strong, nonatomic) PDBasePhotoObject *photoObject;
@property (nonatomic) NSUInteger identifier;

@end
