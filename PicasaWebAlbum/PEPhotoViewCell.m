//
//  PHPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoViewCell.h"

#import "PAColors.h"
#import "PAIcons.h"

@interface PEPhotoViewCell ()

@property (nonatomic) UIView *overrayView;
@property (strong, nonatomic) UIImageView *checkMarkImageView;
@property (strong, nonatomic) UIImageView *checkMarkBackgroundImageView;

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
    
    _videoBackgroundView = [UIImageView new];
    _videoBackgroundView.image = [PAIcons gradientVerticalFromColor:UIColor.clearColor toColor:UIColor.blackColor size:CGSizeMake(1.0f, 40.0f)];
    _videoBackgroundView.hidden = YES;
    [self.contentView addSubview:_videoBackgroundView];
    
    _videoIconView = [UIImageView new];
    _videoIconView.image = [PAIcons videoIconWithColor:[UIColor whiteColor] size:CGSizeMake(94.0f, 50.0f)];
    _videoIconView.contentMode = UIViewContentModeScaleAspectFit;
    _videoIconView.hidden = YES;
    [self.contentView addSubview:_videoIconView];
    
    _videoTimelapseIconView = [UIImageView new];
    _videoTimelapseIconView.image = [[UIImage imageNamed:@"Timelapse"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _videoTimelapseIconView.tintColor = [UIColor whiteColor];
    _videoTimelapseIconView.hidden = YES;
    [self.contentView addSubview:_videoTimelapseIconView];
    
    _videoDurationLabel = [UILabel new];
    _videoDurationLabel.font = [UIFont systemFontOfSize:12.0f];
    _videoDurationLabel.textColor = [UIColor whiteColor];
    _videoDurationLabel.textAlignment = NSTextAlignmentRight;
    _videoDurationLabel.hidden = YES;
    [self.contentView addSubview:_videoDurationLabel];
    
    _favoriteIconView = [UIImageView new];
    _favoriteIconView.image = [[UIImage imageNamed:@"FavoriteMini"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _favoriteIconView.tintColor = [UIColor colorWithRed:240.0f/255.0f green:90.0f/255.0f blue:80.0f/255.0f alpha:1.0f];
    [self.contentView addSubview:_favoriteIconView];
    
    _overrayView = [UIView new];
    _overrayView.backgroundColor = self.backgroundColor;
    _overrayView.alpha = 0.0f;
    [self.contentView addSubview:_overrayView];
    
    _checkMarkImageView = [UIImageView new];
    _checkMarkImageView.image = [[UIImage imageNamed:@"CheckMark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _checkMarkImageView.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
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
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _imageView.frame = rect;
    }
    else {
        CGSize imageSize = _imageView.image.size;
        CGFloat width = imageSize.width;
        CGFloat height = imageSize.height;
        if (width > 0 && height > 0) {
            if (width > height) {
                height = ceilf(rect.size.width * height/width * 2.0f + 0.5f) / 2.0f;
                _imageView.frame = CGRectMake(0.0f, ceilf((rect.size.height-height) + 0.5f)/2.0f, rect.size.width, height);
            }
            else {
                width = ceilf(rect.size.width * width/height * 2.0f + 0.5f) / 2.0f;
                _imageView.frame = CGRectMake(ceilf((rect.size.width-width) + 0.5f)/2.0f, 0.0f, width, rect.size.width);
            }
        }
        else {
            _imageView.frame = CGRectZero;
        }
    }
    
    CGRect imageFrame = _imageView.frame;
    _favoriteIconView.frame = CGRectMake(CGRectGetMaxX(imageFrame)-32.0f, CGRectGetMinY(imageFrame)+7.0f, 25.0f, 25.0f);
    
    _videoBackgroundView.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetMaxY(imageFrame)-20.0f, CGRectGetWidth(imageFrame), 20.0f);
    _videoIconView.frame = CGRectMake(CGRectGetMinX(imageFrame)+5.0f, CGRectGetMaxY(imageFrame)-14.0f, 16.0f, 8.0f);
    _videoTimelapseIconView.frame = CGRectMake(CGRectGetMinX(imageFrame)+5.0f, CGRectGetMaxY(imageFrame)-18.0f, 15.0f, 15.0f);
    _videoDurationLabel.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetMaxY(imageFrame) - 20.0f, CGRectGetWidth(imageFrame) - 5.0f, 20.0f);
    
    _overrayView.frame = rect;
    _checkMarkImageView.frame = CGRectMake(CGRectGetMaxX(imageFrame) - 32.0f, CGRectGetMaxY(imageFrame) - 32.0f, 25.0f, 25.0f);
    _checkMarkBackgroundImageView.frame = _checkMarkImageView.frame;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _imageView.image = nil;
    
    _videoBackgroundView.hidden = YES;
    _videoDurationLabel.hidden = YES;
    _videoDurationLabel.text = nil;
    _videoIconView.hidden = YES;
    _videoTimelapseIconView.hidden = YES;
    
    _favoriteIconView.hidden = YES;
    
    _checkMarkImageView.alpha = 0.0f;
    _checkMarkBackgroundImageView.alpha = 0.0f;
}

#pragma mark methods
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    _overrayView.alpha = (selected && _isSelectWithCheckmark) ? 0.5f : 0.0f;
    _checkMarkImageView.alpha = (selected && _isSelectWithCheckmark) ? 1.0f : 0.0f;
    _checkMarkBackgroundImageView.alpha = (selected && _isSelectWithCheckmark) ? 1.0f : 0.0f;
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
