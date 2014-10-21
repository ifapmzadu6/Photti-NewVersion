//
//  PWAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumViewCell.h"

@import CoreData;

#import "PWModelObject.h"
#import "PWPicasaAPI.h"
#import "PAColors.h"
#import <Reachability.h>
#import <SDImageCache.h>
#import "SDWebImageDecoder.h"
#import "PAIcons.h"
#import "UIButton+HitEdgeInsets.h"
#import <Reachability.h>
#import "NSURLResponse+methods.h"
#import "PAString.h"
#import "PAActivityIndicatorView.h"
#import <FLAnimatedImage.h>

static int const kPWAlbumViewCellNumberOfImageView = 3;

@interface PWAlbumViewCell () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSArray *imageViews;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *numPhotosLabel;
@property (strong, nonatomic) UIView *overrayView;

@property (nonatomic) NSUInteger albumHash;

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
    self.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.contentView addSubview:_activityIndicatorView];
    
    NSMutableArray *imageViews = @[].mutableCopy;
    for (int i=0; i<kPWAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = [UIImageView new];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.tintColor = [[PAColors getColor:PAColorsTypeTintWebColor] colorWithAlphaComponent:0.4f];
        imageView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
        imageView.layer.borderWidth = 1.0f;
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.contentView insertSubview:imageView atIndex:0];
        [imageViews addObject:imageView];
    }
    _imageViews = imageViews;
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:12.0f];
    _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _numPhotosLabel = [UILabel new];
    _numPhotosLabel.font = [UIFont systemFontOfSize:10.0f];
    _numPhotosLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    [self.contentView addSubview:_numPhotosLabel];
    
    _overrayView = [UIView new];
    _overrayView.alpha = 0.0f;
    _overrayView.backgroundColor = self.backgroundColor;
    [self.contentView addSubview:_overrayView];
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerAction:)];
    [self addGestureRecognizer:gestureRecognizer];
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
        imageView.frame = CGRectMake(delta*i, delta*(kPWAlbumViewCellNumberOfImageView-i), imageSize, imageSize);
    }
    
    UIImageView *imageView = _imageViews.firstObject;
    _activityIndicatorView.center = imageView.center;
    
    _titleLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 26.0f, CGRectGetWidth(rect), 14.0f);
    _numPhotosLabel.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - 12.0f, CGRectGetWidth(rect), 12.0f);
    
    _overrayView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(rect), CGRectGetMaxY(imageView.frame));
//    _checkMarkImageView.frame = CGRectMake(CGRectGetWidth(rect) - 32.0f, CGRectGetWidth(rect) - 32.0f, 28.0f, 28.0f);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _titleLabel.text = nil;
    _numPhotosLabel.text = nil;
    for (int i=0; i<kPWAlbumViewCellNumberOfImageView; i++) {
        UIImageView *imageView = _imageViews[i];
        imageView.image = nil;
    }
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
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", _album.id_str];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    request.fetchLimit = 3;
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
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
                    [self loadThumbnailImage:urlString hash:hash imageView:imageView];
                }
            }
        }
        else {
            NSString *urlString = album.tag_thumbnail_url;
            if (!urlString) return;
            UIImageView *imageView = _imageViews.firstObject;
            [self loadThumbnailImage:urlString hash:hash imageView:imageView];
        }
    }
    else {
        UIImageView *imageView = _imageViews.firstObject;
        UIImage *noPhotoImage = [UIImage imageNamed:@"icon_240"];
        imageView.image = noPhotoImage;
    }
}

- (void)loadThumbnailImage:(NSString *)urlString hash:(NSUInteger)hash imageView:(UIImageView *)imageView {
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isGifImage = [url.pathExtension isEqualToString:@"gif"];
    
    if (!isGifImage) {
        UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            imageView.image = memoryCachedImage;
            [_activityIndicatorView stopAnimating];
            
            return;
        }
    }
    
    [_activityIndicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_albumHash != hash) return;
        SDImageCache *sharedImageCache = [SDImageCache sharedImageCache];
        if (isGifImage) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[sharedImageCache defaultCachePathForKey:urlString]]) {
                NSData *data = [self diskImageDataBySearchingAllPathsForKey:urlString];
                FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                if (animatedImage) {
                    [self setImage:[UIImage decodedImageWithImage:animatedImage.posterImage] hash:hash imageView:imageView];
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    [self setImage:[UIImage decodedImageWithImage:image] hash:hash imageView:imageView];
                }
                return;
            }
        }
        else {
            if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:urlString]) {
                UIImage *diskCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
                [self setImage:diskCachedImage hash:hash imageView:imageView];
                return;
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
                    [sself loadThumbnailImage:urlString hash:hash imageView:imageView];
                    return;
                }
                if (isGifImage) {
                    FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                    [sself setImage:[UIImage decodedImageWithImage:animatedImage.posterImage] hash:hash imageView:imageView];
                    if (data && urlString) {
                        [sself storeData:data key:urlString];
                    }
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    [sself setImage:[UIImage decodedImageWithImage:image] hash:hash imageView:imageView];
                    if (image && urlString) {
                        [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                    }
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

#pragma mark Action
- (void)actionButtonAction {
    if (_actionButtonActionBlock) {
        _actionButtonActionBlock(_album);
    }
}

- (void)longPressGestureRecognizerAction:(UILongPressGestureRecognizer *)sender {
    if([sender state] == UIGestureRecognizerStateBegan){
        if (_actionButtonActionBlock) {
            _actionButtonActionBlock(_album);
        }
    }
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
