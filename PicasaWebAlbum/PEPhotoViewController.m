//
//  PHPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoViewController.h"

#import "PWImageScrollView.h"

@interface PEPhotoViewController ()

@property (strong, nonatomic) PWImageScrollView *imageScrollView;

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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

@end
