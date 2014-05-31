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

@property (strong, nonatomic) UILabel *titleOnNavigationBarLabel;

@end

@implementation PWImagePickerNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
    
    _titleOnNavigationBarLabel = [[UILabel alloc] init];
    _titleOnNavigationBarLabel.font = [UIFont systemFontOfSize:13.0f];
    _titleOnNavigationBarLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    _titleOnNavigationBarLabel.textAlignment = NSTextAlignmentCenter;
    [self.navigationBar addSubview:_titleOnNavigationBarLabel];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    
    CGFloat navigationBarHeight = 20.0f + 44.0f + 30.0f;
    if (isLandscape) {
        navigationBarHeight = 20.0f + 32.0f + 22.0f;
    }
    
    self.navigationBar.frame = CGRectMake(0.0f, 0.0f, rect.size.width, navigationBarHeight);
    
    CGFloat navigationBarLabelHeight = navigationBarHeight - 44.0f - 16.0f;
    if (isLandscape) {
        navigationBarLabelHeight = navigationBarHeight - 32.0f - 19.0f;
    }
    _titleOnNavigationBarLabel.frame = CGRectMake(0.0f, navigationBarLabelHeight, rect.size.width, 13.0f);
    
    UINavigationItem *item = self.navigationBar.items.lastObject;
    [item.titleView setNeedsLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setTitleOnNavigationBar:(NSString *)titleOnNavigationBar {
    _titleOnNavigationBar = titleOnNavigationBar;
    
    _titleOnNavigationBarLabel.text = titleOnNavigationBar;
}

- (void)setSelectedPhotosThumbnailImage:(UIImage *)image {
    
}

- (void)setSelectedPhotosSubThumbnailImage:(UIImage *)image {
    
}

- (void)setSelectedPhotosCount:(NSUInteger)count {
    
}

@end
