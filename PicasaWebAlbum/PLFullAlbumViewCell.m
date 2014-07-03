//
//  PLFullAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/02.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLFullAlbumViewCell.h"

#import "PWColors.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"

@interface PLFullAlbumViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic) NSUInteger albumHash;

@end

@implementation PLFullAlbumViewCell

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
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [UIImageView new];
    _imageView.clipsToBounds = NO;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    _imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    _imageView.layer.shadowRadius = 5.0f;
    _imageView.layer.shadowOpacity = 0.3f;
    [self.contentView addSubview:_imageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = self.contentView.bounds;
    
    _imageView.frame = rect;
    
    _activityIndicatorView.center = _imageView.center;
}

- (void)setAlbum:(PLAlbumObject *)album {
    _album = album;
    
    _imageView.image = nil;
    [_activityIndicatorView startAnimating];
    
    if (!album || !album.managedObjectContext) {
        _albumHash = 0;
        return;
    }
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    NSUInteger count = album.photos.count;
    if (count > 0) {
        PLPhotoObject *thumbnail = album.thumbnail;
        if (!thumbnail) {
            thumbnail = album.photos.firstObject;
        }
        NSURL *url = [NSURL URLWithString:thumbnail.url];
        __weak typeof(self) wself = self;
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
    }
}

@end
