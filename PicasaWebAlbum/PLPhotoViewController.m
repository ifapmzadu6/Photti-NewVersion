//
//  PLPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import MediaPlayer;

#import "PLPhotoViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import <SDImageCache.h>
#import "PWImageScrollView.h"
#import "PATabBarController.h"

@interface PLPhotoViewController ()

@property (strong, nonatomic) PWImageScrollView *imageScrollView;
@property (strong, nonatomic) UIButton *videoButton;

@property (strong, nonatomic) MPMoviePlayerController *moviePlayerController;
@property (strong, nonatomic) UIImageView *moviePlayerPlaceholderView;
@property (nonatomic) BOOL statusBarHiddenBeforePlay;

@end

@implementation PLPhotoViewController

- (id)initWithPhoto:(PLPhotoObject *)photo {
    self = [super init];
    if (self) {
        _photo = photo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageScrollView = [[PWImageScrollView alloc] initWithFrame:self.view.bounds];
    _imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    __weak typeof(self) wself = self;
    _imageScrollView.handleFirstZoomBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself loadFullResolutionImage];
    };
    [_imageScrollView setHandleSingleTapBlock:_handleSingleTapBlock];
    [self.view addSubview:_imageScrollView];
    
    [self loadThumbnailImage];
    
    if ([_photo.type isEqualToString:ALAssetTypeVideo]) {
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
        [_videoButton setImage:[PAIcons videoButtonIconWithColor:[UIColor colorWithWhite:1.0f alpha:0.8f] size:92.0f] forState:UIControlStateNormal];
        _videoButton.exclusiveTouch = YES;
        [self.view addSubview:_videoButton];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _videoButton.center = self.view.center;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIButton
- (void)videoButtonAction {
    NSURL *videoUrl = [NSURL URLWithString:_photo.url];
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
    _moviePlayerController.view.exclusiveTouch = YES;
    _moviePlayerController.view.userInteractionEnabled = YES;
    [self.tabBarController.view addSubview:_moviePlayerController.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStateChanged:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayerController];
    
    _moviePlayerPlaceholderView = [UIImageView new];
    _moviePlayerPlaceholderView.image = _imageScrollView.image;
    _moviePlayerPlaceholderView.contentMode = UIViewContentModeScaleAspectFit;
    _moviePlayerPlaceholderView.frame = _moviePlayerController.view.frame;
    _moviePlayerPlaceholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_moviePlayerController.view addSubview:_moviePlayerPlaceholderView];
    
    _moviePlayerController.view.alpha = 0.0f;
    [UIView animateWithDuration:0.3f animations:^{
        _moviePlayerController.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
        _statusBarHiddenBeforePlay = ![[UIApplication sharedApplication] isStatusBarHidden];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        
        [_moviePlayerController prepareToPlay];
    }];
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
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        }
        
		[UIView animateWithDuration:0.3f animations:^{
			_moviePlayerController.view.alpha = 0.0f;
		} completion:^(BOOL finished) {
			[_moviePlayerController.view removeFromSuperview];
			_moviePlayerController = nil;
		}];
    }
}

#pragma mark LoadImage
- (void)loadThumbnailImage {
    NSURL *url = [NSURL URLWithString:_photo.url];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (!asset) return;
            UIImage *image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself.imageScrollView setImage:image];
            });
            [sself loadScreenImage];
            
        } failureBlock:^(NSError *error) {
        }];
    });
}

- (void)loadScreenImage {
    NSURL *url = [NSURL URLWithString:_photo.url];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (!asset) return;
            
            UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself.imageScrollView setImage:image];
            });
        } failureBlock:^(NSError *error) {
        }];
    });
}

- (void)loadFullResolutionImage {
    NSURL *url = [NSURL URLWithString:_photo.url];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (!asset) return;
            
            UIImage *image = [PLPhotoViewController decodedFullResolutionImageFromAsset:asset];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself.imageScrollView setImage:image];
            });
        } failureBlock:^(NSError *error) {
        }];
    });
}

+ (UIImage *)decodedFullResolutionImageFromAsset:(ALAsset *)asset {
	CGImageRef imageRef = asset.defaultRepresentation.fullResolutionImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
	
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
		
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
	
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)imageSize.width,
                                                 (size_t)imageSize.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    CGColorSpaceRelease(colorSpace);
	
	CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
	
    CGContextRelease(context);
	
	UIImage *image = [UIImage imageWithCGImage:decompressedImageRef scale:1.0f orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
	CGImageRelease(decompressedImageRef);
	
    return image;
}

@end
