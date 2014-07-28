//
//  PLAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumViewCell.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLDateFormatter.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PLAssetsManager.h"
#import "UIButton+HitEdgeInsets.h"

@interface PLAlbumViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *numPhotosLabel;
@property (strong, nonatomic) UIButton *actionButton;
@property (strong, nonatomic) UILabel *autoUploadLabel;
@property (strong, nonatomic) UIImageView *autoUploadIcon;
@property (strong, nonatomic) UIView *overrayView;

@property (nonatomic) NSUInteger albumHash;

@end

@implementation PLAlbumViewCell

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
    self.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [UIImageView new];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.4f];
    [self.contentView addSubview:_imageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:14.5f];
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    _titleLabel.numberOfLines = 1;
    [self.contentView addSubview:_titleLabel];
    
    _numPhotosLabel = [UILabel new];
    _numPhotosLabel.font = [UIFont systemFontOfSize:12.0f];
    _numPhotosLabel.textAlignment = NSTextAlignmentCenter;
    _numPhotosLabel.textColor = [UIColor whiteColor];
    _numPhotosLabel.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.667f];
    [self.contentView addSubview:_numPhotosLabel];
    
    _actionButton = [UIButton new];
    [_actionButton addTarget:self action:@selector(actionButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _actionButton.hitEdgeInsets = UIEdgeInsetsMake(-4.0f, -10.0f, -4.0f, 0.0f);
    [_actionButton setImage:[PWIcons albumActionButtonIconWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_actionButton setBackgroundImage:[PWIcons imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.05f]] forState:UIControlStateHighlighted];
    [self.contentView addSubview:_actionButton];
    
    _autoUploadLabel = [UILabel new];
    _autoUploadLabel.font = [UIFont systemFontOfSize:11.0f];
//    _autoUploadLabel.backgroundColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.8f];
    _autoUploadLabel.textColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.8f];
    _autoUploadLabel.text = @"AUTO";
    [self.contentView addSubview:_autoUploadLabel];
    
    _autoUploadIcon = [UIImageView new];
    _autoUploadIcon.image = [[UIImage imageNamed:@"UploadOnlyIconMini"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _autoUploadIcon.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.8f];
    [self.contentView addSubview:_autoUploadIcon];
    
    _overrayView = [UIView new];
    _overrayView.alpha = 0.0f;
    _overrayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
    [self.contentView addSubview:_overrayView];
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerAction:)];
    [self addGestureRecognizer:gestureRecognizer];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        _overrayView.alpha = 1.0f;
    }
    else {
        _overrayView.alpha = 0.0f;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        _overrayView.alpha = 1.0f;
    }
    else {
        _overrayView.alpha = 0.0f;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = self.contentView.bounds;
    
    _imageView.frame = CGRectMake(0.0f, 0.0f, rect.size.width, ceilf(rect.size.width * 3.0f / 4.0f));
    
    _activityIndicatorView.center = _imageView.center;
    
    _numPhotosLabel.frame = CGRectMake(CGRectGetMaxX(_imageView.frame) - 40.0f, CGRectGetMaxY(_imageView.frame) - 20.0f, 36.0f, 16.0f);
    
    _actionButton.frame = CGRectMake(CGRectGetMaxX(rect) - 20.0f, CGRectGetMaxY(_imageView.frame) + 5.0f, 20.0f, 30.0f);
    
    _titleLabel.frame = CGRectMake(8.0f, CGRectGetMaxY(_imageView.frame) + 3.0f, rect.size.width - 20.0f - 8.0f, 15.0f);
    
    _autoUploadIcon.frame = CGRectMake(7.0f, CGRectGetMaxY(_imageView.frame) + 21.5f, 15.0f, 15.0f);
    
    CGSize autoUploadLabelSize = [_autoUploadLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _autoUploadLabel.frame = CGRectMake(24.0f, CGRectGetMaxY(_imageView.frame) + 22.0f, autoUploadLabelSize.width + 1.0f, autoUploadLabelSize.height);
    
    _overrayView.frame = rect;
}

- (void)setAlbum:(PLAlbumObject *)album {
    _album = album;
    
    _titleLabel.text = nil;
    _numPhotosLabel.text = nil;
    _imageView.image = nil;
    [_activityIndicatorView startAnimating];
    
    if (!album) {
        _albumHash = 0;
        return;
    }
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    _titleLabel.text = album.name;
    _numPhotosLabel.text = [NSString stringWithFormat:@"%ld", (long)album.photos.count];
    
    __weak typeof(self) wself = self;
    if (album.photos.count > 0) {
        PLPhotoObject *thumbnail = album.thumbnail;
        if (!thumbnail) {
            thumbnail = album.photos.firstObject;
        }
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
                    sself.imageView.image = image;
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
    else {
        [_activityIndicatorView stopAnimating];
        
        UIImage *noPhotoImage = [[UIImage imageNamed:@"NoPhoto"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _imageView.image = noPhotoImage;
        _imageView.alpha = 1.0f;
    }
}

- (void)setIsDisableActionButton:(BOOL)isDisableActionButton {
    _isDisableActionButton = isDisableActionButton;
    
    _actionButton.hidden = isDisableActionButton;
}

#pragma mark Action
- (void)actionButtonAction {
    if (_actionButtonActionBlock) {
        _actionButtonActionBlock(_album);
    }
}

- (void)longPressGestureRecognizerAction:(UILongPressGestureRecognizer *)sender {
    if([sender state] == UIGestureRecognizerStateBegan){
        if (_actionButtonActionBlock) {
            _actionButtonActionBlock(_album);
        }
    }
}

@end
