//
//  PWAlbumViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumListViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PWPicasaAPI.h"
#import "PWAlbumViewCell.h"
#import "PWPhotoViewCell.h"
#import "PWRefreshControl.h"
#import "PAHorizontalScrollView.h"
#import "PWHorizontalScrollHeaderView.h"
#import "PLCollectionFooterView.h"
#import "PAAlbumCollectionViewFlowLayout.h"
#import "PDTaskManager.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PASnowFlake.h"
#import <Reachability.h>
#import <SDImageCache.h>

#import "PWPhotoListViewController.h"
#import "PWPhotoPageViewController.h"
#import "PWSearchNavigationController.h"
#import "PATabBarAdsController.h"
#import "PABaseNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PXSettingsViewController.h"

@interface PWAlbumListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionView *recentlyUploadedCollectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIImageView *noItemImageView;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isRequesting;
@property (nonatomic) BOOL isRecentlyUploadedRequesting;
@property (nonatomic) BOOL isRefreshControlAnimating;

@property (nonatomic) BOOL isSelectMode;
@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *organizeBarButtonItem;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *recentlyUploadedFetchedResultsController;

@property (strong, nonatomic) id actionSheetItem;

@end

@implementation PWAlbumListViewController

static NSString * const lastUpdateAlbumKey = @"ALVCKEY";
static NSUInteger const kPWAlbumListViewControllerMaxNumberOfRecentlyUploaded = 50;

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Web Album", nil);
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    self.navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[addBarButtonItem, searchBarButtonItem];
    UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editBarButtonItem:)];
    self.navigationItem.leftBarButtonItem = editBarButtonItem;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    PAAlbumCollectionViewFlowLayout *collectionViewLayout = [PAAlbumCollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PWHorizontalScrollHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.contentInset = UIEdgeInsetsMake(10.0f, 10.0f, 0.0f, 10.0f);
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [PWRefreshControl new];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    _refreshControl.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        abort();
    }
    NSFetchRequest *recentlyUploadedRequest = [NSFetchRequest new];
    recentlyUploadedRequest.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    recentlyUploadedRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO]];
    recentlyUploadedRequest.fetchLimit = kPWAlbumListViewControllerMaxNumberOfRecentlyUploaded;
    _recentlyUploadedFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:recentlyUploadedRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _recentlyUploadedFetchedResultsController.delegate = self;
    if (![_recentlyUploadedFetchedResultsController performFetch:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        abort();
    }
    
    if (_fetchedResultsController.fetchedObjects.count == 0) {
        [_activityIndicatorView startAnimating];
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
    
    [self loadRecentlyUploadedPhotos];
    [self loadDataWithStartIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    for (NSIndexPath *indexPath in _recentlyUploadedCollectionView.indexPathsForSelectedItems) {
        [_recentlyUploadedCollectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [tabBarController setToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:NO animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _isRefreshControlAnimating = _refreshControl.isRefreshing;
    if (_refreshControl.isRefreshing) {
        [_refreshControl endRefreshing];
    }
    
    CGRect rect = self.view.bounds;
    
    NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {return [obj1 compare:obj2];}];
    NSIndexPath *indexPath = nil;
    if (indexPaths.count > 0) {
        NSIndexPath *firstIndexPath = indexPaths.firstObject;
        if (!(firstIndexPath.item == 0 && firstIndexPath.section == 0)) {
            indexPath = indexPaths[indexPaths.count / 2];
        }
    }
    
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    _collectionView.frame = rect;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    
    _activityIndicatorView.center = self.view.center;
    
    [self layoutNoItem];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if ((_isRequesting || _isRecentlyUploadedRequesting) && _isRefreshControlAnimating) {
        [_refreshControl beginRefreshing];
    }
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (collectionView == _collectionView) {
        return _fetchedResultsController.sections.count;
    }
    else if (collectionView == _recentlyUploadedCollectionView) {
        return _recentlyUploadedFetchedResultsController.sections.count;
    }
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == _collectionView) {
        id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
        return [sectionInfo numberOfObjects];
    }
    else if (collectionView == _recentlyUploadedCollectionView) {
        id<NSFetchedResultsSectionInfo> sectionInfo = _recentlyUploadedFetchedResultsController.sections[section];
        NSUInteger numberObItems = [sectionInfo numberOfObjects];
        if (numberObItems > kPWAlbumListViewControllerMaxNumberOfRecentlyUploaded) {
            numberObItems = kPWAlbumListViewControllerMaxNumberOfRecentlyUploaded;
        }
        return numberObItems;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        PWAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        
        PWAlbumObject *album = [_fetchedResultsController objectAtIndexPath:indexPath];
        cell.album = album;
        __weak typeof(self) wself = self;
        cell.actionButtonActionBlock = ^(PWAlbumObject *album) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself showAlbumActionSheet:album];
        };
        
        return cell;
    }
    else if (collectionView == _recentlyUploadedCollectionView) {
        PWPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(PWPhotoViewCell.class) forIndexPath:indexPath];
        
        cell.photo = [_recentlyUploadedFetchedResultsController objectAtIndexPath:indexPath];
        cell.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
        
        return cell;
    }
    return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            PWHorizontalScrollHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
            
            headerView.horizontalScrollView.dataSource = self;
            headerView.horizontalScrollView.delegate = self;
            _recentlyUploadedCollectionView = headerView.horizontalScrollView.collectionView;
            headerView.moreButton.hidden = YES;
            headerView.greaterThanImageView.hidden = YES;
            
            return headerView;
        }
        else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
            PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
            
            if (_fetchedResultsController.fetchedObjects.count > 0) {
                NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"- %lu Albums -", nil), (unsigned long)_fetchedResultsController.fetchedObjects.count];
                [footerView setText:albumCountString];
            }
            else {
                [footerView setText:nil];
            }
            
            return footerView;
        }
    }
    else if (collectionView == _recentlyUploadedCollectionView) {
        return nil;
    }
    return nil;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        return [PAAlbumCollectionViewFlowLayout itemSize];
    }
    return CGSizeMake(90.0f, 90.0f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (collectionView == _collectionView) {
        return CGSizeMake(0.0f, 216.0f);
    }
    else if (collectionView == _recentlyUploadedCollectionView) {
        return CGSizeZero;
    }
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (collectionView == _collectionView) {
        return CGSizeMake(0.0f, 50.0f);
    }
    else if (collectionView == _recentlyUploadedCollectionView) {
        return CGSizeZero;
    }
    return CGSizeZero;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        PWAlbumObject *album = [_fetchedResultsController objectAtIndexPath:indexPath];
        PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else if (collectionView == _recentlyUploadedCollectionView) {
        PWPhotoViewCell *cell = (PWPhotoViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        NSArray *photos = _recentlyUploadedFetchedResultsController.fetchedObjects;
        if (photos.count > kPWAlbumListViewControllerMaxNumberOfRecentlyUploaded) {
            NSMutableArray *tmpPhotos = @[].mutableCopy;
            for (int i=0; i<kPWAlbumListViewControllerMaxNumberOfRecentlyUploaded; i++) {
                PWPhotoObject *photo = tmpPhotos[i];
                [tmpPhotos addObject:photo];
            }
            photos = tmpPhotos;
        }
        PWPhotoPageViewController *viewController = [[PWPhotoPageViewController alloc] initWithPhotos:photos index:indexPath.item placeholder:cell.image cache:[NSCache new]];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark UIRefreshControl
- (void)refreshControlAction {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not connected to network", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
    
    [self loadRecentlyUploadedPhotos];
    [self loadDataWithStartIndex:0];
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

- (void)addBarButtonAction {
    PWNewAlbumEditViewController *viewController = [PWNewAlbumEditViewController new];
    __weak typeof(self) wself = self;
    viewController.successBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself loadRecentlyUploadedPhotos];
        [sself loadDataWithStartIndex:0];
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

- (void)editBarButtonItem:(id)sender {
    [self enableSelectMode];
}

- (void)selectActionBarButtonAction:(id)sender {
    
}

- (void)selectTrashBarButtonAction:(id)sender {
    
}

- (void)selectOrganizeBarButtonAction:(id)sender {
    
}

- (void)selectCancelBarButtonAction:(id)sender {
    [self disableSelectMode];
}

#pragma mark LoadData
- (void)loadRecentlyUploadedPhotos {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_refreshControl endRefreshing];
        });
        return;
    };
    
    if (_isRecentlyUploadedRequesting) {
        return;
    }
    _isRecentlyUploadedRequesting = YES;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [PWPicasaAPI getListOfRecentlyUploadedPhotosWithCompletion:^(NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.isRecentlyUploadedRequesting = NO;
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                if (error.code == 401) {
                    if ([PWOAuthManager shouldOpenLoginViewController]) {
                        [sself openLoginViewController];
                    }
                    else {
                        [PWOAuthManager incrementCountOfLoginError];
                        [sself loadRecentlyUploadedPhotos];
                    }
                }
            }
            [PWOAuthManager resetCountOfLoginError];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!sself.isRequesting) {
                    [sself.refreshControl endRefreshing];
                    [sself.activityIndicatorView stopAnimating];
                }
            });
        }];
    });
}

