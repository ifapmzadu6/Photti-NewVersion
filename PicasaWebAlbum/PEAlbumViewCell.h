//
//  PHAlbumViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PEAlbumViewCell : UICollectionViewCell

@property (strong, nonatomic, readonly) UIImageView *firstImageView;
@property (strong, nonatomic, readonly) UIImageView *secondImageView;
@property (strong, nonatomic, readonly) UIImageView *thirdImageView;

@property (strong, nonatomic, readonly) UILabel *titleLabel;
@property (strong, nonatomic, readonly) UILabel *detailLabel;

@property (nonatomic) BOOL isSelectWithCheckmark;

@end
