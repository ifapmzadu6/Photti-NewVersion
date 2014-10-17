//
//  PDLocalPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;
#import "PDBasePhotoObject.h"


@interface PDLocalPhotoObject : PDBasePhotoObject

@property (nonatomic, retain) NSString * prepared_body_filepath;

@end
