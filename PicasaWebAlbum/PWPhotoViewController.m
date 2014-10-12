//
//  PWPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import MediaPlayer;

#import "PWPhotoViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PWPicasaAPI.h"
#import <PAImageScrollView.h>
#import "PATabBarController.h"
#import "PANetworkActivityIndicator.h"
#import "PAActivityIndicatorView.h"
#import <Reachability.h>
#import <FLAnimatedImage.h>
#import <FLAnimatedImageView.h>
#import <SDImageCache.h>

@interface PWPhotoViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) id placeholder;
@property (strong, nonatomic) NSCache *cache;

@property (strong, nonatomic) PAImageScrollView *imageScrollView;
@property (strong, nonatomic) UIButton *videoButton;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@property (weak, nonatomic) NSURLSessionDataTask *task;
@property (weak, nonatomic) NSURLSessionDataTask *highResolutionTask;

@property (strong, nonatomic) MPMoviePlayerController *moviePlayerController;
@property (strong, nonatomic) UIImageView *moviePlayerPlaceholderView;
@property (nonatomic) BOOL statusBarHiddenBeforePlay;

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation PWPhotoViewController

- (id)initWithPhoto:(PWPhotoObject *)photo placeholder:(id)placeholder cache:(NSCache *)cache {
    self = [self init];
    if (self) {
        _photo = photo;
        _placeholder = placeholder;
        _cache = cache;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageScrollView = [[PAImageScrollView alloc] initWithFrame:self.view.bounds];
    _imageScrollView.imageViewClass = FLAnimatedImageView.class;
    _imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_imageScrollView];
    
    if (_placeholder) {
        if ([_placeholder isKindOfClass:[FLAnimatedImage class]]) {
            FLAnimatedImage *animatedImage = _placeholder;
            _imageScrollView.image = animatedImage.posterImage;
            FLAnimatedImageView *imageView = (FLAnimatedImageView *)_imageScrollView.imageView;
            imageView.animatedImage = animatedImage;
        }
        else {
            _imageScrollView.image = _placeholder;
            
            [self loadScreenResolutionImage];
        }
        _placeholder = nil;
    }
    else {
        _indicatorView = [PAActivityIndicatorView new];
        _indicatorView.center = self.view.center;
        [self.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
        
        [self loadImage];
    }
    
    if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
        _imageScrollView.isDisableZoom = YES;
        
        _videoButton = [UIButton new];
        [_videoButton addTarget:self action:@selector(videoButtonAction) forControlEvents:UIControlEventTouchUpInside];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _videoButton.frame = CGRectMake(0.0f, 0.0f, 92.0f, 92.0f);
            [_videoButton setImage:[PAIcons videoButtonIconWithColor:[UIColor colorWithWhite:1.0f alpha:1.0f] size:92.0f] forState:UIControlStateNormal];
        }
        else {
            _videoButton.frame = CGRectMake(0.0f, 0.0f, 170.0f, 170.0f);
            [_videoButton setImage:[PAIcons videoButtonIconWithColor:[UIColor colorWithWhite:1.0f alpha:1.0f] size:170.0f] forState:UIControlStateNormal];
        }
        _videoButton.exclusiveTouch = YES;
        [self.view addSubview:_videoButton];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
    
    _imageScrollView.didSingleTapBlock = _didSingleTapBlock;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _imageScrollView.didSingleTapBlock = nil;
}

- (void)dealloc {
    NSURLSessionDataTask *task = _task;
    if (task) {
        [task cancel];
    }
    task = _highResolutionTask;
    if (task) {
        [task cancel];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _videoButton.center = self.view.center;
}

#pragma mark UIButton
- (void)videoButtonAction {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not connected to network", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
        return;
    }
    
    NSArray *contents = [_photo.media.content.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @"video/mpeg4"]];
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = NSLocalizedString(@"Video Quality", nil);
    for (PWPhotoMediaContentObject *content in contents.reverseObjectEnumerator) {
        NSInteger width = content.width.integerValue;
        NSInteger height = content.height.integerValue;
        NSString *title = [NSString stringWithFormat:@"%ldP", width >= height ? (long)width : (long)height];
        [alertView addButtonWithTitle:title];
    }
    [alertView addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alertView setCancelButtonIndex:alertView.numberOfButtons - 1];
    [alertView show];
}

#pragma mark MPMoviePlayerPlayback
- (void)moviePlaybackStateChanged:(NSNotification *)notification {
    if (_moviePlayerController.playbackState == MPMusicPlaybackStatePlaying) {
        if (_moviePlayerPlaceholderView) {
            _moviePlayerController.controlStyle = MPMovieControlStyleFullscreen;
            
            [_moviePlayerPlaceholderView removeFromSuperview];
            _moviePlayerPlaceholderView = nil;
        }
    }
}

- (void)moviePlaybackDidFinish:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSUInteger reason = [[userInfo objectForKey:@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"] intValue];
    if (reason == MPMovieFinishReasonUserExited || reason == MPMovieFinishReasonPlaybackEnded) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayerController];
        
        if (_statusBarHiddenBeforePlay) {
            PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
            [tabBarController setIsStatusBarHidden:NO animated:NO];
        }
        
        [UIView animateWithDuration:0.3f animations:^{
            _moviePlayerController.view.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [_moviePlayerController.view removeFromSuperview];
            _moviePlayerController = nil;
        }];
    }
}

