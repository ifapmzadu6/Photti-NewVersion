//
//  PWPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoViewCell.h"

#import "PWPicasaAPI.h"
#import "PAColors.h"
#import "PAIcons.h"
#import "PADateFormatter.h"
#import <Reachability.h>
#import <SDImageCache.h>
#import "SDWebImageDecoder.h"
#import "PWCoreDataAPI.h"
#import <Reachability.h>
#import "NSURLResponse+methods.h"
#import "PAActivityIndicatorView.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

@interface PWPhotoViewCell ()

@property (strong, nonatomic) UIImageView *videoBackgroundView;
@property (strong, nonatomic) UIImageView *videoIconView;
@property (strong, nonatomic) UILabel *videoDurationLabel;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) FLAnimatedImageView *animatedImageView;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIView *overrayView;
@property (strong, nonatomic) UIImageView *checkMark;

@property (nonatomic) NSUInteger photoHash;
@property (weak, nonatomic) NSURLSessionTask *task;

@end

@implementation PWPhotoViewCell

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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    }
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [UIImageView new];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    
    _animatedImageView = [FLAnimatedImageView new];
    _animatedImageView.clipsToBounds = YES;
    _animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView insertSubview:_animatedImageView belowSubview:_imageView];
    
    _videoBackgroundView = [UIImageView new];
    _videoBackgroundView.image = [PAIcons gradientVerticalFromColor:UIColor.clearColor toColor:UIColor.blackColor size:CGSizeMake(200.0f, 200.0f)];
    _videoBackgroundView.hidden = YES;
    [self.contentView addSubview:_videoBackgroundView];
    
    _videoIconView = [UIImageView new];
    _videoIconView.image = [PAIcons videoIconWithColor:[UIColor whiteColor] size:CGSizeMake(94.0f, 50.0f)];
    _videoIconView.contentMode = UIViewContentModeScaleAspectFit;
    _videoIconView.hidden = YES;
    [self.contentView addSubview:_videoIconView];
    
    _videoDurationLabel = [UILabel new];
    _videoDurationLabel.text = @"5:21";
    _videoDurationLabel.font = [UIFont systemFontOfSize:12.0f];
    _videoDurationLabel.textColor = [UIColor whiteColor];
    _videoDurationLabel.textAlignment = NSTextAlignmentRight;
    _videoDurationLabel.hidden = YES;
    [self.contentView addSubview:_videoDurationLabel];
    
    _overrayView = [UIView new];
    _overrayView.alpha = 0.0f;
    [self.contentView addSubview:_overrayView];
    
    _checkMark = [UIImageView new];
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
    
    [self layoutImageView];
    
    _activityIndicatorView.center = self.contentView.center;
}

- (void)layoutImageView {
    CGRect rect = self.contentView.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _imageView.frame = rect;
    }
    else {
        CGSize imageSize;
        if (!_animatedImageView.hidden) {
            imageSize = _animatedImageView.animatedImage.size;
        }
        else {
            imageSize = _imageView.image.size;
        }
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
    _animatedImageView.frame = _imageView.frame;
    
    CGRect imageFrame = _imageView.frame;
    _videoBackgroundView.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetMaxY(imageFrame) - 20.0f, CGRectGetWidth(imageFrame), 20.0f);
    _videoIconView.frame = CGRectMake(CGRectGetMinX(imageFrame) + 5.0f, CGRectGetMaxY(imageFrame) - 14.0f, 16.0f, 8.0f);
    _videoDurationLabel.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetMaxY(imageFrame) - 20.0f, CGRectGetWidth(imageFrame) - 5.0f, 20.0f);
    
    _overrayView.frame = imageFrame;
    _checkMark.frame = CGRectMake(CGRectGetMaxX(imageFrame) - 32.0f, CGRectGetMaxY(imageFrame) - 32.0f, 28.0f, 28.0f);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _imageView.image = nil;
    _imageView.hidden = YES;
    _animatedImageView.animatedImage = nil;
    _animatedImageView.hidden = YES;
    _videoBackgroundView.hidden = YES;
    _videoDurationLabel.hidden = YES;
    _videoIconView.hidden = YES;
    
}

- (UIImage *)image {
    return _imageView.image;
}

- (FLAnimatedImage *)animatedImage {
    return _animatedImageView.animatedImage;
}

- (void)setIsSelectWithCheckMark:(BOOL)isSelectWithCheckMark {
    _isSelectWithCheckMark = isSelectWithCheckMark;
    
    [self setSelected:self.isSelected];
}

