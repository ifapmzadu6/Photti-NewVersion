//
//  PHNavigationControllerViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PENavigationController.h"

#import "PAColors.h"
#import "PEHomeViewController.h"

@interface PENavigationController ()

@end

@implementation PENavigationController

- (instancetype)init {
    self = [super init];
    if (self) {
        PEHomeViewController *homeViewController = [PEHomeViewController new];
        
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
