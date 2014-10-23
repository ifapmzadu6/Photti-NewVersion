//
//  PHAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEAlbumViewCell.h"

#import "PAColors.h"

@interface PEAlbumViewCell ()

@property (nonatomic) UIView *overrayView;
@property (strong, nonatomic) UIImageView *checkMarkImageView;
@property (strong, nonatomic) UIImageView *checkMarkBackgroundImageView;
@property (nonatomic) CGRect rect;

@end

@implementation PEAlbumViewCell

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
    _thirdImageView = [UIImageView new];
    _thirdImageView.contentMode = UIViewContentModeScaleAspectFill;
    _thirdImageView.clipsToBounds = YES;
    _thirdImageView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
    _thirdImageView.layer.borderWidth = 1.0f;
    [self.contentView addSubview:_thirdImageView];
    
    _secondImageView = [UIImageView new];
    _secondImageView.contentMode = UIViewContentModeScaleAspectFill;
    _secondImageView.clipsToBounds = YES;
    _secondImageView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
    _secondImageView.layer.borderWidth = 1.0f;
    [self.contentView addSubview:_secondImageView];
    
    _firstImageView = [UIImageView new];
    _firstImageView.contentMode = UIViewContentModeScaleAspectFill;
    _firstImageView.clipsToBounds = YES;
    _firstImageView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
    _firstImageView.layer.borderWidth = 1.0f;
    [self.contentView addSubview:_firstImageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:12.0f];
    _titleLabel.textColor = [PAColors getColor:kPAColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _detailLabel = [UILabel new];
    _detailLabel.font = [UIFont systemFontOfSize:10.0f];
    _detailLabel.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
    [self.contentView addSubview:_detailLabel];
    
    _overrayView = [UIView new];
    _overrayView.backgroundColor = self.backgroundColor;
    _overrayView.alpha = 0.0f;
    [self.contentView addSubview:_overrayView];
    
    _checkMarkImageView = [UIImageView new];
    _checkMarkImageView.image = [[UIImage imageNamed:@"CheckMark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _checkMarkImageView.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
    _checkMarkImageView.alpha = 0.0f;
    [self.contentView addSubview:_checkMarkImageView];
    
    _checkMarkBackgroundImageView = [UIImageView new];
    _checkMarkBackgroundImageView.image = [UIImage imageNamed:@"CheckMarkBackground"];
    _checkMarkBackgroundImageView.alpha = 0.0f;
    [self.contentView insertSubview:_checkMarkBackgroundImageView belowSubview:_checkMarkImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    if (CGRectEqualToRect(_rect, rect)) {
        return;
    }
    CGFloat delta = 4.0f;
    CGFloat imageSize = CGRectGetWidth(rect)-delta*2.0f;
    
    _firstImageView.frame = CGRectMake(0.0f, delta*2.0f, imageSize, imageSize);
    _secondImageView.frame = CGRectMake(delta, delta, imageSize, imageSize);
    _thirdImageView.frame = CGRectMake(delta*2.0f, 0.0f, imageSize, imageSize);
    
    _titleLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 26.0f, CGRectGetWidth(rect), 14.0f);
    _detailLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 12.0f, CGRectGetWidth(rect), 12.0f);
    
    _overrayView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(rect), CGRectGetMaxY(_firstImageView.frame));
    _checkMarkImageView.frame = CGRectMake(CGRectGetMaxX(_firstImageView.frame) - 32.0f, CGRectGetMaxY(_firstImageView.frame) - 32.0f, 25.0f, 25.0f);
    _checkMarkBackgroundImageView.frame = _checkMarkImageView.frame;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.tag = NSIntegerMax;
    
    _firstImageView.image = nil;
    _secondImageView.image = nil;
    _thirdImageView.image = nil;
    _titleLabel.text = nil;
    _detailLabel.text = nil;
}

#pragma mark methods
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    _overrayView.alpha = (selected && _isSelectWithCheckmark) ? 0.5f : 0.0f;
    _checkMarkImageView.alpha = (selected && _isSelectWithCheckmark) ? 1.0f : 0.0f;
    _checkMarkBackgroundImageView.alpha = _checkMarkImageView.alpha;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    _overrayView.alpha = (highlighted) ? 0.5f : 0.0f;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    _firstImageView.layer.borderColor = backgroundColor.CGColor;
    _secondImageView.layer.borderColor = backgroundColor.CGColor;
    _thirdImageView.layer.borderColor = backgroundColor.CGColor;
    _overrayView.backgroundColor = backgroundColor;
}

@end
