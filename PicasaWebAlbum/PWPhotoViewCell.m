//
//  PWPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoViewCell.h"

#import "PWModelObject.h"
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

@property (nonatomic) NSUInteger requestHash;
@property (strong, nonatomic) NSURLSessionDataTask *task;

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

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        if (_isSelectWithCheckMark) {
            _overrayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.2f];
            _checkMark.alpha = 1.0f;
        }
        else {
            _overrayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.2f];
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

- (void)setPhoto:(PWPhotoObject *)photo {
    _photo = photo;
    
    NSArray *thumbnails = photo.media.thumbnail.allObjects;
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
}

- (UIImage *)createThumbnail:(UIImage *)image size:(CGSize)size {
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
