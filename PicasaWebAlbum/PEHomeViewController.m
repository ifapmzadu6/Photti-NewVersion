//
//  PHHomeViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEHomeViewController.h"

@import Photos;

#import "PAColors.h"
#import "PAIcons.h"
#import "PAString.h"
#import "PAPhotoKit.h"
#import "PADateFormatter.h"
#import "PDCoreDataAPI.h"
#import "PDTaskManager.h"
#import "PATabBarAdsController.h"
#import "PXSettingsViewController.h"
#import "PASearchNavigationController.h"
#import "PECategoryViewCell.h"
#import "PACenterTextTableViewCell.h"
#import "PEScrollBannerHeaderView.h"
#import "PEBannerContentView.h"
#import "PAHorizontalScrollView.h"
#import "PEPhotoDataSourceFactoryMethod.h"
#import "PEAlbumListDataSource.h"
#import "PEMomentListDataSource.h"
#import "PDUploadBarButtonItem.h"

#import "PEAlbumListViewController.h"
#import "PEMomentListViewController.h"
#import "PEPhotoListViewController.h"
#import "PEPhotoPageViewController.h"
#import "PDNavigationController.h"

@interface PEHomeViewController () <UITableViewDelegate, PDTaskManagerDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIImageView *todayImageView;
@property (strong, nonatomic) UIImageView *yesterdayImageView;
@property (strong, nonatomic) UIImageView *thisWeekImageView;
@property (strong, nonatomic) UIImageView *lastWeekImageView;

@property (strong, nonatomic) NSArray *enabledItems;

@end

