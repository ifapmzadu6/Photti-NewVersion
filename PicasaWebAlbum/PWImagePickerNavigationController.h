//
//  PWImagePickerNabigationController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseNavigationController.h"

@interface PWImagePickerNavigationController : PABaseNavigationController

@property (strong, nonatomic) NSString *titleOnNavigationBar;

- (void)setSelectedPhotosThumbnailImage:(UIImage *)image;
- (void)setSelectedPhotosSubThumbnailImage:(UIImage *)image;
- (void)setSelectedPhotosCount:(NSUInteger)count;

@end
