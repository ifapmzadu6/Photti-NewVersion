//
//  SEImageViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "SEImageViewController.h"

@import MobileCoreServices;
@import ImageIO;

#import "PAActivityIndicatorView.h"
#import "PAResizeData.h"


@interface SEImageViewController ()

@property (nonatomic) NSInteger index;
@property (strong, nonatomic) NSItemProvider *item;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong ,nonatomic) UIActivityIndicatorView *indicatorView;

@end

@implementation SEImageViewController

- (instancetype)initWithIndex:(NSInteger)index item:(NSItemProvider *)item {
    self = [super init];
    if (self) {
        _index = index;
        _item = item;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
    
    _indicatorView = [PAActivityIndicatorView new];
    [_indicatorView startAnimating];
    [self.view addSubview:_indicatorView];
    
    if ([_item hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeImage]) {
        __weak typeof(self) wself = self;
        [_item loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeImage options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) return;
            NSURL *url = (NSURL *)item;
            UIImage *image = [PAResizeData imageFromFileUrl:url maxPixelSize:500];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    [sself showImageViewWithImage:image];
                }
            });
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _imageView.frame = rect;
    _indicatorView.center = self.view.center;
}

#pragma mark ShowView
- (void)showImageViewWithImage:(UIImage *)image {
    _imageView = [UIImageView new];
    _imageView.image = (UIImage *)image;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.alpha = 0.0f;
    [self.view addSubview:_imageView];
    
    [UIView animateWithDuration:0.2f animations:^{
        _imageView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [_indicatorView stopAnimating];
    }];
}

@end
