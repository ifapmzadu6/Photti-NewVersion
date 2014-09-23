//
//  PHCollectionViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHCollectionViewCell.h"

#import "PAColors.h"

static NSUInteger kPHCollectionViewCellMaxNumberOfImageViews = 9;

@interface PHCollectionViewCell ()

@property (strong, nonatomic) UIView *imageViewBackgroundView;

@end

@implementation PHCollectionViewCell

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
    _imageViewBackgroundView = [UIView new];
    _imageViewBackgroundView.backgroundColor = [UIColor blackColor];
    [self.contentView addSubview:_imageViewBackgroundView];
    
    NSMutableArray *imageViews = @[].mutableCopy;
    for (int i=0; i<kPHCollectionViewCellMaxNumberOfImageViews; i++) {
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.hidden = YES;
        [imageViews addObject:imageView];
        [self.contentView addSubview:imageView];
    }
    _imageViews = imageViews;
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:12.0f];
    _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _detailLabel = [UILabel new];
    _detailLabel.font = [UIFont systemFontOfSize:10.0f];
    _detailLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    [self.contentView addSubview:_detailLabel];
    
    // TODO : remove
    _titleLabel.text = @"トルコ旅行";
    _detailLabel.text = @"51枚の写真";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    NSUInteger numberOfRowAndCol = sqrtf(_numberOfImageView);
    CGFloat imageSize = ceilf((CGRectGetWidth(rect)-2)/numberOfRowAndCol*2.0f+0.5f)/2.0f;
    
    for (int i=0; i<numberOfRowAndCol; i++) {
        for (int j=0; j<numberOfRowAndCol; j++) {
            if (i*numberOfRowAndCol+j < _numberOfImageView) {
                UIImageView *imageView = _imageViews[i*numberOfRowAndCol+j];
                imageView.frame = CGRectMake(imageSize*i +1.0f, imageSize*j +1.0f, imageSize, imageSize);
                imageView.hidden = NO;
            }
        }
    }
    
    _imageViewBackgroundView.frame = CGRectMake(0.5f, 0.5f, imageSize*numberOfRowAndCol+1.0f, imageSize*numberOfRowAndCol+1.0f);
    
    _titleLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 26.0f, CGRectGetWidth(rect), 14.0f);
    _detailLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 12.0f, CGRectGetWidth(rect), 12.0f);
}

- (void)setNumberOfImageView:(NSUInteger)numberOfImageView {
    if (numberOfImageView > 9) {
        numberOfImageView = 9;
    }
    _numberOfImageView = numberOfImageView;
    
    for (UIImageView *imageView in _imageViews) {
        imageView.hidden = YES;
    }
    
    [self setNeedsLayout];
}

@end
