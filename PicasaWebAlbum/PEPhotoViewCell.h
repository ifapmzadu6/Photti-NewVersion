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

@property (nonatomic) BOOL isSelectWithCheckmark;

@end
