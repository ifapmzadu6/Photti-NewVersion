//
//  PWImagePickerLocalAlbumListViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PWImagePickerLocalAlbumListViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) void (^viewDidAppearBlock)();

@end
