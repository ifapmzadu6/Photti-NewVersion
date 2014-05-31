//
//  PWImagePickerLocaliCloudViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerLocaliCloudViewController.h"

#import "PWColors.h"

@interface PWImagePickerLocaliCloudViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;

@end

@implementation PWImagePickerLocaliCloudViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"iCloud上の写真", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
    
    _collectionView.scrollsToTop = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _collectionView.scrollsToTop = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
