//
//  PWAlbumPickerNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumPickerNavigationController.h"

#import "PWColors.h"

@interface PWAlbumPickerNavigationController ()

@end

@implementation PWAlbumPickerNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
    self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintUploadColor];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
