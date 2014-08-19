//
//  PWPhotoPageViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PWPhotoPageViewController : UIPageViewController

- (id)initWithPhotos:(NSArray *)photos index:(NSUInteger)index placeholder:(id)placeholder cache:(NSCache *)cache;

- (void)changePhotos:(NSArray *)photos;

@end
