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

@property (nonatomic) NSUInteger requestHash;
@property (strong, nonatomic) NSURLSessionDataTask *task;

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
    [_actionButton setImage:[PWIcons albumActionButtonIcon] forState:UIControlStateNormal];
    [_actionButton setBackgroundImage:[PWIcons imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.05f]] forState:UIControlStateHighlighted];
    [self.contentView addSubview:_actionButton];
    
    _overrayView = [[UIView alloc] init];
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
    
    _titleLabel.frame = CGRectMake(8.0f, CGRectGetMaxY(_imageView.frame) + 4.0f, rect.size.width - 16.0f, 14.0f);
    
    _numPhotosLabel.frame = CGRectMake(CGRectGetMaxX(_imageView.frame) - 40.0f, CGRectGetMaxY(_imageView.frame) - 20.0f, 36.0f, 16.0f);
    
    _actionButton.frame = CGRectMake(CGRectGetMaxX(rect) - 20.0f, CGRectGetMaxY(_imageView.frame) + 5.0f, 20.0f, 30.0f);
    
    _overrayView.frame = rect;
}

- (void)setAlbum:(PWAlbumObject *)album {
    _album = album;
    
    NSArray *thumbnails = album.media.thumbnail.allObjects;
    thumbnails = [thumbnails sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PWPhotoMediaThumbnailObject *thumbnail1 = (PWPhotoMediaThumbnailObject *)obj1;
        PWPhotoMediaThumbnailObject *thumbnail2 = (PWPhotoMediaThumbnailObject *)obj2;
        return MAX(thumbnail1.width.integerValue, thumbnail1.height.integerValue) > MAX(thumbnail2.width.integerValue, thumbnail2.height.integerValue);
    }];
    PWPhotoMediaThumbnailObject *thumbnail = thumbnails.firstObject;
    if (!thumbnail) {
        [_activityIndicatorView stopAnimating];
        _imageView.alpha = 0.0f;
        _requestHash = 0;
    }
    else {
        _imageView.alpha = 0.0f;
        if (!_activityIndicatorView.isAnimating) {
            [_activityIndicatorView startAnimating];
        }
        
        NSUInteger hash = thumbnail.url.hash;
        _requestHash = hash;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *urlString = thumbnail.url;
            SDImageCache *imageCache = [SDImageCache sharedImageCache];
            UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
            if (memoryCachedImage) {
                UIImage *thumbnailImage = [self createThumbnail:memoryCachedImage size:self.bounds.size];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_requestHash == hash) {
                        [_activityIndicatorView stopAnimating];
                        _imageView.image = thumbnailImage;
                        [UIView animateWithDuration:0.1f animations:^{
                            _imageView.alpha = 1.0f;
                        }];
                    }
                });
            }
            else {
                if ([imageCache diskImageExistsWithKey:urlString]) {
                    if (_requestHash == hash) {
                        UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
                        UIImage *thumbnailImage = [self createThumbnail:diskCachedImage size:self.bounds.size];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (_requestHash == hash) {
                                [_activityIndicatorView stopAnimating];
                                _imageView.image = thumbnailImage;
                                [UIView animateWithDuration:0.1f animations:^{
                                    _imageView.alpha = 1.0f;
                                }];
                            }
                        });
                    }
                }
                else {
                    __weak typeof(self) wself = self;
                    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.description);
                            return;
                        }
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            typeof(wself) sself = wself;
                            if (!sself) return;
                            if (sself.requestHash != hash) return;
                            
                            if (sself.task) {
                                [sself.task cancel];
                                sself.task = nil;
                            }
                            
                            request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
                            sself.task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                if (error) {
                                    NSLog(@"%@", error.description);
                                    return;
                                }
                                typeof(wself) sself = wself;
                                if (!sself) return;
                                if (sself.requestHash == hash) {
                                    UIImage *image = [UIImage imageWithData:data];
                                    UIImage *thumbnailImage = [sself createThumbnail:image size:sself.bounds.size];
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        typeof(wself) sself = wself;
                                        if (!sself) return;
                                        if (sself.requestHash == hash) {
                                            [sself.activityIndicatorView stopAnimating];
                                            sself.imageView.image = thumbnailImage;
                                            [UIView animateWithDuration:0.1f animations:^{
                                                sself.imageView.alpha = 1.0f;
                                            }];
                                        }
                                    });
                                    SDImageCache *imageCache = [SDImageCache sharedImageCache];
                                    [imageCache storeImage:image forKey:urlString toDisk:YES];
                                }
                            }];
                            [sself.task resume];
                        });
                    }];
                }
            }
        });
    }
    
    _titleLabel.text = album.title;
    
    _numPhotosLabel.text = album.gphoto.numphotos;
    
    [self setNeedsLayout];
}

- (UIImage *)createThumbnail:(UIImage *)image size:(CGSize)size {
	CGFloat imageWidth = image.size.width;
	CGFloat imageHeight = image.size.height;
	
	CGRect cropRect;
	if (imageWidth >= imageHeight * 4.0f / 3.0f) {
		cropRect.size.width = imageHeight * 4.0f / 3.0f;
		cropRect.size.height = imageHeight;
		cropRect.origin.x = imageWidth / 2.0f - cropRect.size.width / 2.0f;
		cropRect.origin.y = 0.0f;
	}
	else {
		cropRect.size.width = imageWidth;
		cropRect.size.height = imageWidth * 3.0f / 4.0f;
		cropRect.origin.x = 0.0f;
		cropRect.origin.y = imageHeight / 2.0f - cropRect.size.height / 2.0f;
	}
	
	CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
	UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:2.0f orientation:UIImageOrientationUp];
	CGImageRelease(imageRef);
    
    CGFloat rate = MAX(cropRect.size.width, cropRect.size.height) / MAX(size.width, size.height);
    CGSize resizeSize = CGSizeMake(ceilf(cropRect.size.width * rate), ceilf(cropRect.size.height * rate));
    UIGraphicsBeginImageContextWithOptions(resizeSize, YES, 0.0f);
    [croppedImage drawInRect:(CGRect){.origin = CGPointZero, .size = resizeSize}];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	return resizedImage;
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
