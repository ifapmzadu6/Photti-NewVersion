//
//  PHPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoViewController.h"

#import <PAImageScrollView.h>
#import "PAIcons.h"
#import "PAPlayerView.h"
#import "PATabBarController.h"

@interface PEPhotoViewController ()

@property (strong, nonatomic) PAImageScrollView *imageScrollView;
@property (strong, nonatomic) UIButton *videoButton;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@property (strong, nonatomic) PAPlayerView *playerView;
@property (strong, nonatomic) UIButton *playerOverrayButton;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) BOOL isAutoPlay;

@property (nonatomic) BOOL statusBarHiddenBeforePlay;

@end

@implementation PEPhotoViewController

- (instancetype)initWithAsset:(PHAsset *)asset index:(NSUInteger)index {
    self = [super init];
    if (self) {
        _asset = asset;
        _index = index;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageScrollView = [[PAImageScrollView alloc] initWithFrame:self.view.bounds];
    _imageScrollView.zoomOption = PAImageScrollViewZoomOptionAdjust;
    _imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    __weak typeof(self) wself = self;
    _imageScrollView.firstTimeZoomBlock = ^(PAImageScrollView *scrollView) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself loadFullResolutionImage];
    };
    _imageScrollView.didSingleTapBlock = _didSingleTapBlock;
    [self.view addSubview:_imageScrollView];
    
    CGRect rect = [UIScreen mainScreen].bounds;
    double imageWidth = _asset.pixelWidth;
    double imageHeight = _asset.pixelHeight;
    double width = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect));
    double height = MAX(CGRectGetWidth(rect), CGRectGetHeight(rect));
    if (self.isLandscape) {
        CGFloat tmp = width;
        width = height;
        height = tmp;
    }
    if (width > height) {
        imageHeight = floorf(imageHeight * width / imageWidth * 2.0 + 1.0) / 2.0;
        imageWidth = width;
    }
    else {
        imageWidth = floorf(imageWidth * height / imageHeight * 2.0 + 1.0) / 2.0;
        imageHeight = height;
    }
    CGSize targetSize = CGSizeMake(imageWidth, imageHeight);
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.imageScrollView.image = result;
    }];
    
    if (_asset.mediaType == PHAssetMediaTypeVideo) {
        _imageScrollView.isDisableZoom = YES;
        
        _playerView = [PAPlayerView new];
        [self.view addSubview:_playerView];
        
        _playerOverrayButton = [UIButton new];
        [_playerOverrayButton addTarget:self action:@selector(playerOverrayButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_playerOverrayButton];
        
        _indicatorView = [UIActivityIndicatorView new];
        _indicatorView.center = self.view.center;
        [self.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
        
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
    
    if ((_asset.mediaType == PHAssetMediaTypeVideo) && !_playerItem && !_player) {
        __weak typeof(self) wself = self;
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestPlayerItemForVideo:_asset options:options resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.playerItem = playerItem;
            sself.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            AVPlayerLayer *layer = (AVPlayerLayer *)sself.playerView.layer;
            layer.videoGravity = AVLayerVideoGravityResizeAspect;
            layer.player = sself.player;
            if (sself.isAutoPlay) {
                [sself.player play];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sself.indicatorView stopAnimating];
                });
            }
            
            [playerItem addObserver:sself forKeyPath:@"status" options:0 context:nil];
            [playerItem addObserver:sself forKeyPath:@"playbackBufferEmpty" options:0 context:nil];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [[NSNotificationCenter defaultCenter] addObserver:sself selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _imageScrollView.didSingleTapBlock = nil;
    
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status" context:nil];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
        _playerItem = nil;
    }
    if (_player) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        _player = nil;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _playerView.frame = rect;
    _playerOverrayButton.frame = rect;
    
    _videoButton.center = self.view.center;
    
    _indicatorView.center = self.view.center;
}

#pragma loadFullResolutionImage
- (void)loadFullResolutionImage {
    CGSize targetSize = CGSizeMake(_asset.pixelWidth, _asset.pixelHeight);
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    __weak typeof(self) wself = self;
    [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.imageScrollView.image = result;
    }];
}

#pragma mark VideoAction
- (void)videoButtonAction {
    if (_didSingleTapBlock) {
        _didSingleTapBlock();
    }
    
    if (_player) {
        if (_player.rate == 0) {
            [_player play];
        }
    }
    else {
        _isAutoPlay = YES;
        
        [_indicatorView startAnimating];
    }
    
    UIScrollView *scrollView = self.parentViewController.view.subviews.firstObject;
    if ([scrollView isKindOfClass:[UIScrollView class]]) {
        scrollView.scrollEnabled = NO;
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        _videoButton.alpha = 0.0f;
    }];
}

- (void)playerOverrayButtonAction:(id)sender {
    if (_player && _player.rate != 0) {
        if (_didSingleTapBlock) {
            _didSingleTapBlock();
        }
        
        [_player pause];
        
        [UIView animateWithDuration:0.2f animations:^{
            _videoButton.alpha = 1.0f;
        } completion:^(BOOL finished) {
            UIScrollView *scrollView = self.parentViewController.view.subviews.firstObject;
            if ([scrollView isKindOfClass:[UIScrollView class]]) {
                scrollView.scrollEnabled = YES;
            }
        }];
    }
}

#pragma mark NSNotificationCenter
- (void)playerItemDidReachEnd:(id)sender {
    if (_player && _player.rate == 0) {
        if (_didSingleTapBlock) {
            _didSingleTapBlock();
        }
        
        [_player seekToTime:kCMTimeZero];
        
        [UIView animateWithDuration:0.2f animations:^{
            _videoButton.alpha = 1.0f;
        } completion:^(BOOL finished) {
            UIScrollView *scrollView = self.parentViewController.view.subviews.firstObject;
            if ([scrollView isKindOfClass:[UIScrollView class]]) {
                scrollView.scrollEnabled = YES;
            }
        }];
    }
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        if ([keyPath isEqualToString:@"status"]) {
            switch(item.status)
            {
                case AVPlayerItemStatusFailed:
                    [_indicatorView stopAnimating];
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    [_indicatorView stopAnimating];
                    break;
                case AVPlayerItemStatusUnknown:
                    [_indicatorView stopAnimating];
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            if (item.playbackBufferEmpty) {
                [_indicatorView startAnimating];
            }
        }
    }
}

@end