- (void)loadDataWithStartIndex:(NSUInteger)index {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_refreshControl endRefreshing];
        });
        return;
    };
    
    if (_isRequesting) {
        return;
    }
    _isRequesting = YES;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [PWPicasaAPI getListOfAlbumsWithIndex:index completion:^(NSUInteger nextIndex, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.isRequesting = NO;
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                if (error.code == 401) {
                    if ([PWOAuthManager shouldOpenLoginViewController]) {
                        [sself openLoginViewController];
                    }
                    else {
                        [PWOAuthManager incrementCountOfLoginError];
                        [sself loadDataWithStartIndex:index];
                    }
                }
            }
            else {
                sself.requestIndex = nextIndex;
            }
            [PWOAuthManager resetCountOfLoginError];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!sself.isRecentlyUploadedRequesting) {
                    [sself.refreshControl endRefreshing];
                    [sself.activityIndicatorView stopAnimating];
                }
            });
        }];
    });
}

- (void)openLoginViewController {
    __weak typeof(self) wself = self;
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
            [sself loadRecentlyUploadedPhotos];
            [sself loadDataWithStartIndex:0];
        });
    }];
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (controller == _fetchedResultsController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_collectionView reloadData];
            
            [self refreshNoItemWithNumberOfItem:controller.fetchedObjects.count];
        });
    }
    else if (controller == _recentlyUploadedFetchedResultsController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_recentlyUploadedCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        });
    }
}

