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


@interface SEImageViewController ()

@property (nonatomic) NSInteger index;
@property (strong, nonatomic) NSItemProvider *item;

@property (strong, nonatomic) UIImageView *imageView;

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
    
    if ([_item hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeImage]) {
        __weak typeof(self) wself = self;
        [_item loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeImage options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
                return;
            }
            NSURL *url = (NSURL *)item;
            CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
            CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSourceRef, 0, (__bridge CFDictionaryRef) @{(NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES, (NSString *)kCGImageSourceThumbnailMaxPixelSize: @(500), (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES});
            CFRelease(imageSourceRef);
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    sself.imageView = [UIImageView new];
                    sself.imageView.image = (UIImage *)image;
                    sself.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    sself.imageView.clipsToBounds = YES;
                    [sself.view addSubview:sself.imageView];
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
}

@end
