//
//  PHCollectionViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHMomentViewCell.h"

#import "PAColors.h"

static NSUInteger kPHCollectionViewCellMaxNumberOfImageViews = 4;

@interface PHMomentViewCell ()

@property (strong, nonatomic) UIView *imageViewBackgroundView;
@property (nonatomic) CGRect rect;

@end

@implementation PHMomentViewCell

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
    _imageViewBackgroundView.backgroundColor = [PAColors getColor:PAColorsTypeTextColor];
    _imageViewBackgroundView.opaque = YES;
    [self.contentView addSubview:_imageViewBackgroundView];
    
    NSMutableArray *imageViews = @[].mutableCopy;
    for (int i=0; i<kPHCollectionViewCellMaxNumberOfImageViews; i++) {
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.hidden = YES;
        imageView.opaque = YES;
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
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    if (CGRectEqualToRect(_rect, rect)) {
        return;
    }
    
    NSUInteger numberOfRowAndCol = sqrtf(self.numberOfImageView);
    if (numberOfRowAndCol > 0) {
        CGFloat imageSize = ceilf((CGRectGetWidth(rect)-2)/numberOfRowAndCol*2.0f+0.5f)/2.0f;
        
        for (int i=0; i<numberOfRowAndCol; i++) {
            for (int j=0; j<numberOfRowAndCol; j++) {
                if (i*numberOfRowAndCol+j < _numberOfImageView) {
                    UIImageView *imageView = _imageViews[i*numberOfRowAndCol+j];
                    imageView.frame = CGRectMake(imageSize*i+1.0f, imageSize*j +1.0f, imageSize, imageSize);
                    imageView.hidden = NO;
                }
            }
        }
        
        _imageViewBackgroundView.frame = CGRectMake(0.5f, 0.5f, imageSize*numberOfRowAndCol+1.0f, imageSize*numberOfRowAndCol+1.0f);
    }
    
    _titleLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 26.0f, CGRectGetWidth(rect), 14.0f);
    _detailLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 12.0f, CGRectGetWidth(rect), 12.0f);
}

- (void)setNumberOfImageView:(NSUInteger)numberOfImageView {
    if (numberOfImageView > kPHCollectionViewCellMaxNumberOfImageViews) {
        numberOfImageView = kPHCollectionViewCellMaxNumberOfImageViews;
    }
    _numberOfImageView = numberOfImageView;
    
    for (UIImageView *imageView in _imageViews) {
        imageView.hidden = YES;
    }
    
    [self setNeedsLayout];
}

@end
