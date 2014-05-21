//
//  PLAlbumViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PLAlbumObject;

@interface PLAlbumViewCell : UICollectionViewCell

@property (strong, nonatomic) void (^actionButtonActionBlock)(PLAlbumObject *album);

@property (strong, nonatomic) PLAlbumObject *album;

@end
