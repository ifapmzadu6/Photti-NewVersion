//
//  PABaseViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/27.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PABaseViewController.h"

@interface PABaseViewController ()

@property (strong, nonatomic) UIImageView *noItemImageView;

@property (nonatomic, readwrite) BOOL isPhone;

@end

@implementation PABaseViewController

- (id)init {
    self = [super init];
    if (self) {
        _isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? YES : NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.screenName = NSStringFromClass([self class]);
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self layoutNoItem];
}

#pragma mark methods
- (BOOL)isLandscape {
    return UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
}

#pragma mark NoItem
- (void)refreshNoItemWithNumberOfItem:(NSUInteger)numberOfItem {
    if (numberOfItem == 0) {
        [self showNoItem];
    }
    else {
        [self hideNoItem];
    }
}

- (void)showNoItem {
    if (!_noItemImageView) {
        _noItemImageView = [UIImageView new];
        _noItemImageView.image = [UIImage imageNamed:@"icon_240"];
        _noItemImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:_noItemImageView];
    }
    [self.view bringSubviewToFront:_noItemImageView];
}

- (void)hideNoItem {
    if (_noItemImageView) {
        [_noItemImageView removeFromSuperview];
        _noItemImageView = nil;
    }
}

- (void)layoutNoItem {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _noItemImageView.frame = CGRectMake(0.0f, 0.0f, 240.0f, 240.0f);
    }
    else {
        _noItemImageView.frame = CGRectMake(0.0f, 0.0f, 440.0f, 440.0f);
    }
    _noItemImageView.center = self.view.center;
}

@end
