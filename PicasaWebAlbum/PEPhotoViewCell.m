//
//  PHPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoViewCell.h"

@interface PEPhotoViewCell ()

@property (nonatomic) UIView *overrayView;
@property (strong, nonatomic) UIImageView *checkMarkImageView;

@end

@implementation PEPhotoViewCell

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
    _imageView = [UIImageView new];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    [self.contentView addSubview:_imageView];
    
    _overrayView = [UIView new];
    _overrayView.backgroundColor = self.backgroundColor;
    _overrayView.alpha = 0.0f;
    [self.contentView addSubview:_overrayView];
    
    _checkMarkImageView = [UIImageView new];
    _checkMarkImageView.image = [UIImage imageNamed:@"CheckMark"];
    _checkMarkImageView.alpha = 0.0f;
    [self.contentView addSubview:_checkMarkImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _imageView.frame = rect;
    _overrayView.frame = rect;
    _checkMarkImageView.frame = CGRectMake(CGRectGetMaxX(_imageView.frame) - 32.0f, CGRectGetMaxY(_imageView.frame) - 32.0f, 28.0f, 28.0f);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _imageView.image = nil;
}

#pragma mark methods
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    _overrayView.alpha = (selected && _isSelectWithCheckmark) ? 0.5f : 0.0f;
    _checkMarkImageView.alpha = (selected && _isSelectWithCheckmark) ? 1.0f : 0.0f;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    _overrayView.alpha = (highlighted) ? 0.5f : 0.0f;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    _overrayView.backgroundColor = backgroundColor;
}

@end
