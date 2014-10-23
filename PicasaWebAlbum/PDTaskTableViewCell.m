//
//  PDTaskTableViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskTableViewCell.h"

#import "PAColors.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PLAssetsManager.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PDModelObject.h"
#import "PDCoreDataAPI.h"

#import "PAString.h"
#import "PAIcons.h"

#import <SDImageCache.h>
#import "SDWebImageDecoder.h"

#import "PWRoundedCornerBadgeLabel.h"

@interface PDTaskTableViewCell ()

@property (strong, nonatomic) UIImageView *thumbnailImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *taskTypeLabel;
@property (strong, nonatomic) PWRoundedCornerBadgeLabel *countLabel;

@property (strong, nonatomic) UIImageView *subThumbnailImageView;
@property (strong, nonatomic) UIImageView *subSubThumbnailImageView;
@property (strong, nonatomic) UIImageView *subArrowIcon;
@property (strong, nonatomic) UIImageView *subDestiantionThumbnailImageView;
@property (strong, nonatomic) UILabel *subTitleLabel;

@property (nonatomic) NSUInteger taskHash;

@property (nonatomic) BOOL isPhotosTask;

@end

@implementation PDTaskTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _thumbnailImageView = [UIImageView new];
        _thumbnailImageView.clipsToBounds = YES;
        _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailImageView.alpha = 0.0f;
        [self.contentView addSubview:_thumbnailImageView];
        
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont systemFontOfSize:15.0f];
        _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
        [self.contentView addSubview:_titleLabel];
        
        _taskTypeLabel = [UILabel new];
        _taskTypeLabel.font = [UIFont systemFontOfSize:10.0f];
        [self.contentView addSubview:_taskTypeLabel];
        
        _countLabel = [[PWRoundedCornerBadgeLabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:15.0f];
        [self.contentView addSubview:_countLabel];
        
        _subThumbnailImageView = [UIImageView new];
        _subThumbnailImageView.clipsToBounds = YES;
        _subThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _subThumbnailImageView.alpha = 0.0f;
        [self.contentView insertSubview:_subThumbnailImageView belowSubview:_thumbnailImageView];
        
        _subSubThumbnailImageView = [UIImageView new];
        _subSubThumbnailImageView.clipsToBounds = YES;
        _subSubThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _subSubThumbnailImageView.alpha = 1.0f;
        [self.contentView insertSubview:_subSubThumbnailImageView belowSubview:_thumbnailImageView];
        
        _subArrowIcon = [UIImageView new];
        [self.contentView addSubview:_subArrowIcon];
        
        _subDestiantionThumbnailImageView = [UIImageView new];
        _subDestiantionThumbnailImageView.clipsToBounds = YES;
        _subDestiantionThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _subDestiantionThumbnailImageView.alpha = 0.0f;
        [self.contentView addSubview:_subDestiantionThumbnailImageView];
        
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont systemFontOfSize:15.0f];
        _subTitleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
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
        
        _titleLabel.frame = CGRectMake(70.0f, 22.0f, (CGRectGetWidth(rect) / 2.0f - 10.0f) - 70.0f, 20.0f);
    }
    else {
        _thumbnailImageView.frame = CGRectMake(15.0f, 10.0f, rect.size.height - 20.0f, rect.size.height - 20.0f);
        
        _titleLabel.frame = CGRectMake(70.0f, 22.0f, 220.0f, 20.0f);
    }
    
    _taskTypeLabel.frame = CGRectMake(64.0f, 10.0f, 220.0f, 10.0f);
    
    CGSize countLabelSize = [_countLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _countLabel.frame = CGRectMake(CGRectGetMaxX(rect) - (countLabelSize.width + 12.0f) - 15.0f, 20.0f, countLabelSize.width + 12.0f, 20.0f);
    
    if (_isPhotosTask) {
        _subThumbnailImageView.frame = CGRectMake(15.0f + 2.0f, 10.0f + 2.0f, rect.size.height - 24.0f, rect.size.height - 24.0f);
        _subSubThumbnailImageView.frame = CGRectMake(15.0f + 4.0f, 10.0f + 4.0f, rect.size.height - 24.0f, rect.size.height - 24.0f);
        
        CGFloat arrowSize = ceilf(CGRectGetHeight(rect) / 4.0f);
        _subArrowIcon.frame = CGRectMake(CGRectGetWidth(rect) / 2.0f - 10.0f, CGRectGetHeight(rect) / 2.0f - arrowSize / 2.0f, arrowSize, arrowSize);
        _subArrowIcon.image = [[PAIcons arrowIconWithColor:[PAColors getColor:PAColorsTypeTintWebColor] size:CGSizeMake(arrowSize, arrowSize)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
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

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _titleLabel.text = nil;
    _thumbnailImageView.alpha = 0.0f;
    _subThumbnailImageView.alpha = 0.0f;
    _subSubThumbnailImageView.alpha = 0.0f;
    _subTitleLabel.text = nil;
    _subDestiantionThumbnailImageView.alpha = 0.0f;
    _subArrowIcon.hidden = YES;
}

#pragma mark Methods
- (void)setTaskObject:(PDTaskObject *)taskObject {
    _taskObject = taskObject;
    
    NSUInteger hash = taskObject.hash;
    _taskHash = hash;
    
    if (!taskObject) return;
    
    __weak typeof(self) wself = self;
    if (taskObject.type.integerValue == PDTaskObjectTypeWebAlbumToLocalAlbum) {
        _isPhotosTask = NO;
        
        NSString *id_str = taskObject.from_album_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Download", nil);
        _taskTypeLabel.textColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        _countLabel.text = [NSString stringWithFormat:@"%ld", (long)taskObject.photos.count];
        
        [PWCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
            request.fetchLimit = 1;
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count == 0) {
                return;
            }
            PWAlbumObject *albumObject = objects.firstObject;
            self.titleLabel.text = albumObject.title;
            
            [self loadThumbnailImageWithURLString:albumObject.tag_thumbnail_url hash:hash isSub:NO];
        }];
    }
    else if (taskObject.type.integerValue == PDTaskObjectTypePhotosToLocalAlbum) {
        _isPhotosTask = YES;
        
        NSString *destination_album_id_str = taskObject.to_album_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Download", nil);
        _taskTypeLabel.textColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        _countLabel.text = [NSString stringWithFormat:@"%ld", (long)taskObject.photos.count];
        _titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), taskObject.photos.count];
        _subArrowIcon.hidden = NO;
        _subArrowIcon.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        
        [taskObject.photos enumerateObjectsUsingBlock:^(PDWebPhotoObject *obj, NSUInteger idx, BOOL *stop) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (idx >= 3) {
                *stop = YES;
                return;
            }
            
            __block NSString *url = nil;
            if ([obj isKindOfClass:[PDLocalPhotoObject class]]) {
                NSString *photo_object_id_str = ((PDLocalPhotoObject *)obj).photo_object_id_str;
                [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", photo_object_id_str];
                    request.fetchLimit = 1;
                    NSError *error = nil;
                    NSArray *objects = [context executeFetchRequest:request error:&error];
                    if (objects.count == 0) return;
                    PLPhotoObject *photoObject = objects.firstObject;
                    url = photoObject.url;
                }];
                if (sself.taskHash != hash) return;
                if (!url) return;
                [sself loadThmbnailImageWithAssetURL:[NSURL URLWithString:url] hash:hash completion:^(UIImage *image) {
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
            }
            else if ([obj isKindOfClass:[PDWebPhotoObject class]]) {
                [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
                    NSString *photo_object_id_str = ((PDWebPhotoObject *)obj).photo_object_id_str;
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", photo_object_id_str];
                    request.fetchLimit = 1;
                    NSError *error = nil;
                    NSArray *objects = [context executeFetchRequest:request error:&error];
                    if (objects.count == 0) return;
                    PWPhotoObject *photoObject = objects.firstObject;
                    url = photoObject.tag_thumbnail_url;
                }];
                if (sself.taskHash != hash) return;
                if (!url) return;
                [sself loadThumbnailImageWithURLString:url hash:hash completion:^(UIImage *image) {
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
            }
            else if ([obj isKindOfClass:[PDLocalCopyPhotoObject class]]) {
                NSString *photo_object_id_str = ((PDLocalCopyPhotoObject *)obj).photo_object_id_str;
                [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", photo_object_id_str];
                    request.fetchLimit = 1;
                    NSError *error = nil;
                    NSArray *objects = [context executeFetchRequest:request error:&error];
                    if (objects.count == 0) return;
                    PLPhotoObject *photoObject = objects.firstObject;
                    url = photoObject.url;
                }];
                if (sself.taskHash != hash) return;
                if (!url) return;
                [sself loadThmbnailImageWithAssetURL:[NSURL URLWithString:url] hash:hash completion:^(UIImage *image) {
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
            }
        }];
        
        [PLCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", destination_album_id_str];
            request.fetchLimit = 1;
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count == 0) {
                return;
            }
            PLAlbumObject *albumObject = objects.firstObject;
            self.subTitleLabel.text = albumObject.name;
            
            PLPhotoObject *thumbnail = albumObject.thumbnail;
            if (!thumbnail && albumObject.photos.count > 0) {
                thumbnail = albumObject.photos.firstObject;
            }
            if (!thumbnail) return;
            NSURL *url = [NSURL URLWithString:thumbnail.url];
            [sself loadThmbnailImageWithAssetURL:url hash:hash completion:^(UIImage *image) {
                [sself setImage:image toImageView:sself.subDestiantionThumbnailImageView toAlpha:1.0f hash:hash];
            }];
        }];
    }
    else if (taskObject.type.integerValue == PDTaskObjectTypeLocalAlbumToWebAlbum) {
        _isPhotosTask = NO;
        
        NSString *id_str = taskObject.from_album_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Upload", nil);
        _taskTypeLabel.textColor = [PAColors getColor:PAColorsTypeTintWebColor];
        _countLabel.text = [NSString stringWithFormat:@"%ld", (long)taskObject.photos.count];
        
        [PLCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:@"PLAlbumObject" inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
            request.fetchLimit = 1;
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count == 0) return;
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
    else if (taskObject.type.integerValue == PDTaskObjectTypePhotosToWebAlbum) {
        _isPhotosTask = YES;
        
        NSString *destination_album_id_str = taskObject.to_album_id_str;
        
        _taskTypeLabel.text = NSLocalizedString(@"Upload", nil);
        _taskTypeLabel.textColor = [PAColors getColor:PAColorsTypeTintWebColor];
        _countLabel.text = [NSString stringWithFormat:@"%ld", (long)taskObject.photos.count];
        _titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), taskObject.photos.count];
        _subArrowIcon.hidden = NO;
        _subArrowIcon.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
        
        [taskObject.photos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (idx >= 3) {
                *stop = YES;
                return;
            }
            
            __block NSString *url = nil;
            if ([obj isKindOfClass:[PDLocalPhotoObject class]]) {
                NSString *photo_object_id_str = ((PDLocalPhotoObject *)obj).photo_object_id_str;
                [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", photo_object_id_str];
                    request.fetchLimit = 1;
                    NSError *error = nil;
                    NSArray *objects = [context executeFetchRequest:request error:&error];
                    if (objects.count == 0) return;
                    PLPhotoObject *photoObject = objects.firstObject;
                    url = photoObject.url;
                }];
                if (sself.taskHash != hash) return;
                if (!url) return;
                [sself loadThmbnailImageWithAssetURL:[NSURL URLWithString:url] hash:hash completion:^(UIImage *image) {
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
            }
            else {
                [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
                    NSString *photo_object_id_str = ((PDWebPhotoObject *)obj).photo_object_id_str;
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", photo_object_id_str];
                    request.fetchLimit = 1;
                    NSError *error = nil;
                    NSArray *objects = [context executeFetchRequest:request error:&error];
                    if (objects.count == 0) return;
                    PWPhotoObject *photoObject = objects.firstObject;
                    url = photoObject.tag_thumbnail_url;
                }];
                if (sself.taskHash != hash) return;
                if (!url) return;
                [sself loadThumbnailImageWithURLString:url hash:hash completion:^(UIImage *image) {
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
            }
        }];
        
        [PWCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", destination_album_id_str];
            request.fetchLimit = 1;
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count == 0) {
                return;
            }
            PWAlbumObject *albumObject = objects.firstObject;
            self.subTitleLabel.text = albumObject.title;
            
            [self loadThumbnailImageWithURLString:albumObject.tag_thumbnail_url hash:hash isSub:YES];
        }];
    }
    
    [self setNeedsLayout];
}

