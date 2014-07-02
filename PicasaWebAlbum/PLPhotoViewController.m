//
//  PLPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPhotoViewController.h"

#import "PWColors.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "SDImageCache.h"
#import "PWImageScrollView.h"
#import "PWTabBarController.h"

@interface PLPhotoViewController ()

@property (strong, nonatomic) PWImageScrollView *imageScrollView;

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
}

- (void)loadFullResolutionImage {
    NSURL *url = [NSURL URLWithString:_photo.url];
    __weak typeof(self) wself = self;
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
