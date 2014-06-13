//
//  PDTaskTableViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskTableViewCell.h"

#import "PWColors.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PDModelObject.h"
#import "PDCoreDataAPI.h"

#import "SDImageCache.h"

@interface PDTaskTableViewCell ()

@property (strong, nonatomic) UIImageView *thumbnailImageView;
@property (strong, nonatomic) UILabel *titleLabel;
//@property (strong, nonatomic) UILabel *

@property (nonatomic) NSUInteger taskHash;
@property (weak, nonatomic) NSURLSessionDataTask *task;

@end

@implementation PDTaskTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _thumbnailImageView = [[UIImageView alloc] init];
        _thumbnailImageView.clipsToBounds = YES;
        _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailImageView.alpha = 0.0f;
        [self.contentView addSubview:_thumbnailImageView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:15.0f];
        _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
        [self.contentView addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _thumbnailImageView.frame = CGRectMake(10.0f, 10.0f, rect.size.height - 20.0f, rect.size.height - 20.0f);
    
    _titleLabel.frame = CGRectMake(100.0f, 0.0f, 220.0f, CGRectGetHeight(rect));
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
}

#pragma mark Methods
- (void)setTaskObject:(PDBaseTaskObject *)taskObject {
    _taskObject = taskObject;
    
    NSUInteger hash = taskObject.hash;
    _taskHash = hash;
    
    _thumbnailImageView.alpha = 0.0f;
    
    __weak typeof(self) wself = self;
    if ([taskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
        PDWebToLocalAlbumTaskObject *webToLocalAlbumTaskObject = (PDWebToLocalAlbumTaskObject *)taskObject;
        NSString *id_str = webToLocalAlbumTaskObject.album_object_id_str;
        if (!id_str) {
            return;
        }
        
        [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count == 0) {
                return;
            }
            PWAlbumObject *albumObject = objects.firstObject;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.taskHash != hash) return;
                
                sself.titleLabel.text = albumObject.title;
            });
            
            [sself loadThumbnailImage:albumObject hash:hash];
        }];
    }
    else if ([taskObject isKindOfClass:[PDWebToLocalPhotosTaskObject class]]) {
//        PDWebToLocalPhotosTaskObject *webToLocalPhotosTaskObject = (PDWebToLocalPhotosTaskObject *)taskObject;
        
        
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebAlbumTaskObject class]]) {
//        PDLocalToWebAlbumTaskObject *localToWebAlbumTaskObject = (PDLocalToWebAlbumTaskObject *)taskObject;
        
        
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebPhotosTaskObject class]]) {
//        PDLocalToWebPhotosTaskObject *localToWebPhotosTaskObject = (PDLocalToWebPhotosTaskObject *)taskObject;
        
        
    }
}

- (void)loadThumbnailImage:(PWAlbumObject *)album hash:(NSUInteger)hash {
    NSString *urlString = album.tag_thumbnail_url;
    if (!urlString) {
        return;
    }
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        UIImage *thumbnailImage = [PDTaskTableViewCell createThumbnail:memoryCachedImage size:_thumbnailImageView.bounds.size];
        [self setImage:thumbnailImage hash:hash];
        
        return;
    }
    
    if ([imageCache diskImageExistsWithKey:urlString]) {
        if (_taskHash != hash) return;
        
        UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
        UIImage *thumbnailImage = [PDTaskTableViewCell createThumbnail:diskCachedImage size:_thumbnailImageView.bounds.size];
        [self setImage:thumbnailImage hash:hash];
        
        return;
    }
    
    NSURLSessionDataTask *beforeTask = _task;
    if (beforeTask) {
        [beforeTask cancel];
        _task = nil;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.taskHash != hash) return;
        
        request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            
            UIImage *image = [UIImage imageWithData:data];
            if (sself.taskHash == hash) {
                UIImage *thumbnailImage = [PDTaskTableViewCell createThumbnail:image size:sself.thumbnailImageView.bounds.size];
                [sself setImage:thumbnailImage hash:hash];
            }
            
            SDImageCache *imageCache = [SDImageCache sharedImageCache];
            [imageCache storeImage:image forKey:urlString toDisk:YES];
        }];
        [task resume];
        
        sself.task = task;
    }];
}

- (void)setImage:(UIImage *)image hash:(NSUInteger)hash {
    if (_taskHash != hash) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_taskHash != hash) {
            return;
        }
        
        _thumbnailImageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            _thumbnailImageView.alpha = 1.0f;
        }];
    });
}

+ (UIImage *)createThumbnail:(UIImage *)image size:(CGSize)size {
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return nil;
    }
    
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

#pragma mark Cell Height
+ (CGFloat)cellHeightForTaskObject:(PDBaseTaskObject *)taskObject {
    if ([taskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
        return 60.0f;
    }
    else if ([taskObject isKindOfClass:[PDWebToLocalPhotosTaskObject class]]) {
        return 60.0f;
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebAlbumTaskObject class]]) {
        return 60.0f;
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebPhotosTaskObject class]]) {
        return 60.0f;
    }
    return 0.0f;
}

@end
