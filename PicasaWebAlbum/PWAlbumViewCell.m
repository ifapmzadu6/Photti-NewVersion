//
//  PWAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumViewCell.h"

#import "PWModelObject.h"
#import "UIImageView+AFNetworking.h"
#import "PWPicasaAPI.h"
#import "PWColors.h"
#import "Reachability.h"
#import "SDImageCache.h"
#import "PWIcons.h"
#import "UIButton+HitEdgeInsets.h"

@interface PWAlbumViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *numPhotosLabel;
@property (strong, nonatomic) UIButton *actionButton;
@property (strong, nonatomic) UIView *overrayView;

@property (nonatomic) NSUInteger albumHash;
@property (weak, nonatomic) NSURLSessionDataTask *task;

@end

@implementation PWAlbumViewCell

- (id)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    self.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:14.0f];
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
        
    _numPhotosLabel = [[UILabel alloc] init];
    _numPhotosLabel.font = [UIFont systemFontOfSize:12.0f];
    _numPhotosLabel.textAlignment = NSTextAlignmentCenter;
    _numPhotosLabel.textColor = [UIColor whiteColor];
    _numPhotosLabel.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.667f];
    [self.contentView addSubview:_numPhotosLabel];
    
    _actionButton = [[UIButton alloc] init];
    [_actionButton addTarget:self action:@selector(actionButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _actionButton.hitEdgeInsets = UIEdgeInsetsMake(-4.0f, -10.0f, -4.0f, 0.0f);
    [_actionButton setImage:[PWIcons albumActionButtonIconWithColor:[PWColors getColor:PWColorsTypeTintWebColor]] forState:UIControlStateNormal];
    [_actionButton setBackgroundImage:[PWIcons imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.05f]] forState:UIControlStateHighlighted];
    [self.contentView addSubview:_actionButton];
    
    _overrayView = [[UIView alloc] init];
    _overrayView.alpha = 0.0f;
    _overrayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
    [self.contentView addSubview:_overrayView];
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerAction:)];
    [self addGestureRecognizer:gestureRecognizer];
}

- (void)dealloc {
    NSURLSessionDataTask *task = _task;
    if (task) {
        [task cancel];
    }
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
    
    _titleLabel.frame = CGRectMake(8.0f, CGRectGetMaxY(_imageView.frame) + 4.0f, rect.size.width - 20.0f - 4.0f, 14.0f);
    
    _numPhotosLabel.frame = CGRectMake(CGRectGetMaxX(_imageView.frame) - 40.0f, CGRectGetMaxY(_imageView.frame) - 20.0f, 36.0f, 16.0f);
    
    _actionButton.frame = CGRectMake(CGRectGetMaxX(rect) - 20.0f, CGRectGetMaxY(_imageView.frame) + 5.0f, 20.0f, 30.0f);
    
    _overrayView.frame = rect;
}

- (void)setAlbum:(PWAlbumObject *)album isNowLoading:(BOOL)isNowLoading {
    _album = album;
    
    _imageView.alpha = 0.0f;
    _titleLabel.text = nil;
    _numPhotosLabel.text = nil;
    [_activityIndicatorView startAnimating];
    
    if (!album) {
        return;
    }
    
    _titleLabel.text = album.title;
    _numPhotosLabel.text = album.tag_numphotos;
    
    [self loadThumbnailImage:album isNowLoading:isNowLoading];
}

- (void)loadThumbnailImage:(PWAlbumObject *)album isNowLoading:(BOOL)isNowLoading {
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    NSString *urlString = album.tag_thumbnail_url;
    if (!urlString) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            [self setImage:memoryCachedImage hash:hash];
            
            return;
        }
        
        if ([imageCache diskImageExistsWithKey:urlString]) {
            if (_albumHash != hash) return;
            
            UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
            [self setImage:diskCachedImage hash:hash];
            
            return;
        }
        
        NSURLSessionDataTask *beforeTask = _task;
        if (beforeTask) {
            [beforeTask cancel];
            _task = nil;
        }
        
        if (isNowLoading) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
        
        __weak typeof(self) wself = self;
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.albumHash != hash) return;
                
                request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
                NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    });
                    
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                    
                    UIImage *image = [UIImage imageWithData:data];
                    if (sself.albumHash == hash) {
                        [sself setImage:image hash:hash];
                    }
                    
                    SDImageCache *imageCache = [SDImageCache sharedImageCache];
                    [imageCache storeImage:image forKey:urlString toDisk:YES];
                }];
                [task resume];
                
                sself.task = task;
            });
        }];
    });
}

- (void)setImage:(UIImage *)image hash:(NSUInteger)hash {
    if (_albumHash != hash) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_albumHash != hash) {
            return;
        }
        
        [_activityIndicatorView stopAnimating];
        _imageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            _imageView.alpha = 1.0f;
        }];
    });
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
