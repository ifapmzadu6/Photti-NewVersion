//
//  PWAlbumViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumListViewController.h"

@import CoreData;

#import "PAColors.h"
#import "PAIcons.h"
#import "PWPicasaAPI.h"
#import "PWPhotoViewCell.h"
#import "PWRefreshControl.h"
#import "PAHorizontalScrollView.h"
#import "PWHorizontalScrollHeaderView.h"
#import "PLCollectionFooterView.h"
#import "PAAlbumCollectionViewFlowLayout.h"
#import "PDTaskManager.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PDCoreDataAPI.h"
#import "PASnowFlake.h"
#import "PAAlertControllerKit.h"
#import "PRAlbumListDataSource.h"
#import "PRPhotoListDataSource.h"
#import <Reachability.h>
#import <SDImageCache.h>

#import "PAViewControllerKit.h"
#import "PWPhotoListViewController.h"
#import "PWPhotoPageViewController.h"
#import "PASearchNavigationController.h"
#import "PATabBarAdsController.h"
#import "PABaseNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PXSettingsViewController.h"
#import "PDNavigationController.h"
#import "PAActivityIndicatorView.h"


@interface PWAlbumListViewController () <UIActionSheetDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionView *recentlyUploadedCollectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) PRAlbumListDataSource *albumListDataSource;
@property (strong, nonatomic) PRPhotoListDataSource *photoListDataSource;
@property (nonatomic) BOOL isRecentlyUploadedRequesting;
@property (nonatomic) BOOL isRefreshControlAnimating;

@property (strong, nonatomic) id actionSheetItem;

@end

@implementation PWAlbumListViewController

