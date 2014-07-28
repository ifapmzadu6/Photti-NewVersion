//
//  PWSearchTableViewLocalAlbumCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PLAlbumObject;

@interface PWSearchTableViewLocalAlbumCell : UITableViewCell

@property (strong, nonatomic, readonly) PLAlbumObject *album;
@property (nonatomic) BOOL isShowAlbumType;

- (void)setAlbum:(PLAlbumObject *)album searchedText:(NSString *)seatchedText;

@end
