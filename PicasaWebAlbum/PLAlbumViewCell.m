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

@interface PLAlbumViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *numPhotosLabel;
@property (strong, nonatomic) UIButton *actionButton;
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
    self.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [UIImageView new];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.tintColor = [[PAColors getColor:PAColorsTypeTintLocalColor] colorWithAlphaComponent:0.4f];
    [self.contentView addSubview:_imageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:14.0f];
    _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    _titleLabel.numberOfLines = 2;
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
    [_actionButton setImage:[PAIcons albumActionButtonIconWithColor:[PAColors getColor:PAColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_actionButton setBackgroundImage:[PAIcons imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.05f]] forState:UIControlStateHighlighted];
    [self.contentView addSubview:_actionButton];
    
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
    
    CGSize titleLabelSize = [_titleLabel sizeThatFits:CGSizeMake(rect.size.width - 20.0f - 8.0f, CGFLOAT_MAX)];
    _titleLabel.frame = CGRectMake(8.0f, CGRectGetMaxY(_imageView.frame) + 3.0f, rect.size.width - 20.0f - 8.0f, titleLabelSize.height);
    
    _overrayView.frame = rect;
}

- (void)setAlbum:(PLAlbumObject *)album {
    _album = album;
    
    _imageView.image = nil;
    
    if (!album) {
        _albumHash = 0;
        
        _titleLabel.text = nil;
        _numPhotosLabel.text = nil;
        
        return;
    }
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    [_activityIndicatorView startAnimating];
    
    _titleLabel.text = album.name;
    _numPhotosLabel.text = [NSString stringWithFormat:@"%ld", (long)album.photos.count];
    _titleLabel.numberOfLines = 2;
    
    [self setNeedsLayout];
    
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
