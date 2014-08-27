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
#import "PWRefreshControl.h"
#import "PLCollectionFooterView.h"
#import "PAAlbumCollectionViewFlowLayout.h"
#import <BlocksKit+UIKit.h>
#import <Reachability.h>
#import "PASnowFlake.h"
#import <SDImageCache.h>

#import "PDTaskManager.h"

#import "PLModelObject.h"
#import "PLCoreDataAPI.h"

#import "PWPhotoListViewController.h"
#import "PWSearchNavigationController.h"
#import "PWTabBarAdsController.h"
#import "PABaseNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PWSettingsViewController.h"

@interface PWAlbumListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIImageView *noItemImageView;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isRequesting;
@property (nonatomic) BOOL isRefreshControlAnimating;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PWAlbumListViewController

static NSString * const lastUpdateAlbumKey = @"ALVCKEY";

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
    
    self.view.backgroundColor = [PAColors getColor:PWColorsTypeBackgroundLightColor];
    self.navigationController.navigationBar.tintColor = [PAColors getColor:PWColorsTypeTintWebColor];
    
    PAAlbumCollectionViewFlowLayout *collectionViewLayout = [[PAAlbumCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.contentInset = UIEdgeInsetsMake(10.0f, 10.0f, 0.0f, 10.0f);
    _collectionView.backgroundColor = [PAColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    _refreshControl.tintColor = [PAColors getColor:PWColorsTypeTintWebColor];
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[addBarButtonItem, searchBarButtonItem];
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    settingsBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Settings"] insets:UIEdgeInsetsMake(2.0f, 2.0f, 2.0f, 2.0f)];
    self.navigationItem.leftBarButtonItem = settingsBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"%@", error);
        return;
    }
    
    if (_fetchedResultsController.fetchedObjects.count == 0) {
        [_activityIndicatorView startAnimating];
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
    
    [self loadDataWithStartIndex:0];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [UIView animateWithDuration:0.3f animations:^{
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    [tabBarController setAdsHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
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
        indexPath = indexPaths[indexPaths.count / 2];
    }
    
    PWTabBarController *tabBarViewController = (PWTabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 10.0f, 10.0f, viewInsets.bottom, 10.0f);
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
    
    if (_isRequesting && _isRefreshControlAnimating) {
        [_refreshControl beginRefreshing];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"%lu Albums", nil), (unsigned long)_fetchedResultsController.fetchedObjects.count];
        [footerView setText:albumCountString];
    }
    else {
        [footerView setText:nil];
    }
    
    return footerView;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWAlbumObject *album = [_fetchedResultsController objectAtIndexPath:indexPath];
    PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
    [self.navigationController pushViewController:viewController animated:YES];
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
    
    [self loadDataWithStartIndex:0];
}

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
    [tabBarController setTabBarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:YES animated:NO];
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)sself.tabBarController;
        [tabBarController setTabBarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

- (void)addBarButtonAction {
    PWNewAlbumEditViewController *viewController = [[PWNewAlbumEditViewController alloc] init];
    __weak typeof(self) wself = self;
    viewController.successBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself loadDataWithStartIndex:0];
    };
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeWeb];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark LoadData
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
                NSLog(@"%@", error);
                if (error.code == 401) {
                    [sself openLoginViewController];
                }
            }
            else {
                sself.requestIndex = nextIndex;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.refreshControl endRefreshing];
                [sself.activityIndicatorView stopAnimating];
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
            
            [sself loadDataWithStartIndex:0];
        });
    }];
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
        
        [self refreshNoItemWithNumberOfItem:controller.fetchedObjects.count];
    });
}

#pragma mark UIActionSheet
- (void)showAlbumActionSheet:(PWAlbumObject *)album {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.title];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Edit", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself editActionSheetAction:album];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Share", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself shareActionSheetAction:album];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Download", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself downloadActionSheetAction:album];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself deleteActionSheetAction:album];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
    
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)editActionSheetAction:(PWAlbumObject *)album {
    PWAlbumEditViewController *viewController = [[PWAlbumEditViewController alloc] initWithAlbum:album];
    __weak typeof(self) wself = self;
    viewController.successBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself loadDataWithStartIndex:0];
    };
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
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
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
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
            NSLog(@"%@", error);
            return;
        }
        
        [[PDTaskManager sharedManager] addTaskFromWebAlbum:album toLocalAlbum:nil completion:^(NSError *error) {
            if (error) {
                NSLog(@"%@", error);
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
    
    UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] bk_initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.title]];
    __weak typeof(self) wself = self;
    [deleteActionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.center = CGPointMake((sself.view.bounds.size.width / 2) - 20, (sself.view.bounds.size.height / 2) - 130);
        [indicator startAnimating];
        [alertView setValue:indicator forKey:@"accessoryView"];
        [alertView show];
        
        [PWPicasaAPI deleteAlbum:album completion:^(NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
                NSLog(@"%@", error);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView dismissWithClickedButtonIndex:0 animated:YES];
                [sself loadDataWithStartIndex:0];
            });
        }];
    }];
    [deleteActionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    [deleteActionSheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma NoItem
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
        _noItemImageView.image = [[UIImage imageNamed:@"NoPhoto"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _noItemImageView.tintColor = [[PAColors getColor:PWColorsTypeTintWebColor] colorWithAlphaComponent:0.2f];
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
