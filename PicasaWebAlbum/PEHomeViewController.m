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
#import "PADateFormatter.h"
#import "PATabBarAdsController.h"
#import "PWSettingsViewController.h"
#import "PWSearchNavigationController.h"
#import "PECategoryViewCell.h"
#import "PACenterTextTableViewCell.h"
#import "PEScrollBannerHeaderView.h"
#import "PEBannerContentView.h"
#import "PEHorizontalScrollView.h"

#import "PEPhotoDataSourceFactoryMethod.h"
#import "PEAlbumListDataSource.h"
#import "PEMomentListDataSource.h"

#import "PEAlbumListViewController.h"
#import "PEMomentListViewController.h"
#import "PEPhotoListViewController.h"
#import "PEPhotoPageViewController.h"


typedef NS_ENUM(NSUInteger, kPHHomeViewControllerCell) {
    kPHHomeViewControllerCell_Album,
    kPHHomeViewControllerCell_Moment,
    kPHHomeViewControllerCell_Video,
    kPHHomeViewControllerCell_Panorama,
    kPHHomeViewControllerCell_Timelapse,
    kPHHomeViewControllerCell_Favorite,
    kPHHomeViewControllerCell_iCloud,
    kPHHomeViewControllerCell_AllPhotos,
    kPHHomeViewControllerCell_Count
};

@interface PEHomeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIImageView *todayImageView;
@property (strong, nonatomic) UIImageView *yesterdayImageView;
@property (strong, nonatomic) UIImageView *thisWeekImageView;
@property (strong, nonatomic) UIImageView *lastWeekImageView;

@property (strong, nonatomic) PEAlbumListDataSource *albumListDataSource;
@property (strong, nonatomic) PEMomentListDataSource *momentListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *panoramaListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *videoListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *favoriteListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *timelapseListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *cloudListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *allPhotoListDataSource;

@end

@implementation PEHomeViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.title = NSLocalizedString(@"iPhone上の写真", nil);
        }
        else {
            self.title = NSLocalizedString(@"iPad上の写真", nil);
        }
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        _albumListDataSource = [PEAlbumListDataSource new];
        _albumListDataSource.cellSize = CGSizeMake(100.0f, 134.0f);
        _albumListDataSource.minimumLineSpacing = 15.0f;
        __weak typeof(self) wself = self;
        _albumListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        
        _momentListDataSource = [PEMomentListDataSource new];
        _momentListDataSource.cellSize = CGSizeMake(100.0f, 134.0f);
        _momentListDataSource.minimumLineSpacing = 15.0f;
        _momentListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection) {
            typeof(wself) sself = wself;
            if (!sself) return;
            NSString *title = [PEMomentListDataSource titleForMoment:assetCollection];
            PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album title:title];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        
        _panoramaListDataSource = [PEPhotoDataSourceFactoryMethod makePanoramaListDataSource];
        _panoramaListDataSource.cellSize = CGSizeMake(270.0f, 100.0f);
        _panoramaListDataSource.landscapeCellSize = CGSizeMake(270.0f, 100.0f);
        _panoramaListDataSource.minimumLineSpacing = 15.0f;
        _panoramaListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.panoramaListDataSource.assetCollection index:index];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        
        _videoListDataSource = [PEPhotoDataSourceFactoryMethod makeVideoListDataSource];
        _videoListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
        _videoListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
        _videoListDataSource.minimumLineSpacing = 15.0f;
        _videoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.videoListDataSource.assetCollection index:index];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        
        _favoriteListDataSource = [PEPhotoDataSourceFactoryMethod makeFavoriteListDataSource];
        _favoriteListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
        _favoriteListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
        _favoriteListDataSource.minimumLineSpacing = 15.0f;
        _favoriteListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.favoriteListDataSource.assetCollection index:index];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        
        _timelapseListDataSource = [PEPhotoDataSourceFactoryMethod makeTimelapseListDataSource];
        _timelapseListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
        _timelapseListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
        _timelapseListDataSource.minimumLineSpacing = 15.0f;
        _timelapseListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.timelapseListDataSource.assetCollection index:index];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        
        _cloudListDataSource = [PEPhotoDataSourceFactoryMethod makeCloudListDataSource];
        _cloudListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
        _cloudListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
        _cloudListDataSource.minimumLineSpacing = 15.0f;
        _cloudListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.cloudListDataSource.assetCollection index:index];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        
        _allPhotoListDataSource = [PEPhotoDataSourceFactoryMethod makeAllPhotoListDataSource];
        _allPhotoListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
        _allPhotoListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
        _allPhotoListDataSource.minimumLineSpacing = 15.0f;
        _allPhotoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.allPhotoListDataSource.assetCollection index:index];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    self.navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[searchBarButtonItem];
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    settingsBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Settings"] insets:UIEdgeInsetsMake(2.0f, 2.0f, 2.0f, 2.0f)];
    self.navigationItem.leftBarButtonItem = settingsBarButtonItem;
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
    _tableView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _tableView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom + 30.0f, 0.0f);
    _tableView.scrollIndicatorInsets = viewInsets;
    _tableView.contentOffset = CGPointMake(0.0f, -viewInsets.top);
    [self.view addSubview:_tableView];
    
    PEScrollBannerHeaderView *headerView = [PEScrollBannerHeaderView new];
    headerView.frame = CGRectMake(0.0f, 0.0f, 320.0f, 120.0f);
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
    footerView.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    footerView.numberOfLines = 2;
    _tableView.tableFooterView = footerView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [UIView animateWithDuration:0.3f animations:^{
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    [tabBarController setAdsHidden:NO animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
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

- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return kPHHomeViewControllerCell_Count;
    }
    else {
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PECategoryViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PECategoryViewCell class]) forIndexPath:indexPath];
        
        __weak typeof(self) wself = self;
        if (indexPath.row == kPHHomeViewControllerCell_Album) {
            [_albumListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _albumListDataSource;
            cell.delegate = _albumListDataSource;
            cell.titleLabel.text = @"アルバム";
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEAlbumListViewController *viewController = [PEAlbumListViewController new];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Moment) {
            [_momentListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _momentListDataSource;
            cell.delegate = _momentListDataSource;
            cell.titleLabel.text = @"モーメント";
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEMomentListViewController *viewController = [PEMomentListViewController new];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Panorama) {
            [_panoramaListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _panoramaListDataSource;
            cell.delegate = _panoramaListDataSource;
            cell.titleLabel.text = _panoramaListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.panoramaListDataSource.assetCollection type:PHPhotoListViewControllerType_Panorama];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Video) {
            [_videoListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _videoListDataSource;
            cell.delegate = _videoListDataSource;
            cell.titleLabel.text = _videoListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.videoListDataSource.assetCollection type:PHPhotoListViewControllerType_Video];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Favorite) {
            [_favoriteListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _favoriteListDataSource;
            cell.delegate = _favoriteListDataSource;
            cell.titleLabel.text = _favoriteListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.favoriteListDataSource.assetCollection type:PHPhotoListViewControllerType_Favorite];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Timelapse) {
            [_timelapseListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _timelapseListDataSource;
            cell.delegate = _timelapseListDataSource;
            cell.titleLabel.text = _timelapseListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.timelapseListDataSource.assetCollection type:PHPhotoListViewControllerType_Timelapse];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (indexPath.row == kPHHomeViewControllerCell_iCloud) {
            [_cloudListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _cloudListDataSource;
            cell.delegate = _cloudListDataSource;
            cell.titleLabel.text = _cloudListDataSource.assetCollection.localizedTitle;
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:sself.cloudListDataSource.assetCollection type:PHPhotoListViewControllerType_iCloud];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if (indexPath.row == kPHHomeViewControllerCell_AllPhotos) {
            [_allPhotoListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _allPhotoListDataSource;
            cell.delegate = _allPhotoListDataSource;
            cell.titleLabel.text = @"すべての写真とビデオ";
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:nil type:PHPhotoListViewControllerType_AllPhotos];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        
        return cell;
    }
    else {
        PACenterTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PACenterTextTableViewCell class]) forIndexPath:indexPath];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.centerTextLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.textLabel.text = nil;
        cell.centerTextLabel.text = nil;
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"その他";
            cell.textLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (indexPath.row == 1) {
            cell.centerTextLabel.text = @"このアプリを他の人に教える";
            cell.centerTextLabel.textColor = [PAColors getColor:PAColorsTypeTintDefaultColor];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (indexPath.row == 2) {
            cell.centerTextLabel.text = @"広告を除去する";
            cell.centerTextLabel.textColor = [PAColors getColor:PAColorsTypeTintDefaultColor];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == kPHHomeViewControllerCell_Album) {
            return 200.0f;
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Moment) {
            return 200.0f;
        }
        return 170.0f;
    }
    else {
        return 44.0f;
    }
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
            UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[title, url] applicationActivities:nil];
            [self.tabBarController presentViewController:viewController animated:YES completion:nil];
        }
        else if (indexPath.row == 2) {
            [self settingsBarButtonAction];
        }
    }
}

