//
//  PHNavigationControllerViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHNavigationController.h"

#import "PAColors.h"
#import "PHHomeViewController.h"

@interface PHNavigationController ()

@end

@implementation PHNavigationController

- (instancetype)init {
    self = [super init];
    if (self) {
        PHHomeViewController *homeViewController = [PHHomeViewController new];
        
        self.viewControllers = @[homeViewController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
