//
//  PDTaskManagerViewControllerHeaderView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskManagerViewControllerHeaderView.h"

#import "PWColors.h"

@interface PDTaskManagerViewControllerHeaderView ()

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@end

@implementation PDTaskManagerViewControllerHeaderView

- (id)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:13.0f];
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    [self addSubview:_titleLabel];
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _indicatorView.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
    [self addSubview:_indicatorView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    CGSize titleLabelSize = [_titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    if (_indicatorView.hidden) {
        _titleLabel.frame = CGRectMake(20.0f, CGRectGetHeight(rect)-titleLabelSize.height-6.0f, CGRectGetWidth(rect), titleLabelSize.height);
    }
    else {
        _titleLabel.frame = CGRectMake(38.0f, CGRectGetHeight(rect)-titleLabelSize.height-6.0f, CGRectGetWidth(rect), titleLabelSize.height);
        _indicatorView.center = CGPointMake(24.0f, _titleLabel.center.y-1.5f);
    }
}

- (void)setText:(NSString *)text {
    _titleLabel.text = text;
}

- (void)indicatorIsEnable:(BOOL)isEnable {
    if (isEnable) {
        [_indicatorView startAnimating];
    }
    else {
        [_indicatorView stopAnimating];
    }
}

@end
