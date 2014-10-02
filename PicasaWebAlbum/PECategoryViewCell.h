//
//  PALeftCollectionViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PEHorizontalScrollView;

@interface PECategoryViewCell : UITableViewCell

@property (copy, nonatomic) void (^moreButtonActionBlock)();

@property (strong, nonatomic, readonly) UILabel *titleLabel;
@property (strong, nonatomic, readonly) UIButton *moreButton;
@property (strong, nonatomic, readonly) PEHorizontalScrollView *horizontalScrollView;

@end
