//
//  PWAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumViewCell.h"

@import CoreData;

#import <Reachability.h>
#import <SDImageCache.h>
#import <FLAnimatedImage.h>
#import <Reachability.h>
#import <SDWebImageDecoder.h>
#import "PWModelObject.h"
#import "PWPicasaAPI.h"
#import "PAColors.h"
#import "PAIcons.h"
#import "UIButton+HitEdgeInsets.h"
#import "NSURLResponse+methods.h"
#import "PAString.h"
#import "PAActivityIndicatorView.h"
#import "PAImageResize.h"

static int const kPWAlbumViewCellNumberOfImageView = 3;
static CGFloat const kPWAlbumViewCellShrinkedImageSize = 30;

@interface PWAlbumViewCell () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSArray *imageViews;
@property (strong, nonatomic) NSArray *imageViewBackgroundViews;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *numPhotosLabel;
@property (strong, nonatomic) UIView *overrayView;

@property (nonatomic) NSUInteger albumHash;

@property (strong, nonatomic) NSFetchRequest *request;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PWAlbumViewCell

- (id)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    self.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.contentView addSubview:_activityIndicatorView];
    
    NSMutableArray *imageViews = @[].mutableCopy;
    NSMutableArray *imageViewBackgroundViews = @[].mutableCopy;
    for (int i=0; i<kPWAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = [UIImageView new];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
        imageView.opaque = YES;
        [self.contentView insertSubview:imageView atIndex:0];
        
        UIView *backgroundView = [UIView new];
        backgroundView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
        backgroundView.opaque = YES;
        [self.contentView insertSubview:backgroundView belowSubview:imageView];
        
        [imageViews addObject:imageView];
        [imageViewBackgroundViews addObject:backgroundView];
    }
    _imageViews = imageViews;
    _imageViewBackgroundViews = imageViewBackgroundViews;
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:12.0f];
    _titleLabel.textColor = [PAColors getColor:kPAColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _numPhotosLabel = [UILabel new];
    _numPhotosLabel.font = [UIFont systemFontOfSize:10.0f];
    _numPhotosLabel.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
    [self.contentView addSubview:_numPhotosLabel];
    
    _overrayView = [UIView new];
    _overrayView.alpha = 0.0f;
    _overrayView.backgroundColor = self.backgroundColor;
    [self.contentView addSubview:_overrayView];
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    _request = [NSFetchRequest new];
    _request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
    _request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    _request.fetchLimit = 3;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    _overrayView.alpha = (selected) ? 0.5f : 0.0f;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    _overrayView.alpha = (highlighted) ? 0.5f : 0.0f;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = self.contentView.bounds;
    
    CGFloat delta = 4.0f;
    CGFloat imageSize = CGRectGetWidth(rect)-delta*2.0f;
    
    for (int i=0; i<kPWAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = _imageViews[i];
        imageView.frame = CGRectMake(delta*i+1, delta*((kPWAlbumViewCellNumberOfImageView-1)-i)+1, imageSize-2, imageSize-2);
        
        UIView *backgroundView = _imageViewBackgroundViews[i];
        backgroundView.frame = CGRectMake(delta*i, delta*((kPWAlbumViewCellNumberOfImageView-1)-i), imageSize, imageSize);
    }
    
    UIImageView *imageView = _imageViews.firstObject;
    _activityIndicatorView.center = imageView.center;
    
    _titleLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 27.0f, CGRectGetWidth(rect), 14.0f);
    _numPhotosLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 13.0f, CGRectGetWidth(rect), 12.0f);
    
    _overrayView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(rect), CGRectGetMaxY(imageView.frame));
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _titleLabel.text = nil;
    _numPhotosLabel.text = nil;
    for (int i=0; i<kPWAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = _imageViews[i];
        imageView.image = nil;
    }
    
    _fetchedResultsController = nil;
}

- (void)setAlbum:(PWAlbumObject *)album {
    _album = album;
    
    if (!album) {
        _albumHash = 0;
        return;
    };
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    _titleLabel.text = album.title;
    _numPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Items", nil), album.gphoto.numphotos];
    
    [PWCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
        _request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", _album.id_str];
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:_request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        
        NSUInteger numPhotos = _album.gphoto.numphotos.integerValue;
        if (numPhotos > 0) {
            NSUInteger fetchedCount = _fetchedResultsController.fetchedObjects.count;
            PWPhotoObject *firstPhotoObject = _fetchedResultsController.fetchedObjects.firstObject;
            if ((fetchedCount > 0) && (firstPhotoObject.sortIndex.integerValue == 1)) {
                for (int i=0; i<MIN(MIN(3, numPhotos), fetchedCount); i++) {
                    PWPhotoObject *photoObject = _fetchedResultsController.fetchedObjects[i];
                    if (photoObject.sortIndex.integerValue == i+1) {
                        NSString *urlString = photoObject.tag_thumbnail_url;
                        UIImageView *imageView = _imageViews[i];
                        BOOL isBehind = (i>=1) ? YES : NO;
                        [self loadThumbnailImage:urlString hash:hash imageView:imageView isShrink:isBehind isLowPriority:isBehind];
                    }
                }
            }
            else {
                NSString *urlString = album.tag_thumbnail_url;
                if (!urlString) return;
                UIImageView *imageView = _imageViews.firstObject;
                [self loadThumbnailImage:urlString hash:hash imageView:imageView isShrink:NO isLowPriority:NO];
            }
        }
        else {
            UIImageView *imageView = _imageViews.firstObject;
            UIImage *noPhotoImage = [UIImage imageNamed:@"icon_240"];
            imageView.image = noPhotoImage;
        }
    }];
}