- (void)loadThumbnailImageWithURLString:(NSString *)urlString hash:(NSUInteger)hash isSub:(BOOL)isSub {
    if (!urlString) return;
    if (_taskHash != hash) return;
    
    UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        if (isSub) {
            _subDestiantionThumbnailImageView.image = memoryCachedImage;
            _subDestiantionThumbnailImageView.alpha = 1.0f;
        }
        else {
            _thumbnailImageView.image = memoryCachedImage;
            _thumbnailImageView.alpha = 1.0f;
        }
        
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_taskHash != hash) return;
        
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:urlString]) {
            UIImage *diskCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
            if (isSub) {
                [self setImage:diskCachedImage toImageView:_subDestiantionThumbnailImageView toAlpha:1.0f hash:hash];
            }
            else {
                [self setImage:diskCachedImage toImageView:_thumbnailImageView toAlpha:1.0f hash:hash];
            }
            
            return;
        }
        
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                return;
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error) return;
                
                UIImage *image = [UIImage imageWithData:data];
                if (isSub) {
                    [sself setImage:image toImageView:sself.subDestiantionThumbnailImageView toAlpha:1.0f hash:hash];
                }
                else {
                    [sself setImage:image toImageView:sself.thumbnailImageView toAlpha:1.0f hash:hash];
                }
                
                if (image && urlString) {
                    [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                }
            }];
            [task resume];
        }];
    });
}

