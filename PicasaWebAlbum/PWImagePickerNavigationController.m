//
//  PWImagePickerNabigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerNavigationController.h"

#import "PWColors.h"

@interface PWImagePickerNavigationController ()

@end

@implementation PWImagePickerNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintUploadColor];
    self.navigationBar.barTintColor = [UIColor blackColor];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
        
    UINavigationItem *item = self.navigationBar.items.lastObject;
    [item.titleView setNeedsLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setTitleOnNavigationBar:(NSString *)titleOnNavigationBar {
    _titleOnNavigationBar = titleOnNavigationBar;
    
    for (UIViewController *viewController in self.viewControllers) {
        viewController.navigationItem.prompt = titleOnNavigationBar;
    }
}

- (void)setSelectedPhotosThumbnailImage:(UIImage *)image {
    
}

- (void)setSelectedPhotosSubThumbnailImage:(UIImage *)image {
    
}

- (void)setSelectedPhotosCount:(NSUInteger)count {
    
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    
    viewController.navigationItem.prompt = _titleOnNavigationBar;
}

@end