#pragma mark Banner
- (NSMutableArray *)bannerContentViews {
    NSMutableArray *views = @[].mutableCopy;
    {
        NSString *title = NSLocalizedString(@"Today", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate date]];
        NSDate *endDate = [NSDate date];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view)
            [views addObject:view];
    } {
        NSString *title = NSLocalizedString(@"Yesterday", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate dateWithTimeIntervalSinceNow:-(24*60*60)]];
        NSDate *endDate = [NSDate dateWithTimeInterval:(24*60*60) sinceDate:startDate];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view)
            [views addObject:view];
    } {
        NSString *title = NSLocalizedString(@"This Week", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate dateWithTimeIntervalSinceNow:-(24*60*60*7)]];
        NSDate *endDate = [NSDate date];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view)
            [views addObject:view];
    } {
        NSString *title = NSLocalizedString(@"Last Week", nil);
        NSDate *startDate = [PADateFormatter adjustZeroClock:[NSDate dateWithTimeIntervalSinceNow:-(24*60*60*14)]];
        NSDate *endDate = [NSDate dateWithTimeInterval:(24*60*60*7) sinceDate:startDate];
        UIView *view = [self makeBannerViewWithTitle:title startDate:startDate endDate:endDate];
        if (view)
            [views addObject:view];
    }
    return views;
}


- (PEBannerContentView *)makeBannerViewWithTitle:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"(creationDate > %@) AND (creationDate < %@)", startDate, endDate];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
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
        
        PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:nil type:PHPhotoListViewControllerType_Dates title:title startDate:startDate endDate:endDate];
        [sself.navigationController pushViewController:viewController animated:YES];
    };
    PHAsset *asset = fetchResult.firstObject;
    __weak typeof(contentView) wcontentView = contentView;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wcontentView) scontentView = wcontentView;
        if (!scontentView) return;
        scontentView.imageView.image = result;
    }];
    return contentView;
}

- (PEBannerContentView *)noContentBannerView {
    PEBannerContentView *bannerView = [PEBannerContentView new];
    
    bannerView.titleLabel.text = NSLocalizedString(@"Let's take a picture.", nil);
    
    return bannerView;
}

@end
