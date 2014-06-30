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
#import "Reachability.h"
#import "SDImageCache.h"

@interface PWPhotoViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIView *overrayView;
@property (strong, nonatomic) UIImageView *checkMark;

@property (nonatomic) NSUInteger photoHash;
@property (weak, nonatomic) NSURLSessionDataTask *task;

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
    
    _imageView = [[UIImageView alloc] init];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    
    _overrayView = [[UIView alloc] init];
    _overrayView.alpha = 0.0f;
    [self.contentView addSubview:_overrayView];
    
    _checkMark = [[UIImageView alloc] init];
    _checkMark.image = [UIImage imageNamed:@"CheckMark"];
    _checkMark.alpha = 0.0f;
    [self.contentView addSubview:_checkMark];
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
    if (photo.managedObjectContext == nil) return;
    
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_photoHash != hash) return;
        
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:urlString]) {
            if (_photoHash != hash) return;
            
            UIImage *diskCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
            [self setImage:diskCachedImage hash:hash];
            
            return;
        }
        
        NSURLSessionDataTask *task = _task;
        if (task) {
            [task cancel];
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
                if (sself.photoHash != hash) return;
                
                NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    });
                    
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (error) {
//                        NSLog(@"%@", error.description);
                        return;
                    }
                    UIImage *image = [UIImage imageWithData:data];
                    [sself setImage:image hash:hash];
                    
                    [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                }];
                [task resume];
                sself.task = task;
            });
        }];
    });
}

- (void)setImage:(UIImage *)image hash:(NSUInteger)hash {
    if (_photoHash != hash) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_photoHash != hash) {
            return;
        }
        
        [_activityIndicatorView stopAnimating];
        _imageView.image = image;
        [self setNeedsLayout];
        [UIView animateWithDuration:0.1f animations:^{
            _imageView.alpha = 1.0f;
        }];
    });
}

@end
