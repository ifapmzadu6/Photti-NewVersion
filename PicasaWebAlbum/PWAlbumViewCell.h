//
//  PWAlbumViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PWPicasaAPI.h"

@interface PWAlbumViewCell : UICollectionViewCell

@property (copy, nonatomic) void (^actionButtonActionBlock)(PWAlbumObject *album);

@property (strong, nonatomic, readonly) PWAlbumObject *album;
@property (nonatomic) BOOL isDisableActionButton;

- (void)setAlbum:(PWAlbumObject *)album isNowLoading:(BOOL)isNowLoading;

@end