- (void)loadThumbnailImage:(NSString *)urlString hash:(NSUInteger)hash imageView:(UIImageView *)imageView isShrink:(BOOL)isShrink isLowPriority:(BOOL)isLowPriority {
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isGifImage = [url.pathExtension isEqualToString:@"gif"];
    
    if (!isGifImage && !isShrink) {
        UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            imageView.image = memoryCachedImage;
            [_activityIndicatorView stopAnimating];
            
            return;
        }
    }
    
    [_activityIndicatorView startAnimating];
    
    dispatch_queue_t queue = nil;
    if (isLowPriority) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    }
    else {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(queue, ^{
        if (_albumHash != hash) return;
        SDImageCache *sharedImageCache = [SDImageCache sharedImageCache];
        if (isGifImage) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[sharedImageCache defaultCachePathForKey:urlString]]) {
                NSData *data = [self diskImageDataBySearchingAllPathsForKey:urlString];
                FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                if (animatedImage) {
                    UIImage *image = [UIImage decodedImageWithImage:animatedImage.posterImage];
                    if (isShrink) {
                        image = [PAImageResize resizeImage:image maxPixelSize:kPWAlbumViewCellShrinkedImageSize];
                    }
                    [self setImage:image hash:hash imageView:imageView];
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    if (isShrink) {
                        image = [PAImageResize resizeImage:image maxPixelSize:kPWAlbumViewCellShrinkedImageSize];
                    }
                    else {
                        image = [UIImage decodedImageWithImage:image];
                    }
                    [self setImage:image hash:hash imageView:imageView];
                }
                return;
            }
        }
        else {
            if (isShrink) {
                NSString *filePath = [sharedImageCache defaultCachePathForKey:urlString];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    UIImage *image = [PAImageResize imageFromFileUrl:[NSURL fileURLWithPath:filePath] maxPixelSize:kPWAlbumViewCellShrinkedImageSize];
                    [self setImage:image hash:hash imageView:imageView];
                    return;
                }
            }
            else {
                if ([sharedImageCache diskImageExistsWithKey:urlString]) {
                    UIImage *diskCachedImage = [sharedImageCache imageFromDiskCacheForKey:urlString];
                    [self setImage:diskCachedImage hash:hash imageView:imageView];
                    return;
                }
            }
        }
        
        if (![Reachability reachabilityForInternetConnection].isReachable) {
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
            if (sself.albumHash != hash) return;
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error || !response.isSuccess) {
                    [sself loadThumbnailImage:urlString hash:hash imageView:imageView isShrink:isShrink isLowPriority:isLowPriority];
                    return;
                }
                if (isGifImage) {
                    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                    UIImage *image = [UIImage decodedImageWithImage:animatedImage.posterImage];
                    if (data && urlString) {
                        [sself storeData:data key:urlString];
                    }
                    if (isShrink) {
                        image = [PAImageResize resizeImage:image maxPixelSize:kPWAlbumViewCellShrinkedImageSize];
                    }
                    [sself setImage:image hash:hash imageView:imageView];
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    if (image && urlString) {
                        [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                    }
                    if (isShrink) {
                        image = [PAImageResize resizeImage:image maxPixelSize:kPWAlbumViewCellShrinkedImageSize];
                    }
                    [sself setImage:image hash:hash imageView:imageView];
                }
            }];
            [task resume];
        }];
    });
}

- (void)setImage:(UIImage *)image hash:(NSUInteger)hash imageView:(UIImageView *)imageView {
    if (!image) return;
    if (_albumHash != hash) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_albumHash != hash) return;
        
        [_activityIndicatorView stopAnimating];
        imageView.image = image;
    });
}

#pragma mark DiscCache
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key {
    NSString *defaultPath = [[SDImageCache sharedImageCache] defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data) {
        return data;
    }
    return nil;
}

- (void)storeData:(NSData *)data key:(NSString *)key {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *diskCachePath = [paths[0] stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"];
    if (data) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        [[NSFileManager defaultManager] createFileAtPath:[[SDImageCache sharedImageCache] defaultCachePathForKey:key] contents:data attributes:nil];
    }
}

@end
