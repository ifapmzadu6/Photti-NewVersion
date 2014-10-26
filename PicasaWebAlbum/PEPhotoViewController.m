//
//  PHPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoViewController.h"

@import MediaPlayer;

#import <PAImageScrollView.h>
#import "PAIcons.h"
#import "PATabBarController.h"

@interface PEPhotoViewController ()

@property (strong, nonatomic) PAImageScrollView *imageScrollView;
@property (strong, nonatomic) UIButton *videoButton;

@property (strong, nonatomic) MPMoviePlayerController *moviePlayerController;
@property (strong, nonatomic) UIImageView *moviePlayerPlaceholderView;
@property (nonatomic) BOOL statusBarHiddenBeforePlay;

@end

@implementation PEPhotoViewController

- (instancetype)initWithAsset:(PHAsset *)asset {
    self = [super init];
    if (self) {
        _asset = asset;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageScrollView = [[PAImageScrollView alloc] initWithFrame:self.view.bounds];
    _imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    __weak typeof(self) wself = self;
    _imageScrollView.firstTimeZoomBlock = ^(PAImageScrollView *scrollView){
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself loadFullResolutionImage];
    };
    _imageScrollView.didSingleTapBlock = _didSingleTapBlock;
    [self.view addSubview:_imageScrollView];
    
    CGRect rect = [UIScreen mainScreen].bounds;
    CGFloat imageWidth = _asset.pixelWidth;
    CGFloat imageHeight = _asset.pixelHeight;
    if (CGRectGetWidth(rect) > CGRectGetHeight(rect)) {
        imageHeight = ceilf(imageHeight * CGRectGetWidth(rect) / imageWidth * 2.0f) / 2.0f;
        imageWidth = CGRectGetWidth(rect);
    }
    else {
        imageWidth = ceilf(imageWidth * CGRectGetHeight(rect) / imageHeight * 2.0f) / 2.0f;
        imageHeight = CGRectGetHeight(rect);
    }
    CGSize targetSize = CGSizeMake(imageWidth, imageHeight);
    [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.imageScrollView.image = result;
    }];
    
    if (_asset.mediaType == PHAssetMediaTypeVideo) {
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _videoButton.center = self.view.center;
}

#pragma loadFullResolutionImage
- (void)loadFullResolutionImage {
    CGSize targetSize = CGSizeMake(_asset.pixelWidth, _asset.pixelHeight);
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    __weak typeof(self) wself = self;
    [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.imageScrollView.image = result;
    }];
}

- (void)videoButtonAction {
    [[PHImageManager defaultManager] requestPlayerItemForVideo:_asset options:nil resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
        NSLog(@"%@", info);
        // TODO : AVPlayerを使う？
    }];
    
//    _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:videoUrl];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = MIN(screenSize.width, screenSize.height);
    CGFloat height = MAX(screenSize.width, screenSize.height);
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        _moviePlayerController.view.frame = CGRectMake(0.0f, 0.0f, height, width);
    }
    else {
        _moviePlayerController.view.frame = CGRectMake(0.0f, 0.0f, width, height);
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
        PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
        [tabBarController setIsStatusBarHidden:YES animated:NO];
        
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

@end
