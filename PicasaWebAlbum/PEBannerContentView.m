//
//  PEBannerContentView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/10/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEBannerContentView.h"

@interface PEBannerContentView ()

@property (strong, nonatomic) UIButton *overrayButton;

@end

@implementation PEBannerContentView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _imageView = [UIImageView new];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        
        _gradientView = [PAGradientView new];
        _gradientView.startColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
        _gradientView.endColor = [UIColor clearColor];
        [self addSubview:_gradientView];
        
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont systemFontOfSize:40.0f];
        _titleLabel.textColor = [UIColor whiteColor];
        [self addSubview:_titleLabel];
        
        _overrayButton = [UIButton new];
        [_overrayButton addTarget:self action:@selector(overrayButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_overrayButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    _imageView.frame = rect;
    _overrayButton.frame = rect;
    _gradientView.frame = CGRectMake(_gradientViewInsets.left, _gradientViewInsets.top, CGRectGetWidth(rect) - _gradientViewInsets.left - _gradientViewInsets.right, CGRectGetHeight(rect) - _gradientViewInsets.top - _gradientViewInsets.bottom);
    _titleLabel.frame = CGRectMake(16.0f, 4.0f, CGRectGetWidth(rect) - 16.0f*2.0f, 50.0f);
}

- (void)overrayButtonAction:(id)sender {
    if (_touchUpInsideActionBlock) {
        _touchUpInsideActionBlock();
    }
}

@end