static NSString * const lastUpdateAlbumKey = @"ALVCKEY";

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Web Album", nil);
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        NSManagedObjectContext *context = [PWCoreDataAPI readContext];
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
        __weak typeof(self) wself = self;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        _albumListDataSource = [[PRAlbumListDataSource alloc] initWithFetchRequest:request];
        _albumListDataSource.dataSource = (id)self;
        _albumListDataSource.delegate = (id)self;
        _albumListDataSource.didChangeItemCountBlock = ^(NSUInteger count) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself refreshNoItemWithNumberOfItem:count];
        };
        _albumListDataSource.didSelectAlbumBlock = ^(PWAlbumObject *album, NSUInteger index) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        _albumListDataSource.didRefresh = ^() {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (!sself.isRecentlyUploadedRequesting) {
                [sself.refreshControl endRefreshing];
                [sself.activityIndicatorView stopAnimating];
            }
        };
        _albumListDataSource.openLoginViewController = ^() {
            [PWOAuthManager loginViewControllerWithCompletion:^(UINavigationController *navigationController) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself.refreshControl endRefreshing];
                    [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
                });
            } finish:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself.albumListDataSource loadDataWithStartIndex:0];
                });
            }];
        };
        
        NSFetchRequest *recentlyUploadedRequest = [NSFetchRequest new];
        recentlyUploadedRequest.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
        recentlyUploadedRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO]];
        recentlyUploadedRequest.fetchLimit = 50;
        _photoListDataSource = [[PRPhotoListDataSource alloc] initWithFetchRequest:recentlyUploadedRequest albumID:nil];
        _photoListDataSource.dataSource = (id)self;
        _photoListDataSource.delegate = (id)self;
        _photoListDataSource.didSelectPhotoBlock = ^(PWPhotoObject *photo, id placeholder, NSUInteger index) {
            typeof(wself) sself = wself;
            if (!sself) return;
            NSArray *photos = sself.photoListDataSource.photos;
            if (photos.count > 50) {
                NSMutableArray *tmpPhotos = @[].mutableCopy;
                for (int i=0; i<50; i++) {
                    PWPhotoObject *photo = photos[i];
                    [tmpPhotos addObject:photo];
                }
                photos = tmpPhotos;
            }
            PWPhotoPageViewController *viewController = [[PWPhotoPageViewController alloc] initWithPhotos:photos index:index placeholder:placeholder cache:nil];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    self.navigationController.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[addBarButtonItem, searchBarButtonItem];
    UIBarButtonItem *taskBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Upload"] style:UIBarButtonItemStylePlain target:self action:@selector(taskBarButtonAction:)];
    taskBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Upload"] insets:UIEdgeInsetsMake(2.0f, 2.0f, 2.0f, 2.0f)];
    self.navigationItem.leftBarButtonItems = @[taskBarButtonItem];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    PAAlbumCollectionViewFlowLayout *collectionViewLayout = [PAAlbumCollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _albumListDataSource.collectionView = _collectionView;
    _collectionView.dataSource = _albumListDataSource;
    _collectionView.delegate = _albumListDataSource;
    [_collectionView registerClass:[PWHorizontalScrollHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [PWRefreshControl new];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    _refreshControl.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.view addSubview:_activityIndicatorView];
    
    if (_albumListDataSource.numberOfAlbums == 0) {
        [_activityIndicatorView startAnimating];
    }
    
    [self refreshNoItemWithNumberOfItem:_albumListDataSource.numberOfAlbums];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    for (NSIndexPath *indexPath in _recentlyUploadedCollectionView.indexPathsForSelectedItems) {
        [_recentlyUploadedCollectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    if (_collectionView.indexPathsForVisibleItems.count > 0) {
        [_collectionView reloadItemsAtIndexPaths:_collectionView.indexPathsForVisibleItems];
    }
    if (_recentlyUploadedCollectionView.indexPathsForVisibleItems.count > 0) {
        [_recentlyUploadedCollectionView reloadItemsAtIndexPaths:_recentlyUploadedCollectionView.indexPathsForVisibleItems];
    }
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [tabBarController setToolbarHidden:YES animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    [tabBarController setAdsHidden:NO animated:YES];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _isRefreshControlAnimating = _refreshControl.isRefreshing;
    if (_refreshControl.isRefreshing) {
        [_refreshControl endRefreshing];
    }
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    UIEdgeInsets contentInset = UIEdgeInsetsMake(viewInsets.top, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
    
    _activityIndicatorView.center = self.view.center;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if ((_albumListDataSource.isRequesting || _isRecentlyUploadedRequesting) && _isRefreshControlAnimating) {
        [_refreshControl beginRefreshing];
    }
}

#pragma mark UICollectionViewDataSource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            PWHorizontalScrollHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
            
            _photoListDataSource.collectionView = headerView.horizontalScrollView.collectionView;
            headerView.horizontalScrollView.dataSource = _photoListDataSource;
            headerView.horizontalScrollView.delegate = _photoListDataSource;
            _recentlyUploadedCollectionView = headerView.horizontalScrollView.collectionView;
            headerView.moreButton.hidden = YES;
            headerView.greaterThanImageView.hidden = YES;
            
            return headerView;
        }
    }
    return nil;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        return [PAAlbumCollectionViewFlowLayout itemSize];
    }
    else {
        if (self.isPhone) {
            return CGSizeMake(90.0f, 90.0f);
        }
        else {
            return CGSizeMake(170.0f, 170.0f);
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (collectionView == _collectionView) {
        if (self.isPhone) {
            return CGSizeMake(0.0f, 216.0f);
        }
        else {
            return CGSizeMake(0.0f, 300.0f);
        }
    }
    return CGSizeZero;
}


#pragma mark UIRefreshControl
- (void)refreshControlAction {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [PAAlertControllerKit showNotCollectedToNetwork];
        return;
    }
    
    [_photoListDataSource loadRecentlyUploadedPhotos];
    [_albumListDataSource loadDataWithStartIndex:0];
}

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setTabBarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:YES animated:NO];
    
    PASearchNavigationController *navigationController = (PASearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setTabBarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

- (void)addBarButtonAction {
    PWNewAlbumEditViewController *viewController = [PWNewAlbumEditViewController new];
    __weak typeof(self) wself = self;
    viewController.successBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself.photoListDataSource loadRecentlyUploadedPhotos];
        [sself.albumListDataSource loadDataWithStartIndex:0];
    };
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    if (self.isPhone) {
        navigationController.transitioningDelegate = (id)navigationController;
    }
    else {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)taskBarButtonAction:(id)sender {
    PDNavigationController *navigationController = [PDNavigationController new];
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

@end
