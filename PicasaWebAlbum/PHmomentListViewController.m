//
//  PHmomentListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/29.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEMomentListViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PEMomentListDataSource.h"
#import "PEPhotoListViewController.h"
#import "PATabBarAdsController.h"
#import "PWSearchNavigationController.h"

@interface PEMomentListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) PEMomentListDataSource *dataSource;
@property (nonatomic) BOOL isSelectMode;
@property (strong, nonatomic) UIBarButtonItem *selectTrashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectUploadBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectActionBarButtonItem;

@end

@implementation PEMomentListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Moment", nil);
        
        _dataSource = [PEMomentListDataSource new];
        _dataSource.cellSize = CGSizeMake(90.0f, 120.0f);
        _dataSource.minimumLineSpacing = 15.0f;
        __weak typeof(self) wself = self;
        _dataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[searchBarButtonItem];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = _dataSource;
    _collectionView.delegate = _dataSource;
    _dataSource.collectionView = _collectionView;
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
    
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[flexibleSpace, selectBarButtonItem];
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
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 15.0f, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    _collectionView.scrollIndicatorInsets = viewInsets;
    _collectionView.frame = rect;
}

#pragma mark UIBarButtonAction
- (void)searchBarButtonAction {
    [self openSearchBar];
}

- (void)selectBarButtonAction:(id)sender {
    [self enableSelectMode];
}

- (void)selectActionBarButtonAction:(id)sender {
    
}

- (void)selectUploadBarButtonAction:(id)sender {
    
}

- (void)selectTrashBarButtonAction:(id)sender {
    
}

- (void)cancelBarButtonAction:(id)sender {
    [self disableSelectMode];
}

#pragma mark SearchBar
- (void)openSearchBar {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setTabBarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:YES animated:NO];
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setTabBarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

#pragma mark SelectMode
- (void)enableSelectMode {
    if (_dataSource.isSelectMode) return;
    _dataSource.isSelectMode = YES;
    
    _selectActionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction:)];
    _selectActionBarButtonItem.enabled = NO;
    _selectUploadBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"Upload"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStylePlain target:self action:@selector(selectUploadBarButtonAction:)];
    _selectUploadBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Upload"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    _selectUploadBarButtonItem.enabled = NO;
    _selectTrashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(selectTrashBarButtonAction:)];
    _selectTrashBarButtonItem.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButtonItem, flexibleSpace, _selectUploadBarButtonItem, flexibleSpace, _selectTrashBarButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PAColors getColor:PAColorsTypeTintLocalColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction:)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Select items", nil)];
    [navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:NO];
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationTintColor:[PAColors getColor:PAColorsTypeTintLocalColor]];
    [tabBarController setActionNavigationBarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.navigationController.navigationBar.alpha = 0.0f;
    }];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)disableSelectMode {
    if (!_dataSource.isSelectMode) return;
    _dataSource.isSelectMode = NO;
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:NO animated:NO completion:nil];
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    self.navigationController.navigationBar.alpha = 1.0f;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

@end