- (void)loadThumbnailImageWithURLString:(NSString *)urlString hash:(NSUInteger)hash completion:(void (^)(UIImage *))completion {
    if (!urlString) return;
    if (_taskHash != hash) return;
    
    UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        if (completion) {
            completion(memoryCachedImage);
        }
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_taskHash != hash) return;
        
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:urlString]) {
            UIImage *diskCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
            if (completion) {
                completion(diskCachedImage);
            }
            return;
        }
        
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                return;
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.taskHash != hash) return;
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {                
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error) return;
                
                UIImage *image = [UIImage imageWithData:data];
                if (completion) {
                    completion([UIImage decodedImageWithImage:image]);
                }
                
                if (image && urlString) {
                    [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                }
            }];
            [task resume];
        }];
    });
}

- (void)loadThmbnailImageWithAssetURL:(NSURL *)assetUrl hash:(NSUInteger)hash completion:(void (^)(UIImage *image))completion {
    if (!assetUrl) return;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PLAssetsManager sharedLibrary] assetForURL:assetUrl resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
            if (completion) {
                completion(image);
            }
        } failureBlock:^(NSError *error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }];
    });
}

- (void)setImage:(UIImage *)image toImageView:(UIImageView *)imageView toAlpha:(CGFloat)alpha hash:(NSUInteger)hash {
    if (!image) return;
    if (_taskHash != hash) return;
    
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
        
        if (_taskObject.type.integerValue == PDTaskObjectTypeWebAlbumToLocalAlbum) {
            _countLabel.badgeBackgroundColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        }
        else if (_taskObject.type.integerValue == PDTaskObjectTypePhotosToLocalAlbum) {
            _countLabel.badgeBackgroundColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        }
        else if (_taskObject.type.integerValue == PDTaskObjectTypeLocalAlbumToWebAlbum) {
            _countLabel.badgeBackgroundColor = [PAColors getColor:PAColorsTypeTintWebColor];
        }
        else if (_taskObject.type.integerValue == PDTaskObjectTypePhotosToWebAlbum) {
            _countLabel.badgeBackgroundColor = [PAColors getColor:PAColorsTypeTintWebColor];
        }
    }
    else {
        _countLabel.badgeBorderWidth = 1.0f;
        _countLabel.badgeBackgroundColor = [UIColor whiteColor];
        
        if (_taskObject.type.integerValue == PDTaskObjectTypeWebAlbumToLocalAlbum) {
            _countLabel.badgeBorderColor = [PAColors getColor:PAColorsTypeTintLocalColor];
            _countLabel.textColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        }
        else if (_taskObject.type.integerValue == PDTaskObjectTypePhotosToLocalAlbum) {
            _countLabel.badgeBorderColor = [PAColors getColor:PAColorsTypeTintLocalColor];
            _countLabel.textColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        }
        else if (_taskObject.type.integerValue == PDTaskObjectTypeLocalAlbumToWebAlbum) {
            _countLabel.badgeBorderColor = [PAColors getColor:PAColorsTypeTintWebColor];
            _countLabel.textColor = [PAColors getColor:PAColorsTypeTintWebColor];
        }
        else if (_taskObject.type.integerValue == PDTaskObjectTypePhotosToWebAlbum) {
            _countLabel.badgeBorderColor = [PAColors getColor:PAColorsTypeTintWebColor];
            _countLabel.textColor = [PAColors getColor:PAColorsTypeTintWebColor];
        }
    }
}

@end
