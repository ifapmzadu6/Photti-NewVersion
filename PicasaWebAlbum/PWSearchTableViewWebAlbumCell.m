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

@property (nonatomic) NSUInteger urlHash;
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
        //imageviewの初期化がここに
        
        _urlHash = 0;
    }
    else {
        //imageviewの初期化がここに
        
        NSUInteger hash = thumbnail.url.hash;
        _urlHash = hash;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *urlString = thumbnail.url;
            SDImageCache *imageCache = [SDImageCache sharedImageCache];
            UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
            if (memoryCachedImage) {
                UIImage *thumbnailImage = [self createThumbnail:memoryCachedImage size:CGSizeMake(45.0f, 45.0f)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_urlHash == hash) {
                        _thumbnailImageView.image = thumbnailImage;
                    }
                });
            }
            else {
                if ([imageCache diskImageExistsWithKey:urlString]) {
                    if (_urlHash == hash) {
                        UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
                        UIImage *thumbnailImage = [self createThumbnail:diskCachedImage size:CGSizeMake(45.0f, 45.0f)];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (_urlHash == hash) {
                                _thumbnailImageView.image = thumbnailImage;
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
                            if (sself.urlHash != hash) return;
                            
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
                                if (sself.urlHash == hash) {
                                    UIImage *image = [UIImage imageWithData:data];
                                    UIImage *thumbnailImage = [sself createThumbnail:image size:CGSizeMake(45.0f, 45.0f)];
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        typeof(wself) sself = wself;
                                        if (!sself) return;
                                        if (sself.urlHash == hash) {
                                            sself.thumbnailImageView.image = thumbnailImage;
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