#pragma mark UIActionSheet
- (void)showAlbumActionSheet:(PWAlbumObject *)album {
    _actionSheetItem = album;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:album.title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:NSLocalizedString(@"Edit", nil), NSLocalizedString(@"Share", nil), NSLocalizedString(@"Download", nil), nil];
    actionSheet.tag = 1001;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)editActionSheetAction:(PWAlbumObject *)album {
    PWAlbumEditViewController *viewController = [[PWAlbumEditViewController alloc] initWithAlbum:album];
    __weak typeof(self) wself = self;
    viewController.successBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself loadRecentlyUploadedPhotos];
        [sself loadDataWithStartIndex:0];
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

- (void)shareActionSheetAction:(PWAlbumObject *)album {
    PWAlbumShareViewController *viewController = [[PWAlbumShareViewController alloc] initWithAlbum:album];
    __weak typeof(self) wself = self;
    viewController.changedAlbumBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.collectionView reloadItemsAtIndexPaths:sself.collectionView.indexPathsForVisibleItems];
        });
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

- (void)downloadActionSheetAction:(PWAlbumObject *)album {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not connected to network", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading...", nil) message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    [alertView show];
    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:album.id_str index:0 completion:^(NSUInteger nextIndex, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        
        [[PDTaskManager sharedManager] addTaskFromWebAlbum:album toLocalAlbum:nil completion:^(NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            });
        }];
    }];
}

- (void)deleteActionSheetAction:(PWAlbumObject *)album {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not connected to network", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
        return;
    }
    
    _actionSheetItem = album;
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.title];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    actionSheet.tag = 1002;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)deleteAlbum:(PWAlbumObject *)album {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    [alertView show];
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI deleteAlbum:album completion:^(NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
            [sself loadRecentlyUploadedPhotos];
            [sself loadDataWithStartIndex:0];
        });
    }];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == 1001) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Edit", nil)]) {
            [self editActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Share", nil)]) {
            [self shareActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Download", nil)]) {
            [self downloadActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            [self deleteActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1002) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            [self deleteAlbum:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
}

#pragma mark SelectMode
- (void)enableSelectMode {
    if (_isSelectMode) {
        return;
    }
    _isSelectMode = YES;
//    _selectedPhotoIDs = @[].mutableCopy;
    
    _collectionView.allowsMultipleSelection = YES;
    for (PWPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = YES;
    }
    
    _selectActionBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction:)];
    _selectActionBarButton.enabled = NO;
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(selectTrashBarButtonAction:)];
    _trashBarButtonItem.enabled = NO;
    _organizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(selectOrganizeBarButtonAction:)];
    _organizeBarButtonItem.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButton, flexibleSpace, _organizeBarButtonItem, flexibleSpace, _trashBarButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PAColors getColor:PAColorsTypeTintWebColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(selectCancelBarButtonAction:)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Select items", nil)];
    [navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:NO];
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationTintColor:[PAColors getColor:PAColorsTypeTintWebColor]];
    [tabBarController setActionNavigationBarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.navigationController.navigationBar.alpha = 0.0f;
    }];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)disableSelectMode {
    if (!_isSelectMode) {
        return;
    }
    _isSelectMode = NO;
//    _selectedPhotoIDs = @[].mutableCopy;
    
    _collectionView.allowsMultipleSelection = YES;
    for (PWPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = NO;
    }
    NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:NO animated:NO completion:nil];
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    self.navigationController.navigationBar.alpha = 1.0f;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark NoItem
- (void)refreshNoItemWithNumberOfItem:(NSUInteger)numberOfItem {
    if (numberOfItem == 0) {
        [self showNoItem];
    }
    else {
        [self hideNoItem];
    }
}

- (void)showNoItem {
    if (!_noItemImageView) {
        _noItemImageView = [UIImageView new];
        _noItemImageView.image = [UIImage imageNamed:@"icon_240"];
        _noItemImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view insertSubview:_noItemImageView aboveSubview:_collectionView];
    }
}

- (void)hideNoItem {
    if (_noItemImageView) {
        [_noItemImageView removeFromSuperview];
        _noItemImageView = nil;
    }
}

- (void)layoutNoItem {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _noItemImageView.frame = CGRectMake(0.0f, 0.0f, 240.0f, 240.0f);
    }
    else {
        _noItemImageView.frame = CGRectMake(0.0f, 0.0f, 440.0f, 440.0f);
    }
    _noItemImageView.center = self.view.center;
}

@end