@implementation PEHomeViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"On Device", nil);
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        [self setUpAlbumDataSource];
        [self setUpMomentsDataSource];
        [self setUpVideoDataSource];
        [self setUpPanoramaDataSource];
        [self setUpFavoriteDataSource];
        [self setUpTimelapseDataSource];
        [self setUpCloudDataSource];
        [self setUpBurstsDataSource];
        [self setUpSlomoVideosDataSource];
        [self setUpAllPhotosDataSource];
        
        [[PDTaskManager sharedManager] addTaskManagerObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[PDTaskManager sharedManager] removeTaskManagerObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    self.navigationController.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[searchBarButtonItem];
    PDUploadBarButtonItem *uploadBarButtonItem = [PDUploadBarButtonItem new];
    UIButton *button = (UIButton *)uploadBarButtonItem.customView;
    [button addTarget:self action:@selector(taskBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItems = @[uploadBarButtonItem];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _tableView = [UITableView new];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [_tableView registerClass:[PACenterTextTableViewCell class] forCellReuseIdentifier:NSStringFromClass([PACenterTextTableViewCell class])];
    [_tableView registerClass:[PECategoryViewCell class] forCellReuseIdentifier:NSStringFromClass([PECategoryViewCell class])];
    _tableView.alwaysBounceVertical = YES;
    _tableView.exclusiveTouch = YES;
    _tableView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _tableView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom + 30.0f, 0.0f);
    _tableView.scrollIndicatorInsets = viewInsets;
    _tableView.contentOffset = CGPointMake(0.0f, -viewInsets.top);
    [self.view addSubview:_tableView];
    
    PEScrollBannerHeaderView *headerView = [PEScrollBannerHeaderView new];
    if (self.isPhone) {
        headerView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 120.0f);
    }
    else {
        headerView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 200.0f);
    }
    headerView.shouldAnimate = NO;
    NSArray *headerContentViews = [self bannerContentViews];
    if (headerContentViews.count > 0) {
        headerView.views = headerContentViews;
    }
    else {
        headerView.views = @[[self noContentBannerView]];
    }
    _tableView.tableHeaderView = headerView;
    
    UILabel *footerView = [UILabel new];
    footerView.frame = CGRectMake(0.0f, 0.0f, 320.0f, 60.0f);
    footerView.text = @"Photti\nCopyright © 2014 Keisuke Karijuku.";
    footerView.font = [UIFont systemFontOfSize:13.0f];
    footerView.textAlignment = NSTextAlignmentCenter;
    footerView.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
    footerView.numberOfLines = 2;
    _tableView.tableFooterView = footerView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [tabBarController setToolbarHidden:YES animated:YES completion:nil];
    
    NSArray *enabledItems = [[NSUserDefaults standardUserDefaults] arrayForKey:kPEHomeViewControllerUserDefaultsEnabledItemKey];
    if (![_enabledItems isEqualToArray:enabledItems]) {
        _enabledItems = enabledItems;
        
        [_tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    [tabBarController setAdsHidden:NO animated:YES];
    
    PEScrollBannerHeaderView *headerView = (PEScrollBannerHeaderView *)_tableView.tableHeaderView;
    headerView.shouldAnimate = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    PEScrollBannerHeaderView *headerView = (PEScrollBannerHeaderView *)_tableView.tableHeaderView;
    headerView.shouldAnimate = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _tableView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom + 30.0f, 0.0f);
    _tableView.scrollIndicatorInsets = viewInsets;
    _tableView.frame = rect;
}

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setTabBarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:YES animated:NO];
    
    PASearchNavigationController *navigationController = (PASearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setTabBarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

- (void)taskBarButtonAction:(id)sender {
    PDNavigationController *navigationController = [PDNavigationController new];
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)settingsBarButtonAction {
    PXSettingsViewController *viewController = [[PXSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark SetUpDaraSource
- (void)setUpAlbumDataSource {
    _albumListDataSource = [PEAlbumListDataSource new];
    _albumListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 134.0f) : CGSizeMake(150.0f, 180.0f);
    _albumListDataSource.minimumLineSpacing = 15.0f;
    _albumListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _albumListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection){
        typeof(wself) sself = wself;
        if (!sself) return;
        PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:kPHPhotoListViewControllerType_Album];
        [sself.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)setUpMomentsDataSource {
    _momentListDataSource = [PEMomentListDataSource new];
    _momentListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 134.0f) : CGSizeMake(150.0f, 184.0f);
    _momentListDataSource.minimumLineSpacing = 15.0f;
    _momentListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _momentListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection) {
        typeof(wself) sself = wself;
        if (!sself) return;
        NSString *title = [PAPhotoKit titleForMoment:assetCollection];
        PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:kPHPhotoListViewControllerType_Moment title:title];
        [sself.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)setUpVideoDataSource {
    _videoListDataSource = [PEPhotoDataSourceFactoryMethod makeVideoListDataSource];
    _videoListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _videoListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _videoListDataSource.minimumLineSpacing = 15.0f;
    _videoListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _videoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.videoListDataSource.assetCollection index:index ascending:sself.videoListDataSource.ascending];
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

- (void)setUpPanoramaDataSource {
    _panoramaListDataSource = [PEPhotoDataSourceFactoryMethod makePanoramaListDataSource];
    _panoramaListDataSource.cellSize = (self.isPhone) ? CGSizeMake(270.0f, 100.0f) : CGSizeMake(500.0f, 150.0f);
    _panoramaListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(270.0f, 100.0f) : CGSizeMake(500.0f, 150.0f);
    _panoramaListDataSource.minimumLineSpacing = 15.0f;
    _panoramaListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _panoramaListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.panoramaListDataSource.assetCollection index:index ascending:sself.panoramaListDataSource.ascending];
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

- (void)setUpFavoriteDataSource {
    _favoriteListDataSource = [PEPhotoDataSourceFactoryMethod makeFavoriteListDataSource];
    _favoriteListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _favoriteListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _favoriteListDataSource.minimumLineSpacing = 15.0f;
    _favoriteListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _favoriteListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.favoriteListDataSource.assetCollection index:index ascending:sself.favoriteListDataSource.ascending];
            viewController.needsFavoriteChangedPopBack = YES;
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

- (void)setUpTimelapseDataSource {
    _timelapseListDataSource = [PEPhotoDataSourceFactoryMethod makeTimelapseListDataSource];
    _timelapseListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _timelapseListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _timelapseListDataSource.minimumLineSpacing = 15.0f;
    _timelapseListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _timelapseListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.timelapseListDataSource.assetCollection index:index ascending:sself.timelapseListDataSource.ascending];
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

- (void)setUpCloudDataSource {
    _cloudListDataSource = [PEPhotoDataSourceFactoryMethod makeCloudListDataSource];
    _cloudListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _cloudListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _cloudListDataSource.minimumLineSpacing = 15.0f;
    _cloudListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _cloudListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.cloudListDataSource.assetCollection index:index ascending:sself.cloudListDataSource.ascending];
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

- (void)setUpBurstsDataSource {
    _burstsListDataSource = [PEPhotoDataSourceFactoryMethod makeBurstListDataSource];
    _burstsListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _burstsListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _burstsListDataSource.minimumLineSpacing = 15.0f;
    _burstsListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _burstsListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.burstsListDataSource.assetCollection index:index ascending:sself.burstsListDataSource.ascending];
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

- (void)setUpSlomoVideosDataSource {
    _slomoVideosListDataSource = [PEPhotoDataSourceFactoryMethod makeSlomoVideoListDataSource];
    _slomoVideosListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _slomoVideosListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _slomoVideosListDataSource.minimumLineSpacing = 15.0f;
    _slomoVideosListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _slomoVideosListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.slomoVideosListDataSource.assetCollection index:index ascending:sself.slomoVideosListDataSource.ascending];
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

- (void)setUpAllPhotosDataSource {
    _allPhotoListDataSource = [PEPhotoDataSourceFactoryMethod makeAllPhotoListDataSource];
    _allPhotoListDataSource.cellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _allPhotoListDataSource.landscapeCellSize = (self.isPhone) ? CGSizeMake(100.0f, 100.0f) : CGSizeMake(150.0f, 150.0f);
    _allPhotoListDataSource.minimumLineSpacing = 15.0f;
    _allPhotoListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    __weak typeof(self) wself = self;
    _allPhotoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode){
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!isSelectMode) {
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithResult:sself.allPhotoListDataSource.fetchResult index:index ascending:sself.allPhotoListDataSource.ascending];
            [sself.navigationController pushViewController:viewController animated:YES];
        }
    };
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return _enabledItems.count;
    }
    else {
        return 4;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PECategoryViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PECategoryViewCell class]) forIndexPath:indexPath];
        
        __weak typeof(cell) wcell = cell;
        void (^didChangeItemCountBlock)(NSUInteger) = ^(NSUInteger count){
            typeof(wcell) scell = wcell;
            if (!scell) return;
            cell.noItemLabel.hidden = (count==0) ? NO : YES;
            cell.noItemLabel.userInteractionEnabled = !cell.noItemLabel.hidden;
            cell.horizontalScrollView.collectionView.hidden = !cell.noItemLabel.hidden;
            cell.horizontalScrollView.collectionView.userInteractionEnabled = cell.noItemLabel.hidden;
        };
        
        NSString *rowType = _enabledItems[indexPath.row];
        __weak typeof(self) wself = self;
        if ([rowType isEqualToString:kPEHomeViewControllerRowType_Albums]) {
            _albumListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _albumListDataSource;
            cell.horizontalScrollView.delegate = _albumListDataSource;
            cell.titleLabel.text = [PEHomeViewController localizedStringFromRowType:rowType];
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEAlbumListViewController *viewController = [PEAlbumListViewController new];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_albumListDataSource.fetchResult.count==0) ? NO : YES;
            _albumListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Moments]) {
            _momentListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _momentListDataSource;
            cell.horizontalScrollView.delegate = _momentListDataSource;
            cell.titleLabel.text = [self.class localizedStringFromRowType:rowType];
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEMomentListViewController *viewController = [PEMomentListViewController new];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_momentListDataSource.fetchResult.count==0) ? NO : YES;
            _momentListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Panoramas]) {
            _panoramaListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _panoramaListDataSource;
            cell.horizontalScrollView.delegate = _panoramaListDataSource;
            cell.titleLabel.text = _panoramaListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.panoramaListDataSource.assetCollection type:kPHPhotoListViewControllerType_Panorama];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_panoramaListDataSource.fetchResult.count==0) ? NO : YES;
            _panoramaListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Videos]) {
            _videoListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _videoListDataSource;
            cell.horizontalScrollView.delegate = _videoListDataSource;
            cell.titleLabel.text = _videoListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.videoListDataSource.assetCollection type:kPHPhotoListViewControllerType_Video];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_videoListDataSource.fetchResult.count==0) ? NO : YES;
            _videoListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Favorites]) {
            _favoriteListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _favoriteListDataSource;
            cell.horizontalScrollView.delegate = _favoriteListDataSource;
            cell.titleLabel.text = _favoriteListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.favoriteListDataSource.assetCollection type:kPHPhotoListViewControllerType_Favorite];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_favoriteListDataSource.fetchResult.count==0) ? NO : YES;
            _favoriteListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Timelapse]) {
            _timelapseListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _timelapseListDataSource;
            cell.horizontalScrollView.delegate = _timelapseListDataSource;
            cell.titleLabel.text = _timelapseListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.timelapseListDataSource.assetCollection type:kPHPhotoListViewControllerType_Timelapse];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_timelapseListDataSource.fetchResult.count==0) ? NO : YES;
            _timelapseListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Cloud]) {
            _cloudListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _cloudListDataSource;
            cell.horizontalScrollView.delegate = _cloudListDataSource;
            cell.titleLabel.text = [self.class localizedStringFromRowType:kPEHomeViewControllerRowType_Cloud];
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.cloudListDataSource.assetCollection type:kPHPhotoListViewControllerType_iCloud];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_cloudListDataSource.fetchResult.count==0) ? NO : YES;
            _cloudListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Bursts]) {
            _burstsListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _burstsListDataSource;
            cell.horizontalScrollView.delegate = _burstsListDataSource;
            cell.titleLabel.text = _burstsListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.burstsListDataSource.assetCollection type:kPHPhotoListViewControllerType_Bursts];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_burstsListDataSource.fetchResult.count==0) ? NO : YES;
            _burstsListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_SlomoVideos]) {
            _slomoVideosListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _slomoVideosListDataSource;
            cell.horizontalScrollView.delegate = _slomoVideosListDataSource;
            cell.titleLabel.text = _slomoVideosListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.slomoVideosListDataSource.assetCollection type:kPHPhotoListViewControllerType_SlomoVideo];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_slomoVideosListDataSource.fetchResult.count==0) ? NO : YES;
            _slomoVideosListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_AllPhotos]) {
            _allPhotoListDataSource.collectionView = cell.horizontalScrollView.collectionView;
            cell.horizontalScrollView.dataSource = _allPhotoListDataSource;
            cell.horizontalScrollView.delegate = _allPhotoListDataSource;
            cell.titleLabel.text = [self.class localizedStringFromRowType:rowType];
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:nil type:kPHPhotoListViewControllerType_AllPhotos];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
            cell.noItemLabel.hidden = (_allPhotoListDataSource.fetchResult.count==0) ? NO : YES;
            _allPhotoListDataSource.didChangeItemCountBlock = didChangeItemCountBlock;
        }
        cell.noItemLabel.userInteractionEnabled = !cell.noItemLabel.hidden;
        cell.horizontalScrollView.collectionView.hidden = !cell.noItemLabel.hidden;
        cell.horizontalScrollView.collectionView.userInteractionEnabled = cell.noItemLabel.hidden;
        cell.didSelectSettingsBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            PXSettingsViewController *viewController = [[PXSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
            [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
        };
        
        return cell;
    }
    else {
        PACenterTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PACenterTextTableViewCell class]) forIndexPath:indexPath];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.centerTextLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.textLabel.text = nil;
        cell.centerTextLabel.text = nil;
        
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Other", nil);
            cell.textLabel.textColor = [PAColors getColor:kPAColorsTypeTextColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (indexPath.row == 1) {
            cell.centerTextLabel.text = NSLocalizedString(@"Tell a frend this app", nil);
            cell.centerTextLabel.textColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (indexPath.row == 2) {
            cell.centerTextLabel.text = NSLocalizedString(@"Remove ads", nil);
            cell.centerTextLabel.textColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (indexPath.row == 3) {
            cell.centerTextLabel.text = NSLocalizedString(@"Settings", nil);
            cell.centerTextLabel.textColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row >= _enabledItems.count) {
            return;
        }
        
        NSString *rowType = _enabledItems[indexPath.row];
        if ([rowType isEqualToString:kPEHomeViewControllerRowType_Albums]) {
            _albumListDataSource.collectionView = nil;
            _albumListDataSource.didChangeItemCountBlock = nil;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Moments]) {
            _momentListDataSource.collectionView = nil;
            _momentListDataSource.didChangeItemCountBlock = nil;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Panoramas]) {
            _panoramaListDataSource.collectionView = nil;
            _panoramaListDataSource.didChangeItemCountBlock = nil;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Videos]) {
            _videoListDataSource.collectionView = nil;
            _videoListDataSource.didChangeItemCountBlock = nil;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Favorites]) {
            _favoriteListDataSource.collectionView = nil;
            _favoriteListDataSource.didChangeItemCountBlock = nil;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Timelapse]) {
            _timelapseListDataSource.collectionView = nil;
            _timelapseListDataSource.didChangeItemCountBlock = nil;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Cloud]) {
            _cloudListDataSource.collectionView = nil;
            _cloudListDataSource.didChangeItemCountBlock = nil;
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_AllPhotos]) {
            _allPhotoListDataSource.collectionView = nil;
            _allPhotoListDataSource.didChangeItemCountBlock = nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSString *enabledItems = _enabledItems[indexPath.row];
        if ([enabledItems isEqualToString:kPEHomeViewControllerRowType_Albums] ||
            [enabledItems isEqualToString:kPEHomeViewControllerRowType_Moments]) {
            return (self.isPhone) ? 200.0f : 246.0f;
        }
        return (self.isPhone) ? 170.0f : 220.0f;
    }
    return 44.0f;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            NSString *title = NSLocalizedString(@"Photti - Unlimitedly upload your photos. Free! New Photo Management App.", nil);
            NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/app/id892657316"];
            UIImage *image = [UIImage imageNamed:@"original_img"];
            UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[title, url, image] applicationActivities:nil];
            viewController.popoverPresentationController.sourceView = self.view;
            CGRect frame = [tableView rectForRowAtIndexPath:indexPath];
            CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
            viewController.popoverPresentationController.sourceRect = CGRectMake(0.0f, CGRectGetMinY(frame)-tableView.contentOffset.y, CGRectGetWidth(tableView.bounds), height);
            [self.tabBarController presentViewController:viewController animated:YES completion:nil];
        }
        else if (indexPath.row == 2) {
            [self settingsBarButtonAction];
        }
        else if (indexPath.row == 3) {
            [self settingsBarButtonAction];
        }
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y + scrollView.contentInset.top;
    PEScrollBannerHeaderView *headerView = (PEScrollBannerHeaderView *)_tableView.tableHeaderView;
    headerView.shouldAnimate = NO;
    if (offsetY < 0) {
        headerView.contentInsets = UIEdgeInsetsMake(offsetY, 0.0f, -offsetY, 0.0f);
    }
    else {
        headerView.contentInsets = UIEdgeInsetsZero;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    PEScrollBannerHeaderView *headerView = (PEScrollBannerHeaderView *)_tableView.tableHeaderView;
    headerView.shouldAnimate = YES;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    PEScrollBannerHeaderView *headerView = (PEScrollBannerHeaderView *)_tableView.tableHeaderView;
    headerView.shouldAnimate = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    PEScrollBannerHeaderView *headerView = (PEScrollBannerHeaderView *)_tableView.tableHeaderView;
    headerView.shouldAnimate = YES;
}

