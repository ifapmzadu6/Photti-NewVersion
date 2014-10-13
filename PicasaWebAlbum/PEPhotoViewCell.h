//
//  PHPhotoViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PEPhotoViewCell : UICollectionViewCell

@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic, readonly) UIImageView *favoriteIconView;
@property (strong, nonatomic, readonly) UIImageView *videoBackgroundView;
@property (strong, nonatomic, readonly) UIImageView *videoIconView;
@property (strong, nonatomic, readonly) UIImageView *videoTimelapseIconView;

@property (strong, nonatomic, readonly) UILabel *videoDurationLabel;

@property (nonatomic) BOOL isSelectWithCheckmark;

@end
