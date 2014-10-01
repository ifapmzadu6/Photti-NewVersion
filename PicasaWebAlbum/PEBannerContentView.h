//
//  PEBannerContentView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/10/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PEBannerContentView : UIView

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *titleLabel;

@property (copy, nonatomic) void (^touchUpInsideActionBlock)();

@end
