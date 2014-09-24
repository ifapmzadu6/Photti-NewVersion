//
//  PHHomeViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHHomeViewController.h"

@import Photos;

#import "PAColors.h"
#import "PAIcons.h"
#import "PAString.h"
#import "PATabBarAdsController.h"
#import "PWSettingsViewController.h"
#import "PWSearchNavigationController.h"
#import "PHCategoryViewCell.h"
#import "PACenterTextTableViewCell.h"
#import "PHScrollBannerHeaderView.h"
#import "PAGradientView.h"
#import "PHHorizontalScrollView.h"

#import "PHAlbumListDataSource.h"
#import "PHMomentListDataSource.h"
#import "PHPanoramaListDataSource.h"
#import "PHVideoListDataSource.h"


typedef NS_ENUM(NSUInteger, kPHHomeViewControllerCell) {
    kPHHomeViewControllerCell_Album,
    kPHHomeViewControllerCell_Moment,
    kPHHomeViewControllerCell_Video,
    kPHHomeViewControllerCell_Panorama,
    kPHHomeViewControllerCell_Timelapse,
    kPHHomeViewControllerCell_Screenshot,
    kPHHomeViewControllerCell_iCloud,
    kPHHomeViewControllerCell_AllPhotos,
    kPHHomeViewControllerCell_Count
};

@interface PHHomeViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) UIImageView *todayImageView;

@property (strong, nonatomic) PHAlbumListDataSource *albumListDataSource;
@property (strong, nonatomic) PHMomentListDataSource *momentListDataSource;
@property (strong, nonatomic) PHPanoramaListDataSource *panoramaListDataSource;
@property (strong, nonatomic) PHVideoListDataSource *videoListDataSource;

@end

@implementation PHHomeViewController

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
        
        _albumListDataSource = [PHAlbumListDataSource new];
        _albumListDataSource.cellSize = CGSizeMake(100.0f, 134.0f);
        _albumListDataSource.minimumLineSpacing = 15.0f;
        
        _momentListDataSource = [PHMomentListDataSource new];
        _momentListDataSource.cellSize = CGSizeMake(100.0f, 134.0f);
        _momentListDataSource.minimumLineSpacing = 15.0f;
        
        _panoramaListDataSource = [PHPanoramaListDataSource new];
        _panoramaListDataSource.cellSize = CGSizeMake(270.0f, 100.0f);
        _panoramaListDataSource.minimumLineSpacing = 15.0f;
        
        _videoListDataSource = [PHVideoListDataSource new];
        _videoListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
        _videoListDataSource.minimumLineSpacing = 15.0f;
        
        [self test];
    }
    return self;
}

