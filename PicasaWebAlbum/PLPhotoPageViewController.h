//
//  PLPhotoPageViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PLPhotoPageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

- (id)initWithPhotos:(NSArray *)photos index:(NSUInteger)index;

@end
