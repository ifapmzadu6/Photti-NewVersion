//
//  PLAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumViewCell.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PADateFormatter.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PLAssetsManager.h"
#import "UIButton+HitEdgeInsets.h"
#import "PAActivityIndicatorView.h"

@interface PLAlbumViewCell ()

@property (strong, nonatomic) NSArray *imageViews;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *numPhotosLabel;
@property (strong, nonatomic) UIView *overrayView;

@property (nonatomic) NSUInteger albumHash;

@end

@implementation PLAlbumViewCell

static NSUInteger kPLAlbumViewCellNumberOfImageView = 3;

- (id)init {
    self = [super init];
    if (self) {
        [self initializetion];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializetion];
    }
    return self;
}

- (void)initializetion {
    self.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.contentView addSubview:_activityIndicatorView];
    
    NSMutableArray *imageViews = @[].mutableCopy;
    for (int i=0; i<kPLAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = [UIImageView new];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.tintColor = [[PAColors getColor:kPAColorsTypeTintWebColor] colorWithAlphaComponent:0.4f];
        imageView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
        imageView.layer.borderWidth = 1.0f;
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.contentView insertSubview:imageView atIndex:0];
        [imageViews addObject:imageView];
    }
    _imageViews = imageViews;
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:12.0f];
    _titleLabel.textColor = [PAColors getColor:kPAColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _numPhotosLabel = [UILabel new];
    _numPhotosLabel.font = [UIFont systemFontOfSize:10.0f];
    _numPhotosLabel.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
    [self.contentView addSubview:_numPhotosLabel];
        
    _overrayView = [UIView new];
    _overrayView.alpha = 0.0f;
    _overrayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    [self.contentView addSubview:_overrayView];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    _overrayView.alpha = (selected) ? 0.5f : 0.0f;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    _overrayView.alpha = (highlighted) ? 0.5f : 0.0f;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = self.contentView.bounds;
    
    CGFloat delta = 4.0f;
    CGFloat imageSize = CGRectGetWidth(rect)-delta*2.0f;
    
    for (int i=0; i<kPLAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = _imageViews[i];
        imageView.frame = CGRectMake(delta*i, delta*((kPLAlbumViewCellNumberOfImageView-1)-i), imageSize, imageSize);
    }
    
    UIImageView *imageView = _imageViews.firstObject;
    _activityIndicatorView.center = imageView.center;
    
    _titleLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 27.0f, CGRectGetWidth(rect), 14.0f);
    _numPhotosLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 13.0f, CGRectGetWidth(rect), 12.0f);
    
    _overrayView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(rect), CGRectGetMaxY(imageView.frame));
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _titleLabel.text = nil;
    _numPhotosLabel.text = nil;
    for (UIImageView *imageView in _imageViews) {
        imageView.image = nil;
    }
}

- (void)setAlbum:(PLAlbumObject *)album {
    _album = album;
    
    for (int i=0; i<kPLAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = _imageViews[i];
        imageView.image = nil;
    }
    
    if (!album) {
        _albumHash = 0;
        
        return;
    }
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    [_activityIndicatorView startAnimating];
    
    _titleLabel.text = album.name;
    _numPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Items", nil), @(album.photos.count).stringValue];
    
    __weak typeof(self) wself = self;
    if (album.photos.count > 0) {
        for (int i=0; i<MIN(kPLAlbumViewCellNumberOfImageView, album.photos.count); i++) {
            PLPhotoObject *thumbnail = album.photos[i];
            UIImageView *imageView = _imageViews[i];
            NSURL *url = [NSURL URLWithString:thumbnail.url];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (sself.albumHash != hash) return;
                    UIImage *image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        typeof(wself) sself = wself;
                        if (!sself) return;
                        if (sself.albumHash != hash) return;
                        [sself.activityIndicatorView stopAnimating];
                        imageView.image = image;
                    });
                } failureBlock:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        typeof(wself) sself = wself;
                        if (!sself) return;
                        [sself.activityIndicatorView stopAnimating];
                    });
                }];
            });
        }
    }
    else {
        [_activityIndicatorView stopAnimating];
        
        UIImage *noPhotoImage = [UIImage imageNamed:@"icon_240"];
        UIImageView *imageView = self.imageViews.firstObject;
        imageView.image = noPhotoImage;
    }
}

@end
