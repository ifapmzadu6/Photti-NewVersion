//
//  PWSearchTableViewWebAlbumCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSearchTableViewWebAlbumCell.h"

#import "PWModelObject.h"
#import "PWPicasaAPI.h"
#import "SDImageCache.h"

@interface PWSearchTableViewWebAlbumCell ()

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIImageView *thumbnailImageView;

@property (nonatomic) NSUInteger albumHash;
@property (strong, nonatomic) NSURLSessionDataTask *task;

@end

@implementation PWSearchTableViewWebAlbumCell

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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:17.0f];
    _titleLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_titleLabel];
    
    _thumbnailImageView = [[UIImageView alloc] init];
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    _thumbnailImageView.clipsToBounds = YES;
    [self.contentView addSubview:_thumbnailImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _thumbnailImageView.frame = CGRectMake(15.0f, 4.0f, 36.0f, 36.0f);
    
    _titleLabel.frame = CGRectMake(51.0f + 10.0f, 0.0f, rect.size.width - (51.0f + 10.0f) - 15.0f, rect.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setAlbum:(PWAlbumObject *)album isNowLoading:(BOOL)isNowLoading {
    _album = album;
    
    NSString *urlString = album.tag_thumbnail_url;
    if (!urlString) {
        return;
    }
    
    _titleLabel.text = album.title;
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            UIImage *thumbnailImage = [PWSearchTableViewWebAlbumCell createThumbnail:memoryCachedImage size:self.bounds.size];
            [self setImage:thumbnailImage hash:hash];
            
            return;
        }
        
        if ([imageCache diskImageExistsWithKey:urlString]) {
            if (_albumHash != hash) return;
            
            UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
            UIImage *thumbnailImage = [PWSearchTableViewWebAlbumCell createThumbnail:diskCachedImage size:self.bounds.size];
            [self setImage:thumbnailImage hash:hash];
            
            return;
        }
        
        NSURLSessionDataTask *beforeTask = _task;
        if (beforeTask) {
            [beforeTask cancel];
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
                if (sself.albumHash != hash) return;
                
                request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
                NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                    
                    UIImage *image = [UIImage imageWithData:data];
                    if (sself.albumHash == hash) {
                        UIImage *thumbnailImage = [PWSearchTableViewWebAlbumCell createThumbnail:image size:sself.bounds.size];
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
    if (_albumHash != hash) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_albumHash != hash) {
            return;
        }
        
        _thumbnailImageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            _thumbnailImageView.alpha = 1.0f;
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
