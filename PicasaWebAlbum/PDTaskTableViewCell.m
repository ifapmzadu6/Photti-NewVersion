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

#import "PWString.h"
#import "PWIcons.h"

#import "SDImageCache.h"

#import "PWLoundedCornerBadgeLabel.h"

@interface PDTaskTableViewCell ()

@property (strong, nonatomic) UIImageView *thumbnailImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *taskTypeLabel;
@property (strong, nonatomic) PWLoundedCornerBadgeLabel *countLabel;

@property (strong, nonatomic) UIImageView *subThumbnailImageView;
@property (strong, nonatomic) UIImageView *subSubThumbnailImageView;
@property (strong, nonatomic) UIImageView *subArrowIcon;
@property (strong, nonatomic) UIImageView *subDestiantionThumbnailImageView;
@property (strong, nonatomic) UILabel *subTitleLabel;

@property (nonatomic) NSUInteger taskHash;
@property (weak, nonatomic) NSURLSessionDataTask *task;

@property (nonatomic) BOOL isPhotosTask;

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
        
        _subThumbnailImageView = [[UIImageView alloc] init];
        _subThumbnailImageView.clipsToBounds = YES;
        _subThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _subThumbnailImageView.alpha = 0.0f;
        [self.contentView insertSubview:_subThumbnailImageView belowSubview:_thumbnailImageView];
        
        _subSubThumbnailImageView = [[UIImageView alloc] init];
        _subSubThumbnailImageView.clipsToBounds = YES;
        _subSubThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _subSubThumbnailImageView.alpha = 1.0f;
        [self.contentView insertSubview:_subSubThumbnailImageView belowSubview:_thumbnailImageView];
        
        _subArrowIcon = [[UIImageView alloc] init];
        [self.contentView addSubview:_subArrowIcon];
        
        _subDestiantionThumbnailImageView = [[UIImageView alloc] init];
        _subDestiantionThumbnailImageView.clipsToBounds = YES;
        _subDestiantionThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _subDestiantionThumbnailImageView.alpha = 0.0f;
        [self.contentView addSubview:_subDestiantionThumbnailImageView];
        
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.font = [UIFont systemFontOfSize:15.0f];
        _subTitleLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
        _subTitleLabel.minimumScaleFactor = 0.75f;
        _subTitleLabel.adjustsFontSizeToFitWidth = YES;
        _subTitleLabel.numberOfLines = 2;
        [self.contentView addSubview:_subTitleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    if (_isPhotosTask) {
        _thumbnailImageView.frame = CGRectMake(15.0f, 10.0f, rect.size.height - 24.0f, rect.size.height - 24.0f);
        
        _titleLabel.frame = CGRectMake(70.0f, 22.0f, (CGRectGetWidth(rect) / 2.0f - 10.0f) - 70.0f, 15.0f);
    }
    else {
        _thumbnailImageView.frame = CGRectMake(15.0f, 10.0f, rect.size.height - 20.0f, rect.size.height - 20.0f);
        
        _titleLabel.frame = CGRectMake(70.0f, 22.0f, 220.0f, 15.0f);
    }
    
    _taskTypeLabel.frame = CGRectMake(65.0f, 10.0f, 220.0f, 10.0f);
    
    CGSize countLabelSize = [_countLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _countLabel.frame = CGRectMake(CGRectGetMaxX(rect) - (countLabelSize.width + 20.0f), 20.0f, countLabelSize.width + 16.0f, 20.0f);
    
    if (_isPhotosTask) {
        _subThumbnailImageView.frame = CGRectMake(15.0f + 2.0f, 10.0f + 2.0f, rect.size.height - 24.0f, rect.size.height - 24.0f);
        _subSubThumbnailImageView.frame = CGRectMake(15.0f + 4.0f, 10.0f + 4.0f, rect.size.height - 24.0f, rect.size.height - 24.0f);
        
        CGFloat arrowSize = ceilf(CGRectGetHeight(rect) / 3.0f);
        _subArrowIcon.frame = CGRectMake(CGRectGetWidth(rect) / 2.0f - 10.0f, CGRectGetHeight(rect) / 2.0f - arrowSize / 2.0f, arrowSize, arrowSize);
        _subArrowIcon.image = [PWIcons arrowIconWithColor:[PWColors getColor:PWColorsTypeTintWebColor] size:CGSizeMake(arrowSize, arrowSize)];
        
        _subDestiantionThumbnailImageView.frame = CGRectMake(CGRectGetMaxX(_subArrowIcon.frame) + 6.0f, 15.0f, rect.size.height - 30.0f, rect.size.height - 30.0f);
        
        _subTitleLabel.frame = CGRectMake(CGRectGetMaxX(_subDestiantionThumbnailImageView.frame) + 4.0f, 15.0f, (CGRectGetMaxX(rect) - (countLabelSize.width + 20.0f)) - (CGRectGetMaxX(_subDestiantionThumbnailImageView.frame) + 4.0f), 30.0f);
        _subTitleLabel.text = _subTitleLabel.text;
    }
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
    _subThumbnailImageView.alpha = 0.0f;
    _subSubThumbnailImageView.alpha = 0.0f;
    _subTitleLabel.text = nil;
    _subDestiantionThumbnailImageView.alpha = 0.0f;
    _subArrowIcon.hidden = YES;
    
    __weak typeof(self) wself = self;
    if ([taskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
        _isPhotosTask = NO;
        
        PDWebToLocalAlbumTaskObject *webToLocalAlbumTaskObject = (PDWebToLocalAlbumTaskObject *)taskObject;
        NSString *id_str = webToLocalAlbumTaskObject.album_object_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Download", nil);
        _taskTypeLabel.textColor = [PWColors getColor:PWColorsTypeTintLocalColor];
        _countLabel.text = [NSString stringWithFormat:@"%d", taskObject.photos.count];
        
        [PWCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
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
            
            [sself loadThumbnailImageWithURLString:albumObject.tag_thumbnail_url hash:hash isSub:NO];
        }];
    }
    else if ([taskObject isKindOfClass:[PDWebToLocalPhotosTaskObject class]]) {
        _isPhotosTask = YES;
        
        PDWebToLocalPhotosTaskObject *webToLocalPhotosTaskObject = (PDWebToLocalPhotosTaskObject *)taskObject;
        
        _taskTypeLabel.text = NSLocalizedString(@"Download", nil);
        _taskTypeLabel.textColor = [PWColors getColor:PWColorsTypeTintLocalColor];
        _countLabel.text = [NSString stringWithFormat:@"%d", taskObject.photos.count];
        
        
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebAlbumTaskObject class]]) {
        _isPhotosTask = NO;
        
        PDLocalToWebAlbumTaskObject *localToWebAlbumTaskObject = (PDLocalToWebAlbumTaskObject *)taskObject;
        NSString *id_str = localToWebAlbumTaskObject.album_object_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Upload", nil);
        _taskTypeLabel.textColor = [PWColors getColor:PWColorsTypeTintWebColor];
        _countLabel.text = [NSString stringWithFormat:@"%d", taskObject.photos.count];
        
        [PLCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
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
                if (sself.taskHash != hash) return;
                sself.titleLabel.text = albumObject.name;
            });
            
            PLPhotoObject *thumbnail = albumObject.thumbnail;
            if (!thumbnail && albumObject.photos.count > 0) {
                thumbnail = albumObject.photos.firstObject;
            }
            if (!thumbnail) return;
            NSURL *url = [NSURL URLWithString:thumbnail.url];
            [sself loadThmbnailImageWithAssetURL:url hash:hash completion:^(UIImage *image) {
                [sself setImage:image toImageView:sself.thumbnailImageView toAlpha:1.0f hash:hash];
            }];
        }];
    }
    else if ([taskObject isKindOfClass:[PDLocalToWebPhotosTaskObject class]]) {
        _isPhotosTask = YES;
        
        PDLocalToWebPhotosTaskObject *localToWebPhotosTaskObject = (PDLocalToWebPhotosTaskObject *)taskObject;
        NSString *destination_album_id_str = localToWebPhotosTaskObject.destination_album_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Upload", nil);
        _taskTypeLabel.textColor = [PWColors getColor:PWColorsTypeTintWebColor];
        _countLabel.text = [NSString stringWithFormat:@"%d", taskObject.photos.count];
        _titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), taskObject.photos.count];
        _subArrowIcon.hidden = NO;
        
        [localToWebPhotosTaskObject.photos enumerateObjectsUsingBlock:^(PDLocalPhotoObject *obj, NSUInteger idx, BOOL *stop) {
            if (idx >= 3) {
                *stop = YES;
                return;
            }
            
            [PLCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.taskHash != hash) return;
                
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", obj.photo_object_id_str];
                NSError *error = nil;
                NSArray *objects = [context executeFetchRequest:request error:&error];
                if (objects.count == 0) {
                    return;
                }
                PLPhotoObject *photoObject = objects.firstObject;
                
                [sself loadThmbnailImageWithAssetURL:[NSURL URLWithString:photoObject.url] hash:hash completion:^(UIImage *image) {
                    if (idx == 0) {
                        [sself setImage:image toImageView:sself.thumbnailImageView toAlpha:1.0f hash:hash];
                    }
                    else if (idx == 1) {
                        [sself setImage:image toImageView:sself.subThumbnailImageView toAlpha:0.667f hash:hash];
                    }
                    else if (idx == 2) {
                        [sself setImage:image toImageView:sself.subSubThumbnailImageView toAlpha:0.333f hash:hash];
                    }
                }];
            }];
        }];
        
        [PWCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", destination_album_id_str];
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
                sself.subTitleLabel.text = albumObject.title;
            });
            
            [sself loadThumbnailImageWithURLString:albumObject.tag_thumbnail_url hash:hash isSub:YES];
        }];
    }
    
    [self setNeedsLayout];
}