- (void)test {
    PHFetchResult *result = [PHAsset fetchAssetsWithOptions:0];
    PHAsset *firstAsset = result.firstObject;
    [[PHImageManager defaultManager] requestImageForAsset:firstAsset targetSize:CGSizeMake(50.0f, 50.0f) contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions new] resultHandler:^(UIImage *result, NSDictionary *info) {
    }];
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
    [_tableView registerClass:[PACenterTextTableViewCell class] forCellReuseIdentifier:@"CenterCell"];
    [_tableView registerClass:[PHCategoryViewCell class] forCellReuseIdentifier:@"CategoryCell"];
    _tableView.alwaysBounceVertical = YES;
    _tableView.exclusiveTouch = YES;
    _tableView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _tableView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom + 30.0f, 0.0f);
    _tableView.scrollIndicatorInsets = viewInsets;
    _tableView.contentOffset = CGPointMake(0.0f, -viewInsets.top);
    [self.view addSubview:_tableView];
    
    PHScrollBannerHeaderView *headerView = [PHScrollBannerHeaderView new];
    headerView.frame = CGRectMake(0.0f, 0.0f, 320.0f, 120.0f);
    headerView.views = @[[self makeTodayBannerView], [self makeYesterdayBannerView], [self makeWeekBannerView], [self makeLastWeekBannerView]];
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
    navigationController.view.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
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
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeWeb];
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
        return 4;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PHCategoryViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell" forIndexPath:indexPath];
        if (indexPath.row == kPHHomeViewControllerCell_Album) {
            [_albumListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _albumListDataSource;
            cell.delegate = _albumListDataSource;
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Moment) {
            [_momentListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _momentListDataSource;
            cell.delegate = _momentListDataSource;
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Panorama) {
            [_panoramaListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _panoramaListDataSource;
            cell.delegate = _panoramaListDataSource;
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Video) {
            [_videoListDataSource prepareForUse:cell.horizontalScrollView.collectionView];
            cell.dataSource = _videoListDataSource;
            cell.delegate = _videoListDataSource;
        }
        else {
            cell.dataSource = self;
            cell.delegate = self;
        }
        cell.horizontalScrollView.collectionView.tag = indexPath.row;
        
        if (indexPath.row == kPHHomeViewControllerCell_Album) {
            cell.titleLabel.text = @"アルバム";
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Moment) {
            cell.titleLabel.text = @"モーメント";
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Video) {
            cell.titleLabel.text = @"ビデオ";
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Timelapse) {
            cell.titleLabel.text = @"タイムラプス";
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Panorama) {
            cell.titleLabel.text = @"パノラマ";
        }
        else if (indexPath.row == kPHHomeViewControllerCell_Screenshot) {
            cell.titleLabel.text = @"スクリーンショット";
        }
        else if (indexPath.row == kPHHomeViewControllerCell_AllPhotos) {
            cell.titleLabel.text = @"すべての写真とビデオ";
        }
        else if (indexPath.row == kPHHomeViewControllerCell_iCloud) {
            cell.titleLabel.text = @"iCloud上の写真";
        }
        
        return cell;
    }
    else {
        PACenterTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CenterCell" forIndexPath:indexPath];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.centerTextLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.textLabel.text = nil;
        cell.centerTextLabel.text = nil;
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"その他";
            cell.textLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
        }
        else if (indexPath.row == 1) {
            cell.centerTextLabel.text = @"このアプリを他の人に教える";
            cell.centerTextLabel.textColor = [PAColors getColor:PAColorsTypeTintDefaultColor];
        }
        else if (indexPath.row == 2) {
            cell.centerTextLabel.text = @"この作者の他のアプリを見る";
            cell.centerTextLabel.textColor = [PAColors getColor:PAColorsTypeTintDefaultColor];
        }
        else if (indexPath.row == 3) {
            cell.centerTextLabel.text = @"広告を除去する";
            cell.centerTextLabel.textColor = [PAColors getColor:PAColorsTypeTintDefaultColor];
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
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {    
    return 18;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    
    srand((unsigned)time(NULL));
    UIImageView *imageView = [UIImageView new];
    imageView.frame = cell.contentView.bounds;
    NSString *imageName = [NSString stringWithFormat:@"img_%ld", random()%17 + 1];
    imageView.image = [UIImage imageNamed:imageName];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.backgroundColor = [UIColor colorWithWhite:0.7f alpha:1.0f];
    imageView.clipsToBounds = YES;
    [cell.contentView addSubview:imageView];
    
    return cell;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100.0f, 100.0f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 15.0f;
}


#pragma mark MakeBannerView
- (UIView *)makeTodayBannerView {
    UIView *view = [UIView new];
    view.frame = CGRectMake(0.0f, 0.0f, 320.0f, 120.0f);
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.image = [UIImage imageNamed:@"img_16"];
    imageView.frame = view.frame;
    [view addSubview:imageView];
    _todayImageView = imageView;
    
    PAGradientView *gradientView = [PAGradientView new];
    gradientView.startColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    gradientView.endColor = [UIColor clearColor];
    gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gradientView.backgroundColor = [UIColor clearColor];
    gradientView.frame = view.frame;
    [view addSubview:gradientView];
    
    UILabel *todayLabel = [UILabel new];
    todayLabel.text = NSLocalizedString(@"Today", nil);
    todayLabel.font = [UIFont systemFontOfSize:40.0f];
    todayLabel.textColor = [UIColor whiteColor];
    todayLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    todayLabel.frame = CGRectMake(16.0f, 4.0f, CGRectGetWidth(view.bounds) - 16.0f*2.0f, 50.0f);
    [view addSubview:todayLabel];
    
    return view;
}

- (UIView *)makeYesterdayBannerView {
    UIView *view = [UIView new];
    view.frame = CGRectMake(0.0f, 0.0f, 320.0f, 120.0f);
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.image = [UIImage imageNamed:@"img_17"];
    imageView.frame = view.frame;
    [view addSubview:imageView];
    _todayImageView = imageView;
    
    PAGradientView *gradientView = [PAGradientView new];
    gradientView.startColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    gradientView.endColor = [UIColor clearColor];
    gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gradientView.backgroundColor = [UIColor clearColor];
    gradientView.frame = view.frame;
    [view addSubview:gradientView];
    
    UILabel *yesterdayLabel = [UILabel new];
    yesterdayLabel.text = NSLocalizedString(@"Yesterday", nil);
    yesterdayLabel.font = [UIFont systemFontOfSize:40.0f];
    yesterdayLabel.textAlignment = NSTextAlignmentRight;
    yesterdayLabel.textColor = [UIColor whiteColor];
    yesterdayLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    yesterdayLabel.frame = CGRectMake(16.0f, 4.0f, CGRectGetWidth(view.bounds) - 16.0f*2.0f, 50.0f);
    [view addSubview:yesterdayLabel];
    
    return view;
}

- (UIView *)makeWeekBannerView {
    UIView *view = [UIView new];
    view.frame = CGRectMake(0.0f, 0.0f, 320.0f, 120.0f);
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.image = [UIImage imageNamed:@"img_14"];
    imageView.frame = view.frame;
    [view addSubview:imageView];
    _todayImageView = imageView;
    
    PAGradientView *gradientView = [PAGradientView new];
    gradientView.startColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    gradientView.endColor = [UIColor clearColor];
    gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gradientView.backgroundColor = [UIColor clearColor];
    gradientView.frame = view.frame;
    [view addSubview:gradientView];
    
    UILabel *weekLabel = [UILabel new];
    weekLabel.text = NSLocalizedString(@"Week", nil);
    weekLabel.font = [UIFont systemFontOfSize:40.0f];
    weekLabel.textColor = [UIColor whiteColor];
    weekLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    weekLabel.frame = CGRectMake(16.0f, 4.0f, CGRectGetWidth(view.bounds) - 16.0f*2.0f, 50.0f);
    [view addSubview:weekLabel];
    
    return view;
}

- (UIView *)makeLastWeekBannerView {
    UIView *view = [UIView new];
    view.frame = CGRectMake(0.0f, 0.0f, 320.0f, 120.0f);
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.image = [UIImage imageNamed:@"img_13"];
    imageView.frame = view.frame;
    [view addSubview:imageView];
    _todayImageView = imageView;
    
    PAGradientView *gradientView = [PAGradientView new];
    gradientView.startColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    gradientView.endColor = [UIColor clearColor];
    gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gradientView.backgroundColor = [UIColor clearColor];
    gradientView.frame = view.frame;
    [view addSubview:gradientView];
    
    UILabel *lastweekLabel = [UILabel new];
    lastweekLabel.text = NSLocalizedString(@"Last Week", nil);
    lastweekLabel.font = [UIFont systemFontOfSize:40.0f];
    lastweekLabel.textColor = [UIColor whiteColor];
    lastweekLabel.textAlignment = NSTextAlignmentRight;
    lastweekLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    lastweekLabel.frame = CGRectMake(16.0f, 4.0f, CGRectGetWidth(view.bounds) - 16.0f*2.0f, 50.0f);
    [view addSubview:lastweekLabel];
    
    return view;
}


@end
