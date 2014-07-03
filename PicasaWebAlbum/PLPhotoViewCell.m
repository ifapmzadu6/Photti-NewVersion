//
//  PLPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import ImageIO;

#import "PLPhotoViewCell.h"

#import "PWIcons.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLDateFormatter.h"

@interface PLPhotoViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImageView *videoBackgroundView;
@property (strong, nonatomic) UIImageView *videoIconView;
@property (strong, nonatomic) UILabel *videoDurationLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIView *overrayView;
@property (strong, nonatomic) UIImageView *checkMark;

@property (nonatomic) NSUInteger photoHash;

@end

@implementation PLPhotoViewCell

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
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    
    _videoBackgroundView = [[UIImageView alloc] init];
    _videoBackgroundView.image = [PWIcons gradientVerticalFromColor:UIColor.clearColor toColor:UIColor.blackColor size:CGSizeMake(200.0f, 200.0f)];
    _videoBackgroundView.hidden = YES;
    [self.contentView addSubview:_videoBackgroundView];
    
    _videoIconView = [[UIImageView alloc] init];
    _videoIconView.image = [PWIcons videoIconWithColor:[UIColor whiteColor] size:CGSizeMake(94.0f, 50.0f)];
    _videoIconView.contentMode = UIViewContentModeScaleAspectFit;
    _videoIconView.hidden = YES;
    [self.contentView addSubview:_videoIconView];
    
    _videoDurationLabel = [[UILabel alloc] init];
    _videoDurationLabel.text = @"5:21";
    _videoDurationLabel.font = [UIFont systemFontOfSize:12.0f];
    _videoDurationLabel.textColor = [UIColor whiteColor];
    _videoDurationLabel.textAlignment = NSTextAlignmentRight;
    _videoDurationLabel.hidden = YES;
    [self.contentView addSubview:_videoDurationLabel];
    
    _overrayView = [[UIView alloc] init];
    _overrayView.alpha = 0.0f;
    [self.contentView addSubview:_overrayView];
    
    _checkMark = [[UIImageView alloc] init];
    _checkMark.image = [UIImage imageNamed:@"CheckMark"];
    _checkMark.alpha = 0.0f;
    [self.contentView addSubview:_checkMark];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        if (_isSelectWithCheckMark) {
            _overrayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
            _checkMark.alpha = 1.0f;
        }
        else {
            _overrayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
            _checkMark.alpha = 0.0f;
        }
        _overrayView.alpha = 1.0f;
    }
    else {
        _checkMark.alpha = 0.0f;
        _overrayView.alpha = 0.0f;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        if (_isSelectWithCheckMark) {
            _overrayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
        }
        else {
            _overrayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
        }
        _overrayView.alpha = 1.0f;
    }
    else {
        _overrayView.alpha = 0.0f;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _imageView.frame = rect;
    }
    else {
        CGFloat width = _imageView.image.size.width;
        CGFloat height = _imageView.image.size.height;
        if (width > 0 && height > 0) {
            if (width > height) {
                height = ceilf(rect.size.width * height/width * 2.0f) / 2.0f;
                _imageView.frame = CGRectMake(0.0f, ceilf(rect.size.width-height)/2.0f, rect.size.width, height);
            }
            else {
                width = ceilf(rect.size.width * width/height * 2.0f) / 2.0f;
                _imageView.frame = CGRectMake(ceilf(rect.size.width-width)/2.0f, 0.0f, width, rect.size.width);
            }
        }
        else {
            _imageView.frame = CGRectZero;
        }
    }
    
    _videoBackgroundView.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 20.0f, CGRectGetWidth(rect), 20.0f);
    _videoIconView.frame = CGRectMake(5.0f, CGRectGetHeight(rect) - 14.0f, 16.0f, 8.0f);
    _videoDurationLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 20.0f, CGRectGetWidth(rect) - 5.0f, 20.0f);

    _activityIndicatorView.center = self.contentView.center;
    _overrayView.frame = _imageView.frame;
    _checkMark.frame = CGRectMake(CGRectGetMaxX(_imageView.frame) - 32.0f, CGRectGetMaxY(_imageView.frame) - 32.0f, 28.0f, 28.0f);
}

- (void)setIsSelectWithCheckMark:(BOOL)isSelectWithCheckMark {
    _isSelectWithCheckMark = isSelectWithCheckMark;
    
    [self setSelected:self.isSelected];
}

- (void)setPhoto:(PLPhotoObject *)photo {
    _photo = photo;
    
    NSUInteger hash = photo.hash;
    _photoHash = hash;
    
    _imageView.image = nil;
    [_activityIndicatorView startAnimating];
    
    if (![_photo.type isEqualToString:ALAssetTypeVideo]) {
        _videoBackgroundView.hidden = YES;
        _videoDurationLabel.hidden = YES;
        _videoIconView.hidden = YES;
    }
    else {
        _videoBackgroundView.hidden = NO;
        _videoDurationLabel.text = [PLDateFormatter arrangeDuration:_photo.duration.doubleValue];
        _videoDurationLabel.hidden = NO;
        _videoIconView.hidden = NO;
    }
    
    NSURL *url = [NSURL URLWithString:photo.url];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.photoHash != hash) return;
            
            UIImage *image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.photoHash != hash) return;
                
                [sself.activityIndicatorView stopAnimating];
                sself.imageView.image = image;
                [sself setNeedsLayout];
            });
        } failureBlock:^(NSError *error) {
        }];
    });
}

@end