#pragma mark PDTaskManagerDelegate
- (void)taskManagerChangedTaskCount {
    __weak typeof(self) wself = self;
    [[PDTaskManager sharedManager] countOfAllPhotosInTaskWithCompletion:^(NSUInteger count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            PDUploadBarButtonItem *uploadBarButtonItem = (PDUploadBarButtonItem *)sself.navigationItem.leftBarButtonItem;
            if (count > 0) {
                [uploadBarButtonItem startAnimation];
            }
            else {
                [uploadBarButtonItem endAnimation];
            }
        });
    }];
}

#pragma mark Banner
- (NSMutableArray *)bannerContentViews {
    NSMutableArray *views = @[].mutableCopy;
    {
        NSString *title = NSLocalizedString(@"Today", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate date]];
        NSDate *endDate = [NSDate dateWithTimeInterval:(24*60*60) sinceDate:startDate];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view) [views addObject:view];
    } {
        NSString *title = NSLocalizedString(@"Yesterday", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate dateWithTimeIntervalSinceNow:-(24*60*60)]];
        NSDate *endDate = [NSDate dateWithTimeInterval:(24*60*60) sinceDate:startDate];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view) [views addObject:view];
    } {
        NSString *title = NSLocalizedString(@"This Week", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate dateWithTimeIntervalSinceNow:-(24*60*60*7)]];
        NSDate *endDate = [NSDate date];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view) [views addObject:view];
    } {
        NSString *title = NSLocalizedString(@"Last Week", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate dateWithTimeIntervalSinceNow:-(24*60*60*14)]];
        NSDate *endDate = [NSDate dateWithTimeInterval:(24*60*60*7) sinceDate:startDate];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view) [views addObject:view];
    }
    return views;
}


