//
//  PLAllPhotosViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PLAllPhotosViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (copy, nonatomic) void (^viewDidAppearBlock)();
@property (copy, nonatomic) void (^headerViewDidTapBlock)(BOOL isSelectMode);
@property (copy, nonatomic) void (^photoDidSelectedInSelectModeBlock)(NSArray *photos);


@property (nonatomic, readonly) BOOL isSelectMode;
- (void)setIsSelectMode:(BOOL)isSelectMode withSelectIndexPaths:(NSArray *)selectIndexPaths;

@property (strong, nonatomic) NSMutableArray *selectedPhotos;

@end
