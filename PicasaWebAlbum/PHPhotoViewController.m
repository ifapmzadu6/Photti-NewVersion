//
//  PHPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHPhotoViewController.h"

#import "PWImageScrollView.h"

@interface PHPhotoViewController ()

@property (strong, nonatomic) PWImageScrollView *imageScrollView;

@end

@implementation PHPhotoViewController

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
//        [sself loadFullResolutionImage];
    };
    [_imageScrollView setHandleSingleTapBlock:_handleSingleTapBlock];
    [self.view addSubview:_imageScrollView];
    
    [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:CGSizeMake(_asset.pixelWidth, _asset.pixelHeight) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
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

@end