- (UIView *)makeBannerViewWithTitle:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"(creationDate > %@) AND (creationDate < %@)", startDate, endDate];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:options];
    if (fetchResult.count == 0) {
        return nil;
    }
    PEBannerContentView *contentView = [PEBannerContentView new];
    contentView.titleLabel.text = title;
    __weak typeof(self) wself = self;
    contentView.touchUpInsideActionBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:nil type:kPHPhotoListViewControllerType_Dates title:title startDate:startDate endDate:endDate];
        [sself.navigationController pushViewController:viewController animated:YES];
    };
    PHAsset *asset = fetchResult.firstObject;
    __weak typeof(contentView) wcontentView = contentView;
    PHImageRequestOptions *imageRequestOptions = [PHImageRequestOptions new];
    imageRequestOptions.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wcontentView) scontentView = wcontentView;
        if (!scontentView) return;
        scontentView.imageView.image = result;
    }];
    contentView.gradientViewInsets = UIEdgeInsetsMake(0.0f, 0.0f, 40.0f, 0.0f);
    return contentView;
}

- (UIView *)noContentBannerView {
    PEBannerContentView *bannerView = [PEBannerContentView new];
    bannerView.titleLabel.text = NSLocalizedString(@"Let's take a picture.", nil);
    bannerView.titleLabel.font = [UIFont systemFontOfSize:30.0f];
    bannerView.gradientView.startColor = [UIColor colorWithRed:29.0f/255.0f green:119.0f/255.0f blue:239.0f/255.0f alpha:1.0f];
    bannerView.gradientView.endColor = [UIColor colorWithRed:129.0f/255.0f green:243.0f/255.0f blue:253.0f/255.0f alpha:1.0f];
    return bannerView;
}


