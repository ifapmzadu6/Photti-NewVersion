//
//  PABaseViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/27.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PABaseViewController.h"

@interface PABaseViewController ()

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark methods
- (BOOL)isLandscape {
    return UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
}

@end
