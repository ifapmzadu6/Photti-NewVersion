//
//  PWPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoViewCell.h"

#import "UIImageView+AFNetworking.h"
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
    self.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
    
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
    
    _imageView.frame = rect;
    
    _activityIndicatorView.center = _imageView.center;
    
    _overrayView.frame = rect;
    
    _checkMark.frame = CGRectMake(CGRectGetMaxX(rect) - 32.0f, CGRectGetMaxY(rect) - 32.0f, 28.0f, 28.0f);
}

- (void)setIsSelectWithCheckMark:(BOOL)isSelectWithCheckMark {
    _isSelectWithCheckMark = isSelectWithCheckMark;
    
    [self setSelected:self.isSelected];
}

- (void)setPhoto:(PWPhotoObject *)photo isNowLoading:(BOOL)isNowLoading {
    _photo = photo;
    
    NSUInteger hash = photo.hash;
    _photoHash = hash;
    
    _imageView.alpha = 0.0f;
    [_activityIndicatorView startAnimating];
    
    if (!photo) {
        return;
    }
    
    NSString *urlString = photo.tag_thumbnail_url;
    if (!urlString) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_photoHash != hash) return;
        
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            UIImage *thumbnailImage = [PWPhotoViewCell createThumbnail:memoryCachedImage size:self.bounds.size];
            [self setImage:thumbnailImage hash:hash];
            
            return;
        }
        
        if ([imageCache diskImageExistsWithKey:urlString]) {
            if (_photoHash != hash) return;
            
            UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
            UIImage *thumbnailImage = [PWPhotoViewCell createThumbnail:diskCachedImage size:self.bounds.size];
            [self setImage:thumbnailImage hash:hash];
            
            return;
        }
        
        NSURLSessionDataTask *task = _task;
        if (task) {
            [task cancel];
        }
        
        if (isNowLoading) {
            return;
        }
        
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
                
                request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
                NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    UIImage *image = [UIImage imageWithData:data];
                    
                    if (sself.photoHash == hash) {
                        UIImage *thumbnailImage = [PWPhotoViewCell createThumbnail:image size:sself.bounds.size];
                        [sself setImage:thumbnailImage hash:hash];
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
    if (_photoHash != hash) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_photoHash != hash) {
            return;
        }
        
        [_activityIndicatorView stopAnimating];
        _imageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            _imageView.alpha = 1.0f;
        }];
    });
}

+ (UIImage *)createThumbnail:(UIImage *)image size:(CGSize)size {
	CGFloat imageWidth = image.size.width;
	CGFloat imageHeight = image.size.height;
	
	CGRect cropRect;
	if (imageWidth >= imageHeight) {
		cropRect.size.width = imageHeight;
		cropRect.size.height = imageHeight;
		cropRect.origin.x = imageWidth / 2.0f - cropRect.size.width / 2.0f;
		cropRect.origin.y = 0.0f;
	}
	else {
		cropRect.size.width = imageWidth;
		cropRect.size.height = imageWidth;
		cropRect.origin.x = 0.0f;
		cropRect.origin.y = imageHeight / 2.0f - cropRect.size.height / 2.0f;
	}
	
	CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
	UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:2.0f orientation:UIImageOrientationUp];
	CGImageRelease(imageRef);
    
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
    [croppedImage drawInRect:(CGRect){.origin = CGPointZero, .size = size}];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	return resizedImage;
}

@end
