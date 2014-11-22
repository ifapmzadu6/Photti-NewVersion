//
//  PLPhotoViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PLPhotoObject;

@interface PLPhotoViewCell : UICollectionViewCell

@property (strong, nonatomic, readonly) UIImageView *imageView;

@property (strong, nonatomic) PLPhotoObject *photo;
@property (nonatomic) BOOL isSelectWithCheckMark;

- (void)initialization;

@end
