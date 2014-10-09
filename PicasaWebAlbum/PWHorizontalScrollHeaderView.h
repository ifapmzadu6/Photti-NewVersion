//
//  PWHorizontalScrollHeaderView.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PAHorizontalScrollView;

@interface PWHorizontalScrollHeaderView : UICollectionReusableView

@property (copy, nonatomic) void (^moreButtonActionBlock)();

@property (strong, nonatomic, readonly) UILabel *titleLabel;
@property (strong, nonatomic, readonly) UIButton *moreButton;
@property (strong, nonatomic) UIImageView *greaterThanImageView;
@property (strong, nonatomic, readonly) PAHorizontalScrollView *horizontalScrollView;

@end
