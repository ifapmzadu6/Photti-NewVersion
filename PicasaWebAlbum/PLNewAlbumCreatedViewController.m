//
//  PLNewAlbumCreatedViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLNewAlbumCreatedViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLAssetsManager.h"

@interface PLNewAlbumCreatedViewController ()

@property (strong, nonatomic) UILabel *createdNewAlbumLabel;

@end

@implementation PLNewAlbumCreatedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    _createdNewAlbumLabel = [UILabel new];
    _createdNewAlbumLabel.text = NSLocalizedString(@"Created New Albums!", nil);
    _createdNewAlbumLabel.font = [UIFont systemFontOfSize:15.0f];
    _createdNewAlbumLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_createdNewAlbumLabel];
    
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
//    CGRect rect = self.view.bounds;
    
    _createdNewAlbumLabel.frame = CGRectMake(60.0f, 300.0f, 200.0f, 20.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
