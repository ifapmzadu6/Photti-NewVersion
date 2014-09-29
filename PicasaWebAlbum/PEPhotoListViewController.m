//
//  PHPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoListViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PATabBarAdsController.h"
#import "PEPhotoDataSourceFactoryMethod.h"
#import "PEPhotoListDataSource.h"
#import "PEPhotoPageViewController.h"

@interface PEPhotoListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;

@property (nonatomic) PHPhotoListViewControllerType type;
@property (strong, nonatomic) PEPhotoListDataSource *photoListDataSource;
@property (nonatomic) BOOL isSelectMode;

@end

@implementation PEPhotoListViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(PHPhotoListViewControllerType)type {
    self = [self initWithAssetCollection:assetCollection type:type title:nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(PHPhotoListViewControllerType)type title:(NSString *)title {
    self = [self initWithAssetCollection:assetCollection type:type title:title startDate:nil endDate:nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(PHPhotoListViewControllerType)type title:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self = [super init];
    if (self) {
        _type = type;
        
        if (title) {
            self.title = title;
        }
        else {
            if (type == PHPhotoListViewControllerType_AllPhotos) {
                self.title = NSLocalizedString(@"All Items", nil);
            }
            else {
                self.title = assetCollection.localizedTitle;
            }
        }
        
        __weak typeof(self) wself = self;
        if (type == PHPhotoListViewControllerType_AllPhotos) {
            _photoListDataSource = [PEPhotoDataSourceFactoryMethod makeAllPhotoListDataSource];
            _photoListDataSource.flowLayout = [PAPhotoCollectionViewFlowLayout new];
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index) {
                typeof(wself) sself = wself;
                if (!sself) return;
                PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:nil];
                PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithResult:fetchResult index:index];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (type == PHPhotoListViewControllerType_Dates) {
            _photoListDataSource = [PEPhotoDataSourceFactoryMethod makePhotoListDataSourceWithStartDate:startDate endDate:endDate];
            _photoListDataSource.flowLayout = [PAPhotoCollectionViewFlowLayout new];
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index) {
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithResult:sself.photoListDataSource.fetchResult index:index];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else {
            _photoListDataSource = [PEPhotoDataSourceFactoryMethod makePhotoInAlbumListDataSourceWithCollection:assetCollection];
            _photoListDataSource.flowLayout = [PAPhotoCollectionViewFlowLayout new];
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index) {
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.photoListDataSource.assetCollection index:index];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = _photoListDataSource;
    _collectionView.delegate = _photoListDataSource;
    [_photoListDataSource prepareForUse:_collectionView];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_isSelectMode) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction:)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction:)];
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, selectBarButtonItem];
    if (_type == PHPhotoListViewControllerType_Album) {
        toolbarItems = @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    }
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        [tabBarController setToolbarTintColor:[PAColors getColor:PAColorsTypeTintLocalColor]];
        __weak typeof(self) wself = self;
        [tabBarController setToolbarHidden:NO animated:animated completion:^(BOOL finished) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
            [tabBarController setTabBarHidden:YES animated:NO completion:nil];
        }];
    }
    else {
        [tabBarController setToolbarItems:toolbarItems animated:YES];
    }
    [tabBarController setAdsHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = tabBarController.viewInsets;
    _collectionView.contentInset = viewInsets;
    _collectionView.scrollIndicatorInsets = viewInsets;
    _collectionView.frame = rect;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)actionBarButtonAction:(id)sender {
    
}

- (void)addBarButtonAction:(id)sender {
    
}

- (void)selectBarButtonAction:(id)sender {
    
}

@end
