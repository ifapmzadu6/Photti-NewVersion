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
#import "Reachability.h"
#import "SDImageCache.h"
#import "PWCoreDataAPI.h"

@interface PWPhotoViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImageView *videoBackgroundView;
@property (strong, nonatomic) UIImageView *videoIconView;
@property (strong, nonatomic) UILabel *videoDurationLabel;
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
    
    _imageView = [UIImageView new];
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
    
    CGRect imageFrame = _imageView.frame;
    _videoBackgroundView.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetHeight(imageFrame) - 20.0f, CGRectGetWidth(imageFrame), 20.0f);
    _videoIconView.frame = CGRectMake(CGRectGetMinX(imageFrame) + 5.0f, CGRectGetHeight(imageFrame) - 14.0f, 16.0f, 8.0f);
    _videoDurationLabel.frame = CGRectMake(CGRectGetMinX(imageFrame), CGRectGetHeight(imageFrame) - 20.0f, CGRectGetWidth(imageFrame) - 5.0f, 20.0f);
    
    _activityIndicatorView.center = self.contentView.center;
    _overrayView.frame = _imageView.frame;
    _checkMark.frame = CGRectMake(CGRectGetMaxX(_imageView.frame) - 32.0f, CGRectGetMaxY(_imageView.frame) - 32.0f, 28.0f, 28.0f);
}

- (void)setIsSelectWithCheckMark:(BOOL)isSelectWithCheckMark {
    _isSelectWithCheckMark = isSelectWithCheckMark;
    
    [self setSelected:self.isSelected];
}

- (void)setPhoto:(PWPhotoObject *)photo isNowLoading:(BOOL)isNowLoading {
    _photo = photo;
    
    NSUInteger hash = photo.hash;
    _photoHash = hash;
    
    if (!photo) return;
    
    if (photo.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
        _videoBackgroundView.hidden = YES;
        _videoDurationLabel.hidden = YES;
        _videoIconView.hidden = YES;
    }
    if (photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
        _videoBackgroundView.hidden = NO;
        
        NSString *durationString = durationString = photo.gphoto.originalvideo_duration;
        _videoDurationLabel.text = [PLDateFormatter arrangeDuration:durationString.doubleValue];
        _videoDurationLabel.hidden = NO;
        _videoIconView.hidden = NO;
    }
    
    NSString *urlString = photo.tag_thumbnail_url;
    if (!urlString) return;
    
    UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        _imageView.image = memoryCachedImage;
        _imageView.alpha = 1.0f;
        [self setNeedsLayout];
        
        return;
    }
    
    _imageView.alpha = 0.0f;
    [_activityIndicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_photoHash != hash) return;
        
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:urlString]) {
            UIImage *diskCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
            [self setImage:diskCachedImage hash:hash];
            
            return;
        }
        
        if (isNowLoading) {
            return;
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
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
                if (error) {
//                    NSLog(@"%@", error.description);
                    return;
                }
                UIImage *image = [UIImage imageWithData:data];
                [sself setImage:image hash:hash];
                
                if (image && urlString) {
                    [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
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
        
        [_activityIndicatorView stopAnimating];
        _imageView.image = image;
        [self setNeedsLayout];
        [UIView animateWithDuration:0.1f animations:^{
            _imageView.alpha = 1.0f;
        }];
    });
}

@end