#pragma mark Video
- (void)playVideoWithUrl:(NSURL *)videoUrl {
    _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:videoUrl];
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        _moviePlayerController.view.frame = CGRectMake(0.0f, 0.0f, size.height, size.width);
    }
    else {
        _moviePlayerController.view.frame = [UIScreen mainScreen].bounds;
    }
    _moviePlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _moviePlayerController.controlStyle = MPMovieControlStyleNone;
    _moviePlayerController.fullscreen = YES;
    _moviePlayerController.scalingMode = MPMovieScalingModeAspectFit;
    _moviePlayerController.shouldAutoplay = YES;
    [self.tabBarController.view addSubview:_moviePlayerController.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStateChanged:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayerController];
    
    _moviePlayerPlaceholderView = [UIImageView new];
    _moviePlayerPlaceholderView.image = _imageScrollView.image;
    _moviePlayerPlaceholderView.contentMode = UIViewContentModeScaleAspectFit;
    _moviePlayerPlaceholderView.frame = _moviePlayerController.view.frame;
    _moviePlayerPlaceholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_moviePlayerController.view addSubview:_moviePlayerPlaceholderView];
    
    UIImageView *videoButtonImageView = [UIImageView new];
    videoButtonImageView.image = [PAIcons videoButtonIconWithColor:[UIColor colorWithWhite:1.0f alpha:1.0f] size:92.0f];
    videoButtonImageView.frame = CGRectMake(0.0f, 0.0f, 92.0f, 92.0f);
    videoButtonImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    videoButtonImageView.center = _moviePlayerPlaceholderView.center;
    [_moviePlayerPlaceholderView addSubview:videoButtonImageView];
    
    PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
    indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    indicator.center = _moviePlayerPlaceholderView.center;
    [_moviePlayerPlaceholderView addSubview:indicator];
    [indicator startAnimating];
    
    _moviePlayerController.view.alpha = 0.0f;
    [UIView animateWithDuration:0.3f animations:^{
        _moviePlayerController.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
        _statusBarHiddenBeforePlay = ![[UIApplication sharedApplication] isStatusBarHidden];
        PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
        [tabBarController setIsStatusBarHidden:YES animated:NO];
        
        [_moviePlayerController prepareToPlay];
    }];
}

#pragma mark LoadImage
- (void)loadImage {
    NSString *urlString = _photo.tag_thumbnail_url;
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL isGifImage = [url.pathExtension isEqualToString:@"gif"];
    
    if (!isGifImage) {
        UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            [_indicatorView stopAnimating];
            [_imageScrollView setImage:memoryCachedImage];
            
            [self loadScreenResolutionImage];
            
            return;
        }
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        SDImageCache *sharedImageCache = [SDImageCache sharedImageCache];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[sharedImageCache defaultCachePathForKey:urlString]]) {
            if (isGifImage) {
                NSData *data = [self diskImageDataBySearchingAllPathsForKey:urlString];
                FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself.indicatorView stopAnimating];
                    sself.imageScrollView.image = animatedImage.posterImage;
                    FLAnimatedImageView *imageView = (FLAnimatedImageView *)sself.imageScrollView.imageView;
                    imageView.animatedImage = animatedImage;
                });
            }
            else {
                UIImage *diskCachedImage = [sharedImageCache imageFromDiskCacheForKey:urlString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself.indicatorView stopAnimating];
                    [sself.imageScrollView setImage:diskCachedImage];
                    
                    [sself loadScreenResolutionImage];
                });
            }
            return;
        }
        
        [PANetworkActivityIndicator increment];
        
        [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                [PANetworkActivityIndicator decrement];
                return;
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                [PANetworkActivityIndicator decrement];
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                    return;
                }
                typeof(wself) sself = wself;
                if (!sself) return;
                if (isGifImage) {
                    FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sself.indicatorView stopAnimating];
                        sself.imageScrollView.image = animatedImage.posterImage;
                        FLAnimatedImageView *imageView = (FLAnimatedImageView *)sself.imageScrollView.imageView;
                        imageView.animatedImage = animatedImage;
                    });
                    
                    if (data && urlString) {
                        [sself storeData:data key:urlString];
                    }
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    if (!image) return;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sself.indicatorView stopAnimating];
                        [sself.imageScrollView setImage:image];
                        
                        [sself loadScreenResolutionImage];
                    });
                    
                    if (image && urlString) {
                        [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                    }
                }
            }];
            [task resume];
            sself.task = task;
        }];
    });
}

- (void)loadScreenResolutionImage {
    NSString *urlString = _photo.tag_screenimage_url;
    if (!urlString) return;
    
    UIImage *memoryCache = [_cache objectForKey:urlString];
    if (memoryCache) {
        [_indicatorView stopAnimating];
        [_imageScrollView setImage:memoryCache];
        
        return;
    }
    
    [PANetworkActivityIndicator increment];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            [PANetworkActivityIndicator decrement];
            return;
        }
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [PANetworkActivityIndicator decrement];
            if (error) {
                return;
            }
            
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself.imageScrollView setImage:image];
            });
            
            if (image && urlString) {
                [sself.cache setObject:image forKey:urlString];
            }
        }];
        [task resume];
        sself.highResolutionTask = task;
    }];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        
    }
    else  {
        NSArray *contents = [_photo.media.content.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @"video/mpeg4"]];
        PWPhotoMediaContentObject *content = contents[contents.count - 1 - buttonIndex];
        
        [self playVideoWithUrl:[NSURL URLWithString:content.url]];
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
