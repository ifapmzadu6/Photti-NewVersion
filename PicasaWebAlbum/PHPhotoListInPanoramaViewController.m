//
//  PHPhotoListInPanoramaViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHPhotoListInPanoramaViewController.h"

#import "PHPhotoDataSourceFactoryMethod.h"
#import "PHPhotoListDataSource.h"

@interface PHPhotoListInPanoramaViewController ()

@property (strong, nonatomic) PHAssetCollection *panoramaCollection;
@property (strong, nonatomic) PHFetchResult *fetchResult;

@property (strong, nonatomic) PHPhotoListDataSource *dataSouce;

@end

@implementation PHPhotoListInPanoramaViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _dataSouce = [PHPhotoDataSourceFactoryMethod makePanoramaListDataSource];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
