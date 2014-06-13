//
//  PWAlbumViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumListViewController.h"

#import "PWColors.h"
#import "PWPicasaAPI.h"
#import "PWAlbumViewCell.h"
#import "PWRefreshControl.h"
#import "BlocksKit+UIKit.h"
#import "PWSnowFlake.h"

#import "PDTaskManager.h"

#import "PLModelObject.h"
#import "PLCoreDataAPI.h"

#import "PWPhotoListViewController.h"
#import "PWSearchNavigationController.h"
#import "PWTabBarController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"

@interface PWAlbumListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isNowRequesting;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PWAlbumListViewController

static NSString * const lastUpdateAlbumKey = @"ALVCKEY";

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"ウェブアルバム";
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"Picasa"] selectedImage:[UIImage imageNamed:@"PicasaSelected"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    self.navigationController.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.contentInset = UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 0.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -10.0f);
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.myContentInsetTop = 10.0f;
    _refreshControl.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[addBarButtonItem, searchBarButtonItem];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(actionBarButtonAction)];
    
    [_refreshControl beginRefreshing];
    [_activityIndicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:@"PWAlbumManagedObject" inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        NSError *error = nil;
        [sself.fetchedResultsController performFetch:&error];
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sself.fetchedResultsController.fetchedObjects.count > 0) {
                [sself.activityIndicatorView stopAnimating];
            }
            
            [sself.collectionView reloadData];
            
            [sself reloadData];
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [tabBarController setToolbarHidden:YES animated:animated completion:nil];
    
    if (!_isNowRequesting) {
        [_refreshControl endRefreshing];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = CGRectMake(10.0f, 0.0f, rect.size.width - 20.0f, rect.size.height);

    NSArray *indexPaths = _collectionView.indexPathsForVisibleItems;
    NSIndexPath *indexPath = nil;
    if (indexPaths.count) {
        indexPath = indexPaths[indexPaths.count / 2];
    }
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    
    _activityIndicatorView.center = self.view.center;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem - Depricated
- (void)actionBarButtonAction {
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[_fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PWAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    [cell setAlbum:[_fetchedResultsController objectAtIndexPath:indexPath] isNowLoading:_isNowRequesting];
    __weak typeof(self) wself = self;
    [cell setActionButtonActionBlock:^(PWAlbumObject *album) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself showAlbumActionSheet:album];
    }];
    
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        return CGSizeMake(177.0f, ceilf(177.0f * 3.0f / 4.0f) + 40.0f);
    }
    else {
        return CGSizeMake(146.0f, ceilf(146.0f * 3.0f / 4.0f) + 40.0f);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 8.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 8.0f;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWAlbumObject *album = [_fetchedResultsController objectAtIndexPath:indexPath];
    PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark UIRefreshControl
- (void)refreshControlAction {
    if (!_isNowRequesting) {
        [self reloadData];
    }
}

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setTabBarHidden:YES animated:YES completion:nil];
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    }];
}

- (void)addBarButtonAction {
    PWNewAlbumEditViewController *viewController = [[PWNewAlbumEditViewController alloc] init];
    __weak typeof(self) wself = self;
    [viewController setSuccessBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself reloadData];
    }];
    PWNavigationController *navigationController = [[PWNavigationController alloc] initWithRootViewController:viewController];
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark LoadData
- (void)loadDataWithStartIndex:(NSUInteger)index {
    __weak typeof(self) wself = self;
    [PWPicasaAPI getListOfAlbumsWithIndex:index completion:^(NSArray *albums, NSUInteger nextIndex, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (error) {
            NSLog(@"%@", error);
            if (error.code == 401) {
                [sself openLoginviewController];
            }
            return;
        }
        
        sself.requestIndex = nextIndex;
        NSError *coredataError = nil;
        [sself.fetchedResultsController performFetch:&coredataError];
        if (coredataError) {
            NSLog(@"%@", coredataError.description);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
            
            [sself.collectionView reloadData];
        });
    }];
}

- (void)reloadData {
    _isNowRequesting = YES;
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI getListOfAlbumsWithIndex:0 completion:^(NSArray *albums, NSUInteger nextIndex, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (error) {
            NSLog(@"%@", error);
            if (error.code == 401) {
                [sself openLoginviewController];
            }
            return;
        }
        
        sself.requestIndex = nextIndex;
        
        [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            NSError *coredataError = nil;
            [sself.fetchedResultsController performFetch:&coredataError];
            if (coredataError) {
                NSLog(@"%@", coredataError.description);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.refreshControl endRefreshing];
                [sself.activityIndicatorView stopAnimating];
                
                sself.isNowRequesting = NO;
                [sself.collectionView reloadData];
            });
        }];
    }];
}

- (void)openLoginviewController {
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
            
            [sself reloadData];
        });
    }];
}

#pragma mark UIActionSheet
- (void)showAlbumActionSheet:(PWAlbumObject *)album {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.title];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"情報", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWAlbumEditViewController *viewController = [[PWAlbumEditViewController alloc] initWithAlbum:album];
        [viewController setSuccessBlock:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself reloadData];
        }];
        PWNavigationController *navigationController = [[PWNavigationController alloc] initWithRootViewController:viewController];
        [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"共有", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWAlbumShareViewController *viewController = [[PWAlbumShareViewController alloc] initWithAlbum:album];
        [viewController setChangedAlbumBlock:^(NSString *retAccess, NSSet *link) {
            album.link = link;
            album.gphoto.access = retAccess;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.collectionView reloadItemsAtIndexPaths:sself.collectionView.indexPathsForVisibleItems];
            });
        }];
        PWNavigationController *navigationController = [[PWNavigationController alloc] initWithRootViewController:viewController];
        [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"ダウンロード", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:album.id_str index:0 completion:^(NSArray *photos, NSUInteger nextIndex, NSError *error) {
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [PDTaskManager addTaskFromWebAlbum:album toLocalAlbum:nil completion:^(NSError *error) {
                    NSLog(@"added");
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                    
//                    dispatch_after(1.0f, dispatch_get_main_queue(), ^{
//                        [PDTaskManager resumeAllTasks];
//                    });
                }];
            });
        }];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"削除", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] bk_initWithTitle:NSLocalizedString(@"本当に削除しますか？アルバム内の写真はすべて削除されます。", nil)];
        [deleteActionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"削除する", nil) handler:^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"アルバムを削除しています", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            
            [PWPicasaAPI deleteAlbum:album completion:^(NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                
                if (error) {
                    NSLog(@"%@", error.description);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alertView dismissWithClickedButtonIndex:0 animated:YES];
                    [sself reloadData];
                });
            }];
        }];
        [deleteActionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
        
        [deleteActionSheet showFromTabBar:sself.tabBarController.tabBar];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{
        
    }];
    
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

@end
