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
    
    _titleLabel.text = nil;
    _thumbnailImageView.alpha = 0.0f;
    
    if ([taskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
        PDWebToLocalAlbumTaskObject *webToLocalAlbumTaskObject = (PDWebToLocalAlbumTaskObject *)taskObject;
        
        _titleLabel.text = webToLocalAlbumTaskObject.album_object_title;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self loadThumbnailImageWithURLString:webToLocalAlbumTaskObject.album_object_thumbnail_url hash:hash];
        });
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

- (void)loadThumbnailImageWithURLString:(NSString *)urlString hash:(NSUInteger)hash {
    if (!urlString) {
        return;
    }
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        [self setImage:memoryCachedImage hash:hash];
        
        return;
    }
    
    if ([imageCache diskImageExistsWithKey:urlString]) {
        if (_taskHash != hash) return;
        
        UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
        [self setImage:diskCachedImage hash:hash];
        
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
                [sself setImage:image hash:hash];
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
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.taskHash != hash) return;
        
        sself.thumbnailImageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            sself.thumbnailImageView.alpha = 1.0f;
        }];
    });
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
