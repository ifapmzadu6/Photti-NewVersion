//
//  PWHorizontalScrollHeaderView.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWHorizontalScrollHeaderView.h"

#import "PAColors.h"
#import "PAHorizontalScrollView.h"
#import "PWPhotoViewCell.h"

@interface PWHorizontalScrollHeaderView ()

@property (strong, nonatomic) UIView *bottomLineView;
@property (strong, nonatomic) UILabel *bottomTitleLabel;

@end

@implementation PWHorizontalScrollHeaderView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:16.0f];
    _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    [self addSubview:_titleLabel];
    
    _moreButton = [UIButton new];
    [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _moreButton.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [_moreButton setTitle:NSLocalizedString(@"See All", nil) forState:UIControlStateNormal];
    [_moreButton setTitleColor:[PAColors getColor:PAColorsTypeTextLightSubColor] forState:UIControlStateNormal];
    _moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    _moreButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 10.0f);
    [self addSubview:_moreButton];
    
    _greaterThanImageView = [UIImageView new];
    _greaterThanImageView.image = [[UIImage imageNamed:@"GreaterThan"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _greaterThanImageView.tintColor = [PAColors getColor:PAColorsTypeTextLightSubColor];
    _greaterThanImageView.frame = CGRectMake(0.0f, 0.0f, 8.0f, 10.0f);
    [self addSubview:_greaterThanImageView];
    
    _horizontalScrollView = [PAHorizontalScrollView new];
    [_horizontalScrollView.collectionView registerClass:PWPhotoViewCell.class forCellWithReuseIdentifier:NSStringFromClass(PWPhotoViewCell.class)];
    _horizontalScrollView.collectionView.contentInset = UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 0.0f);
    [self addSubview:_horizontalScrollView];
    
    _bottomLineView = [UIView new];
    _bottomLineView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    [self addSubview:_bottomLineView];
    
    _bottomTitleLabel = [UILabel new];
    _bottomTitleLabel.font = [UIFont systemFontOfSize:16.0f];
    _bottomTitleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    [self addSubview:_bottomTitleLabel];
    
    _titleLabel.text = NSLocalizedString(@"Recently Uploaded", nil);
    _bottomTitleLabel.text = NSLocalizedString(@"Albums", nil);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    _titleLabel.frame = CGRectMake(0.0f, 20.0f, 200.0f, 20.0f);
    [_moreButton sizeToFit];
    CGFloat moreButtonWidth = CGRectGetWidth(_moreButton.bounds) + 50.0f;
    _moreButton.frame = CGRectMake(CGRectGetWidth(rect) - moreButtonWidth, 17.0f, moreButtonWidth, 26.0f);
    _greaterThanImageView.frame = CGRectMake(CGRectGetMaxX(_moreButton.frame)-CGRectGetWidth(_greaterThanImageView.frame), CGRectGetMinY(_moreButton.frame)+(CGRectGetHeight(_moreButton.frame)-CGRectGetHeight(_greaterThanImageView.frame))/2.0f, CGRectGetWidth(_greaterThanImageView.frame), CGRectGetHeight(_greaterThanImageView.frame));
    _horizontalScrollView.frame = CGRectMake(-15.0f, 44.0f, CGRectGetWidth(rect)+15.0f*2.0f, CGRectGetHeight(rect) - 100.0f);
    _bottomLineView.frame = CGRectMake(0.0f, CGRectGetHeight(rect)-46.0f, CGRectGetWidth(rect)+15.0f, 0.5f);
    _bottomTitleLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect)-30.0f, 200.0f, 20.0f);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if(self.hidden) {
        return [super pointInside:point withEvent:event];
    }
    
    CGRect hitFrame = _horizontalScrollView.frame;
    
    return CGRectContainsPoint(hitFrame, point);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    UIEdgeInsets contentInsets = _horizontalScrollView.collectionView.contentInset;
    _horizontalScrollView.collectionView.contentOffset = CGPointMake(-contentInsets.left, 0.0f);
}

- (void)moreButtonAction {
    if (_moreButtonActionBlock) {
        _moreButtonActionBlock();
    }
}

@end
