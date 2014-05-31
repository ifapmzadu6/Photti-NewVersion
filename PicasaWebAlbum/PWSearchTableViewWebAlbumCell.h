//
//  PWSearchTableViewWebAlbumCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PWAlbumObject;

@interface PWSearchTableViewWebAlbumCell : UITableViewCell

@property (strong, nonatomic, readonly) PWAlbumObject *album;

- (void)setAlbum:(PWAlbumObject *)album isNowLoading:(BOOL)isNowLoading;

@end
