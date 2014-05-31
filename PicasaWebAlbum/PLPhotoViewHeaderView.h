//
//  PLPhotoViewHeaderView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PLPhotoViewHeaderView : UICollectionReusableView

@property (strong, nonatomic) void (^selectButtonActionBlock)();
@property (strong, nonatomic) void (^deselectButtonActionBlock)();

- (void)setText:(NSString *)text;
- (void)setDetail:(NSString *)detail;
- (void)setSelectButtonIsDeselect:(BOOL)isDeselect;

@end
