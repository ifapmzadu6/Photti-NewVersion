//
//  PLPhotoViewHeaderView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PLPhotoViewHeaderView : UICollectionReusableView

@property (copy, nonatomic) void (^selectButtonActionBlock)();
@property (copy, nonatomic) void (^deselectButtonActionBlock)();

- (void)setText:(NSString *)text;
- (void)setDetail:(NSString *)detail;
- (void)setSelectButtonIsDeselect:(BOOL)isDeselect;

@end
