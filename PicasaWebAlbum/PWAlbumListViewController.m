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

@property (strong, nonatomic) NSMutableArray *albums;
@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isDisplayed;
@property (strong, nonatomic) NSString *searchText;
@property (nonatomic) BOOL isSelectMode;

@end

@implementation PWAlbumListViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"ウェブアルバム";
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"Picasa"] selectedImage:[UIImage imageNamed:@"PicasaSelected"]];
        
        _albums = [NSMutableArray array];
    }
    return self;
}

- (id)initWithSearchText:(NSString *)searchText {
    self = [self init];
    if (self) {
        self.title = searchText;
        
        _searchText = searchText;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
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
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
    if (!_searchText) {
        UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
        UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
        self.navigationItem.rightBarButtonItems = @[addBarButtonItem, searchBarButtonItem];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    }
    
    [_refreshControl beginRefreshing];
    [self loadLocalData];
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = CGRectMake(10.0f, 0.0f, rect.size.width - 20.0f, rect.size.height);
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
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
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _albums.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _isDisplayed = YES;
    
    PWAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.album = _albums[indexPath.row];
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
    PWAlbumObject *album = _albums[indexPath.row];
    PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark UIRefreshControl
- (void)refreshControlAction {
    [self reloadData];
}

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    [navigationController openSearchBarWithPredicate:^NSArray *(NSString *word) {
        __block NSArray *titles = nil;
        
        [PWCoreDataAPI performBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            request.entity = [NSEntityDescription entityForName:@"PWAlbumManagedObject" inManagedObjectContext:context];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
            if (word) {
                request.predicate = [NSPredicate predicateWithFormat:@"title contains %@", word];
            }
            NSError *error;
            NSArray *albums = [context executeFetchRequest:request error:&error];
            NSMutableArray *mutableTitles = [NSMutableArray array];
            for (PWAlbumObject *album in albums) {
                [mutableTitles addObject:album.title];
            }
            titles = mutableTitles.copy;
        }];
        
        return titles;
    } completion:^UIViewController *(NSString *searchText) {
        PWAlbumListViewController *viewController = [[PWAlbumListViewController alloc] initWithSearchText:searchText];
        return viewController;
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sself.refreshControl endRefreshing];
                    UIViewController *viewController = [PWOAuthManager loginViewControllerWithCompletion:^{
                        [sself loadDataWithStartIndex:index];
                    }];
                    [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
                });
            }
            return;
        }
        
        sself.requestIndex = nextIndex;
        [sself.albums addObjectsFromArray:albums];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.collectionView reloadData];
        });
    }];
}

- (void)reloadData {
    __weak typeof(self) wself = self;
    [PWPicasaAPI getListOfAlbumsWithIndex:0 completion:^(NSArray *albums, NSUInteger nextIndex, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (error) {
            NSLog(@"%@", error);
            if (error.code == 401) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sself.refreshControl endRefreshing];
                    UIViewController *viewController = [PWOAuthManager loginViewControllerWithCompletion:^{
                        [sself reloadData];
                    }];
                    [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
                });
            }
            return;
        }
        
        sself.requestIndex = nextIndex;
        sself.albums = albums.mutableCopy;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.activityIndicatorView stopAnimating];
            [sself.refreshControl endRefreshing];
            [sself.collectionView reloadData];
        });
        
        NSMutableArray *deleteAlbums = albums.mutableCopy;
        for (PWAlbumObject *album in albums) {
            for (PWAlbumObject *deleteAlbum in deleteAlbums) {
                if ([album.id_str isEqualToString:deleteAlbum.id_str]) {
                    [deleteAlbums removeObject:deleteAlbum];
                    break;
                }
            }
        }
        if (deleteAlbums.count > 0) {
            [PWCoreDataAPI performBlockAndWait:^(NSManagedObjectContext *context) {
                for (PWAlbumObject *album in deleteAlbums) {
                    [context deleteObject:album];
                }
                [context save:nil];
            }];
        }
    }];
}

- (void)loadLocalData {
    [_activityIndicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    [PWCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:@"PWAlbumManagedObject" inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        NSString *searchText = sself.searchText;
        if (searchText) {
            request.predicate = [NSPredicate predicateWithFormat:@"title contains %@", searchText];
        }
        NSError *error;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        
        sself.albums = albums.mutableCopy;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sself.albums.count > 0) {
                [sself.activityIndicatorView stopAnimating];
                if (!sself.isDisplayed) {
                    [sself.collectionView reloadData];
                }
            }
            
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
                    return;
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
