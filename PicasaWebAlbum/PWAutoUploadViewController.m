//
//  PWAutoUploadViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAutoUploadViewController.h"

#import "PWColors.h"

@interface PWAutoUploadViewController ()

@end

@implementation PWAutoUploadViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"自動アップロード";
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemDownloads tag:3];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
