//
//  PWPhotoObject+Methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/12.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoObject.h"

@interface PWPhotoObject (Methods)

+ (PWPhotoObject *)getPhotoObjectWithID:(NSString *)id_str;

+ (void)getCountFromPhotoObjects:(NSArray *)photos completion:(void (^)(NSUInteger countOfPhoto, NSUInteger countOfVideo))completion;

@end
