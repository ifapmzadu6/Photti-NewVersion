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
#import "PLAssetsManager.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PDModelObject.h"
#import "PDCoreDataAPI.h"

#import "SDImageCache.h"

#import "PWLoundedCornerBadgeLabel.h"

@interface PDTaskTableViewCell ()

@property (strong, nonatomic) UIImageView *thumbnailImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *taskTypeLabel;
@property (strong, nonatomic) PWLoundedCornerBadgeLabel *countLabel;

@property (nonatomic) NSUInteger taskHash;
@property (weak, nonatomic) NSURLSessionDataTask *task;

@end

@implementation PDTaskTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.showsReorderControl = YES;
        
        _thumbnailImageView = [[UIImageView alloc] init];
        _thumbnailImageView.clipsToBounds = YES;
        _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailImageView.alpha = 0.0f;
        [self.contentView addSubview:_thumbnailImageView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:15.0f];
        _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
        [self.contentView addSubview:_titleLabel];
        
        _taskTypeLabel = [[UILabel alloc] init];
        _taskTypeLabel.font = [UIFont systemFontOfSize:10.0f];
        [self.contentView addSubview:_taskTypeLabel];
        
        _countLabel = [[PWLoundedCornerBadgeLabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:15.0f];
        [self.contentView addSubview:_countLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _thumbnailImageView.frame = CGRectMake(15.0f, 10.0f, rect.size.height - 20.0f, rect.size.height - 20.0f);
    
    _titleLabel.frame = CGRectMake(70.0f, 26.0f, 220.0f, 15.0f);
    
    _taskTypeLabel.frame = CGRectMake(70.0f, 10.0f, 220.0f, 10.0f);
    
    CGSize countLabelSize = [_countLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _countLabel.frame = CGRectMake(CGRectGetMaxX(rect) - (countLabelSize.width + 20.0f), 20.0f, countLabelSize.width + 16.0f, 20.0f);
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
        NSString *id_str = webToLocalAlbumTaskObject.album_object_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Download", nil);
        _taskTypeLabel.textColor = [PWColors getColor:PWColorsTypeTintLocalColor];
        _countLabel.text = [NSString stringWithFormat:@"%d", taskObject.photos.count];
        
        __weak typeof(self) wself = self;
        [PWCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
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
                sself.titleLabel.text = albumObject.title;
            });
            
            [sself loadThumbnailImageWithURLString:albumObject.tag_thumbnail_url hash:hash];
        }];
    }
    else if ([taskObject isKindOfClass:[PDWebToLocalPhotosTaskObject class]]) {
//        PDWebToLocalPhotosTaskObject *webToLocalPhotosTaskObject = (PDWebToLocalPhotosTaskObject *)taskObject;
        
        
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebAlbumTaskObject class]]) {
        PDLocalToWebAlbumTaskObject *localToWebAlbumTaskObject = (PDLocalToWebAlbumTaskObject *)taskObject;
        NSString *id_str = localToWebAlbumTaskObject.album_object_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Upload", nil);
        _taskTypeLabel.textColor = [PWColors getColor:PWColorsTypeTintWebColor];
        _countLabel.text = [NSString stringWithFormat:@"%d", taskObject.photos.count];
        
        __weak typeof(self) wself = self;
        [PLCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count == 0) {
                return;
            }
            PLAlbumObject *albumObject = objects.firstObject;
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                sself.titleLabel.text = albumObject.name;
                
                PLPhotoObject *thumbnail = albumObject.thumbnail;
                if (!thumbnail) {
                    thumbnail = albumObject.photos.firstObject;
                }
                NSURL *url = [NSURL URLWithString:thumbnail.url];
                [sself loadThmbnailImageWithAssetURL:url hash:hash];
            });
        }];
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebPhotosTaskObject class]]) {
//        PDLocalToWebPhotosTaskObject *localToWebPhotosTaskObject = (PDLocalToWebPhotosTaskObject *)taskObject;
        
        
    }
    
    [self setNeedsLayout];
}

- (void)loadThumbnailImageWithURLString:(NSString *)urlString hash:(NSUInteger)hash {
    if (!urlString) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
    });
}

- (void)loadThmbnailImageWithAssetURL:(NSURL *)assetUrl hash:(NSUInteger)hash {
    if (!assetUrl) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PLAssetsManager assetForURL:assetUrl resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
            [sself setImage:image hash:hash];
        } failureBlock:^(NSError *error) {
            
        }];
    });
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

- (void)setIsNowLoading:(BOOL)isNowLoading {
    _isNowLoading = isNowLoading;
    
    if (isNowLoading) {
        _countLabel.badgeBorderWidth = 0.0f;
        _countLabel.textColor = [UIColor whiteColor];
        
        if ([_taskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
            _countLabel.badgeBackgroundColor = [PWColors getColor:PWColorsTypeTintLocalColor];
        }
        else if ([_taskObject isKindOfClass:[PDWebToLocalPhotosTaskObject class]]) {
            _countLabel.badgeBackgroundColor = [PWColors getColor:PWColorsTypeTintLocalColor];
        }
        else if ([_taskObject isKindOfClass:[PDLocalToWebAlbumTaskObject class]]) {
            _countLabel.badgeBackgroundColor = [PWColors getColor:PWColorsTypeTintWebColor];
        }
        else if ([_taskObject isKindOfClass:[PDLocalToWebPhotosTaskObject class]]) {
            _countLabel.badgeBackgroundColor = [PWColors getColor:PWColorsTypeTintWebColor];
        }
    }
    else {
        _countLabel.badgeBorderWidth = 1.0f;
        _countLabel.badgeBackgroundColor = [UIColor whiteColor];
        
        if ([_taskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
            _countLabel.badgeBorderColor = [PWColors getColor:PWColorsTypeTintLocalColor];
            _countLabel.textColor = [PWColors getColor:PWColorsTypeTintLocalColor];
        }
        else if ([_taskObject isKindOfClass:[PDWebToLocalPhotosTaskObject class]]) {
            _countLabel.badgeBorderColor = [PWColors getColor:PWColorsTypeTintLocalColor];
            _countLabel.textColor = [PWColors getColor:PWColorsTypeTintLocalColor];
        }
        else if ([_taskObject isKindOfClass:[PDLocalToWebAlbumTaskObject class]]) {
            _countLabel.badgeBorderColor = [PWColors getColor:PWColorsTypeTintWebColor];
            _countLabel.textColor = [PWColors getColor:PWColorsTypeTintWebColor];
        }
        else if ([_taskObject isKindOfClass:[PDLocalToWebPhotosTaskObject class]]) {
            _countLabel.badgeBorderColor = [PWColors getColor:PWColorsTypeTintWebColor];
            _countLabel.textColor = [PWColors getColor:PWColorsTypeTintWebColor];
        }
    }
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