#pragma mark Class Methods

+ (NSArray *)defaultEnabledItems {
    return @[kPEHomeViewControllerRowType_Albums,
             kPEHomeViewControllerRowType_Moments,
             kPEHomeViewControllerRowType_AllPhotos,
             kPEHomeViewControllerRowType_Favorites,
             kPEHomeViewControllerRowType_Panoramas,
             kPEHomeViewControllerRowType_Videos,
             kPEHomeViewControllerRowType_Timelapse,
             kPEHomeViewControllerRowType_Bursts,
             kPEHomeViewControllerRowType_SlomoVideos,
             kPEHomeViewControllerRowType_Cloud];
}

+ (NSString *)localizedStringFromRowType:(NSString *)rowType {
    if ([rowType isEqualToString:kPEHomeViewControllerRowType_Albums])
        return NSLocalizedString(@"Albums", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Moments])
        return NSLocalizedString(@"Moments", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Videos])
        return NSLocalizedString(@"Videos", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Panoramas])
        return NSLocalizedString(@"Panoramas", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Timelapse])
        return NSLocalizedString(@"Timelapse", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Favorites])
        return NSLocalizedString(@"Favorites", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Cloud])
        return NSLocalizedString(@"iCloud", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Bursts])
        return NSLocalizedString(@"Bursts", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_SlomoVideos])
        return NSLocalizedString(@"Slo-mo", nil);
    else if ([rowType isEqualToString:kPEHomeViewControllerRowType_AllPhotos])
        return NSLocalizedString(@"Camera Roll", nil);
    return nil;
}

