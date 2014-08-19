//
//  PWPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoViewCell.h"

#import "PWPicasaAPI.h"
#import "PWColors.h"
#import "PWIcons.h"
#import "PLDateFormatter.h"
#import <Reachability.h>
#import <SDImageCache.h>
#import "SDWebImageDecoder.h"
#import "PWCoreDataAPI.h"
#import <Reachability.h>
#import "NSURLResponse+methods.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

@interface PWPhotoViewCell ()

@property (strong, nonatomic) UIImageView *videoBackgroundView;
@property (strong, nonatomic) UIImageView *videoIconView;
@property (strong, nonatomic) UILabel *videoDurationLabel;
@property (strong, nonatomic) FLAnimatedImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIView *overrayView;
@property (strong, nonatomic) UIImageView *checkMark;

@property (nonatomic) NSUInteger photoHash;

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
        self.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
    }
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [FLAnimatedImageView new];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    
    _videoBackgroundView = [UIImageView new];
    _videoBackgroundView.image = [PWIcons gradientVerticalFromColor:UIColor.clearColor toColor:UIColor.blackColor size:CGSizeMake(200.0f, 200.0f)];
    _videoBackgroundView.hidden = YES;
    [self.contentView addSubview:_videoBackgroundView];
    
    _videoIconView = [UIImageView new];
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
        if (_imageView.animatedImage) {
            imageSize = [FLAnimatedImage sizeForImage:_imageView.animatedImage];
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
    
    CGRect imageFrame = _imageView.frame;
    _videoBackgroundView.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetMaxY(imageFrame) - 20.0f, CGRectGetWidth(imageFrame), 20.0f);
    _videoIconView.frame = CGRectMake(CGRectGetMinX(imageFrame) + 5.0f, CGRectGetMaxY(imageFrame) - 14.0f, 16.0f, 8.0f);
    _videoDurationLabel.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetMaxY(imageFrame) - 20.0f, CGRectGetWidth(imageFrame) - 5.0f, 20.0f);
    
    _overrayView.frame = imageFrame;
    _checkMark.frame = CGRectMake(CGRectGetMaxX(imageFrame) - 32.0f, CGRectGetMaxY(imageFrame) - 32.0f, 28.0f, 28.0f);
}

- (UIImage *)image {
    return _imageView.image;
}

- (FLAnimatedImage *)animatedImage {
    return _imageView.animatedImage;
}

- (void)setIsSelectWithCheckMark:(BOOL)isSelectWithCheckMark {
    _isSelectWithCheckMark = isSelectWithCheckMark;
    
    [self setSelected:self.isSelected];
}

- (void)setPhoto:(PWPhotoObject *)photo {
    _photo = photo;
    
    NSUInteger hash = photo.hash;
    _photoHash = hash;
    
    if (!photo) return;
    
    _videoBackgroundView.hidden = YES;
    _videoDurationLabel.hidden = YES;
    _videoIconView.hidden = YES;
    
    NSString *urlString = photo.tag_thumbnail_url;
    if (!urlString) return;
    
    [self loadImageWithURLString:urlString hash:hash];
}

- (void)loadImageWithURLString:(NSString *)urlString hash:(NSUInteger)hash {
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isGifImage = [url.pathExtension isEqualToString:@"gif"];
    
    if (!isGifImage) {
        UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
                _videoBackgroundView.hidden = NO;
                
                NSString *durationString = durationString = _photo.gphoto.originalvideo_duration;
                _videoDurationLabel.text = [PLDateFormatter arrangeDuration:durationString.doubleValue];
                _videoDurationLabel.hidden = NO;
                _videoIconView.hidden = NO;
            }
            
            _imageView.image = memoryCachedImage;
            _imageView.alpha = 1.0f;
            [self setNeedsLayout];
            
            return;
        }
    }
    
    _imageView.alpha = 0.0f;
    _imageView.image = nil;
    [_activityIndicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_photoHash != hash) return;
        SDImageCache *sharedImageCache = [SDImageCache sharedImageCache];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[sharedImageCache defaultCachePathForKey:urlString]]) {
            if (isGifImage) {
                NSData *data = [self diskImageDataBySearchingAllPathsForKey:urlString];
                FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                [self setAnimatedImage:animatedImage hash:hash];
            }
            else {
                UIImage *diskCachedImage = [sharedImageCache imageFromDiskCacheForKey:urlString];
                [self setImage:[UIImage decodedImageWithImage:diskCachedImage] hash:hash];
            }
            return;
        }
        
        if (![Reachability reachabilityForInternetConnection].isReachable) {
            return;
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.photoHash != hash) return;
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error || !response.isSuccess) {
                    [sself loadImageWithURLString:urlString hash:hash];
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
            [task resume];
        }];
    });
}

- (void)setImage:(UIImage *)image hash:(NSUInteger)hash {
    if (!image) return;
    if (_photoHash != hash) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_photoHash != hash) return;
        
        if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
            _videoBackgroundView.hidden = NO;
            
            NSString *durationString = durationString = _photo.gphoto.originalvideo_duration;
            _videoDurationLabel.text = [PLDateFormatter arrangeDuration:durationString.doubleValue];
            _videoDurationLabel.hidden = NO;
            _videoIconView.hidden = NO;
        }
        
        [_activityIndicatorView stopAnimating];
        _imageView.image = image;
        [self layoutImageView];
        [UIView animateWithDuration:0.1f animations:^{
            _imageView.alpha = 1.0f;
        }];
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
            _videoDurationLabel.text = [PLDateFormatter arrangeDuration:durationString.doubleValue];
            _videoDurationLabel.hidden = NO;
            _videoIconView.hidden = NO;
        }
        
        [_activityIndicatorView stopAnimating];
        _imageView.animatedImage = animatedImage;
        _imageView.alpha = 1.0f;
        [self layoutImageView];
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