- (void)loadThumbnailImageWithURLString:(NSString *)urlString hash:(NSUInteger)hash isSub:(BOOL)isSub {
    if (!urlString) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            if (isSub) {
                [self setImage:memoryCachedImage toImageView:self.subDestiantionThumbnailImageView toAlpha:1.0f hash:hash];
            }
            else {
                [self setImage:memoryCachedImage toImageView:self.thumbnailImageView toAlpha:1.0f hash:hash];
            }
            
            return;
        }
        
        if ([imageCache diskImageExistsWithKey:urlString]) {
            if (_taskHash != hash) return;
            
            UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
            if (isSub) {
                [self setImage:diskCachedImage toImageView:self.subDestiantionThumbnailImageView toAlpha:1.0f hash:hash];
            }
            else {
                [self setImage:diskCachedImage toImageView:self.thumbnailImageView toAlpha:1.0f hash:hash];
            }
            
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
                    if (isSub) {
                        [sself setImage:image toImageView:sself.subDestiantionThumbnailImageView toAlpha:1.0f hash:hash];
                    }
                    else {
                        [sself setImage:image toImageView:sself.thumbnailImageView toAlpha:1.0f hash:hash];
                    }
                }
                
                SDImageCache *imageCache = [SDImageCache sharedImageCache];
                [imageCache storeImage:image forKey:urlString toDisk:YES];
            }];
            [task resume];
            
            sself.task = task;
        }];
    });
}

- (void)loadThmbnailImageWithAssetURL:(NSURL *)assetUrl hash:(NSUInteger)hash completion:(void (^)(UIImage *image))completion {
    if (!assetUrl) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PLAssetsManager assetForURL:assetUrl resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
            if (completion) {
                completion(image);
            }
        } failureBlock:^(NSError *error) {
            
        }];
    });
}

- (void)setImage:(UIImage *)image toImageView:(UIImageView *)imageView toAlpha:(CGFloat)alpha hash:(NSUInteger)hash {
    if (_taskHash != hash) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.taskHash != hash) return;
        
        imageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            imageView.alpha = alpha;
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