- (void)setPhoto:(PWPhotoObject *)photo {
    _photo = photo;
    
    NSUInteger hash = photo.hash;
    _photoHash = hash;
    
    NSURLSessionTask *task = _task;
    if (task && task.state == NSURLSessionTaskStateRunning) {
        [task cancel];
    }
    
    if (!photo) {
        return;
    }
    
    NSString *urlString = photo.tag_thumbnail_url;
    if (!urlString) return;
    
    [self loadImageWithURLString:urlString hash:hash];
}

- (void)loadImageWithURLString:(NSString *)urlString hash:(NSUInteger)hash {
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isGifImage = [url.pathExtension isEqualToString:@"gif"];
    
    [_activityIndicatorView startAnimating];
    
    if (!isGifImage) {
        UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
                _videoBackgroundView.hidden = NO;
                
                NSString *durationString = durationString = _photo.gphoto.originalvideo_duration;
                _videoDurationLabel.text = [PADateFormatter arrangeDuration:durationString.doubleValue];
                _videoDurationLabel.hidden = NO;
                _videoIconView.hidden = NO;
            }
            
            [_activityIndicatorView stopAnimating];
            _imageView.image = memoryCachedImage;
            _imageView.hidden = NO;
            [self setNeedsLayout];
            
            return;
        }
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_photoHash != hash) return;
        SDImageCache *sharedImageCache = [SDImageCache sharedImageCache];
        if (isGifImage) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[sharedImageCache defaultCachePathForKey:urlString]]) {
                NSData *data = [self diskImageDataBySearchingAllPathsForKey:urlString];
                FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                if (animatedImage) {
                    [self setAnimatedImage:animatedImage hash:hash];
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    [self setImage:[UIImage decodedImageWithImage:image] hash:hash];
                }
                return;
            }
        }
        else {
            if ([sharedImageCache diskImageExistsWithKey:urlString]) {
                UIImage *diskCachedImage = [sharedImageCache imageFromDiskCacheForKey:urlString];
                [self setImage:[UIImage decodedImageWithImage:diskCachedImage] hash:hash];
                return;
            }
        }
        
        if (![Reachability reachabilityForInternetConnection].isReachable) {
            return;
        }
        
        [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                return;
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.photoHash != hash) return;
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error || !response.isSuccess) {
                    [self loadImageWithURLString:urlString hash:hash];
                    return;
                }
                if (isGifImage) {
                    FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                    [sself setAnimatedImage:animatedImage hash:hash];
                    if (data && urlString) {
                        [sself storeData:data key:urlString];
                    }
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    [sself setImage:[UIImage decodedImageWithImage:image] hash:hash];
                    if (image && urlString) {
                        [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                    }
                }
            }];
            sself.task = task;
            [task resume];
        }];
    });
}

#pragma mark Image
- (void)setImage:(UIImage *)image hash:(NSUInteger)hash {
    if (!image) return;
    if (_photoHash != hash) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_photoHash != hash) return;
        
        if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
            _videoBackgroundView.hidden = NO;
            
            NSString *durationString = durationString = _photo.gphoto.originalvideo_duration;
            _videoDurationLabel.text = [PADateFormatter arrangeDuration:durationString.doubleValue];
            _videoDurationLabel.hidden = NO;
            _videoIconView.hidden = NO;
        }
        
        [_activityIndicatorView stopAnimating];
        _imageView.image = image;
        _imageView.hidden = NO;
        [self setNeedsLayout];
    });
}

#pragma mark AnimatedImage
- (void)setAnimatedImage:(FLAnimatedImage *)animatedImage hash:(NSUInteger)hash {
    if (!animatedImage) return;
    if (_photoHash != hash) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_photoHash != hash) return;
        
        if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
            _videoBackgroundView.hidden = NO;
            
            NSString *durationString = durationString = _photo.gphoto.originalvideo_duration;
            _videoDurationLabel.text = [PADateFormatter arrangeDuration:durationString.doubleValue];
            _videoDurationLabel.hidden = NO;
            _videoIconView.hidden = NO;
        }
        
        [_activityIndicatorView stopAnimating];
        _animatedImageView.animatedImage = animatedImage;
        _animatedImageView.hidden = NO;
        [self setNeedsLayout];
    });
}

#pragma mark DiscCache
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key {
    NSString *defaultPath = [[SDImageCache sharedImageCache] defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data) {
        return data;
    }
    return nil;
}

- (void)storeData:(NSData *)data key:(NSString *)key {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *diskCachePath = [paths[0] stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"];
    if (data) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        [[NSFileManager defaultManager] createFileAtPath:[[SDImageCache sharedImageCache] defaultCachePathForKey:key] contents:data attributes:nil];
    }
}

@end