+ (NSString *)rowTypeFromLocalizedString:(NSString *)rowType {
    if ([rowType isEqualToString:NSLocalizedString(@"Albums", nil)])
        return kPEHomeViewControllerRowType_Albums;
    else if ([rowType isEqualToString:NSLocalizedString(@"Moments", nil)])
        return kPEHomeViewControllerRowType_Moments;
    else if ([rowType isEqualToString:NSLocalizedString(@"Videos", nil)])
        return kPEHomeViewControllerRowType_Videos;
    else if ([rowType isEqualToString:NSLocalizedString(@"Panoramas", nil)])
        return kPEHomeViewControllerRowType_Panoramas;
    else if ([rowType isEqualToString:NSLocalizedString(@"Timelapse", nil)])
        return kPEHomeViewControllerRowType_Timelapse;
    else if ([rowType isEqualToString:NSLocalizedString(@"Favorites", nil)])
        return kPEHomeViewControllerRowType_Favorites;
    else if ([rowType isEqualToString:NSLocalizedString(@"iCloud", nil)])
        return kPEHomeViewControllerRowType_Cloud;
    else if ([rowType isEqualToString:NSLocalizedString(@"Bursts", nil)])
        return kPEHomeViewControllerRowType_Bursts;
    else if ([rowType isEqualToString:NSLocalizedString(@"Slo-mo", nil)])
        return kPEHomeViewControllerRowType_SlomoVideos;
    else if ([rowType isEqualToString:NSLocalizedString(@"Camera Roll", nil)])
        return kPEHomeViewControllerRowType_AllPhotos;
    return nil;
}

@end
