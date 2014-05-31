//
//  PWPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoListViewController.h"

#import "PWPicasaAPI.h"
#import "PWColors.h"
#import "PWString.h"
#import "PWRefreshControl.h"
#import "BlocksKit+UIKit.h"

#import "PWPhotoViewCell.h"
#import "PWTabBarController.h"
#import "PWNavigationController.h"
#import "PWPhotoPageViewController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PWImagePickerController.h"

@interface PWPhotoListViewController ()

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *moveBarButtonItem;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isNowRequesting;
@property (nonatomic) BOOL isSelectMode;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray *selectedPhotoIDs;

@end

@implementation PWPhotoListViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [super init];
    if (self) {
        _album = album;
        
        self.title = album.title;
        
        _selectedPhotoIDs = @[].mutableCopy;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.autoresizesSubviews = YES;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
//    UIBarButtonItem *mapBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Info"] style:UIBarButtonItemStylePlain target:self action:@selector(mapBarButtonAction)];
//    self.navigationItem.rightBarButtonItem = mapBarButtonItem;
    
    [_refreshControl beginRefreshing];
    [_activityIndicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", sself.album.id_str];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        
        sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        [sself.fetchedResultsController performFetch:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (sself.fetchedResultsController.fetchedObjects.count) {
                [sself.activityIndicatorView stopAnimating];
            }
            
            [sself.collectionView reloadData];
            
            [sself reloadData];
        });
    }];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    _activityIndicatorView.center = self.view.center;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"選択" style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        __weak typeof(self) wself = self;
        [tabBarController setToolbarHidden:NO animated:animated completion:^(BOOL finished) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
            [tabBarController setTabBarHidden:YES animated:NO completion:nil];
        }];
    }
    else {
        [tabBarController setToolbarItems:toolbarItems animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
//- (void)mapBarButtonAction {
//    
//}

- (void)actionBarButtonAction {
    [self showAlbumActionSheet:_album];
}

- (void)addBarButtonAction {
    PWImagePickerController *viewController = [[PWImagePickerController alloc] initWithAlbumTitle:_album.title completion:^(NSArray *selectedPhotos) {
        
    }];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)selectBarButtonAction {
    [self enableSelectMode];
}

- (void)cancelBarButtonAction {
    [self disableSelectMode];
}

- (void)selectActionBarButtonAction {
    
}

- (void)trashBarButtonAction {
    [self showTrashPhotosActionSheet];
}

- (void)moveBarButtonAction {
    
}

#pragma mark UIRefreshControl
- (void)refreshControlAction {
    if (!_isNowRequesting) {
        [self reloadData];
    }
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
    PWPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.isSelectWithCheckMark = _isSelectMode;
    [cell setPhoto:[_fetchedResultsController objectAtIndexPath:indexPath] isNowLoading:_isNowRequesting];;
    
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        return CGSizeMake(112.0f, 112.0f);
    }
    else {
        return CGSizeMake(105.0f, 105.0f);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0f;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        _selectActionBarButton.enabled = YES;
        _trashBarButtonItem.enabled = YES;
        _moveBarButtonItem.enabled = YES;
        
        PWPhotoObject *photo = [_fetchedResultsController objectAtIndexPath:indexPath];
        [_selectedPhotoIDs addObject:photo.id_str];
    }
    else {
        NSArray *photos = [_fetchedResultsController fetchedObjects];
        PWPhotoPageViewController *viewController = [[PWPhotoPageViewController alloc] initWithPhotos:photos index:indexPath.row];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        if (_collectionView.indexPathsForSelectedItems.count == 0) {
            _selectActionBarButton.enabled = NO;
            _trashBarButtonItem.enabled = NO;
            _moveBarButtonItem.enabled = NO;
        }
        
        PWPhotoObject *photo = [_fetchedResultsController objectAtIndexPath:indexPath];
        [_selectedPhotoIDs removeObject:photo.id_str];
    }
}

#pragma mark SelectMode
- (void)enableSelectMode {
    if (_isSelectMode) {
        return;
    }
    _isSelectMode = YES;
    _selectedPhotoIDs = @[].mutableCopy;
    
    _collectionView.allowsMultipleSelection = YES;
    for (PWPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = YES;
    }
    
    _selectActionBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction)];
    _selectActionBarButton.enabled = NO;
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction)];
    _trashBarButtonItem.enabled = NO;
    _moveBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"移動" style:UIBarButtonItemStylePlain target:self action:@selector(moveBarButtonAction)];
    _moveBarButtonItem.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButton, flexibleSpace, _moveBarButtonItem, flexibleSpace, _trashBarButtonItem];
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    [cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]} forState:UIControlStateNormal];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@"項目を選択"];
    [navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:NO];
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationBarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.navigationController.navigationBar.alpha = 0.0f;
    }];
	if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
		self.navigationController.interactivePopGestureRecognizer.enabled = NO;
	}
        
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)disableSelectMode {
    if (!_isSelectMode) {
        return;
    }
    _isSelectMode = NO;
    _selectedPhotoIDs = @[].mutableCopy;
    
    _collectionView.allowsMultipleSelection = YES;
    for (PWPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = NO;
    }
    NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setToolbarHidden:NO animated:NO completion:nil];
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    
    self.navigationController.navigationBar.alpha = 1.0f;
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    
	if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
		self.navigationController.interactivePopGestureRecognizer.enabled = YES;
	}
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark LoadData
- (void)loadDataWithStartIndex:(NSUInteger)index {
    __weak typeof(self) wself = self;
    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:_album.id_str index:index completion:^(NSArray *photos, NSUInteger nextIndex, NSError *error) {
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.collectionView reloadData];
        });
    }];
}

- (void)reloadData {
    _isNowRequesting = YES;
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:_album.id_str index:0 completion:^(NSArray *photos, NSUInteger nextIndex, NSError *error) {
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
        [sself.fetchedResultsController performFetch:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
            
            sself.isNowRequesting = NO;
            [sself.collectionView reloadData];
            
            NSArray *photos = sself.fetchedResultsController.fetchedObjects;
            for (NSString *id_str in sself.selectedPhotoIDs) {
                NSArray *searched = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
                for (PWPhotoObject *photo in searched) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[photos indexOfObject:photo] inSection:0];
                    [sself.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                }
            }
        });
    }];
}

- (void)openLoginviewController {
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.refreshControl endRefreshing];
        
        UIViewController *viewController = [PWOAuthManager loginViewControllerWithCompletion:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself reloadData];
        }];
        
        [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
    });
}

#pragma mark Action
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

- (void)showTrashPhotosActionSheet {
    __weak typeof(self) wself = self;
    NSArray *photos = [_fetchedResultsController fetchedObjects];
    [PWPhotoObject getCountFromPhotoObjects:photos completion:^(NSUInteger countOfPhoto, NSUInteger countOfVideo) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSString *itemString = [PWString itemNameFromPhotoCount:countOfPhoto videoCount:countOfVideo];
        NSString *deleteButton = [NSString stringWithFormat:@"%@を削除", itemString];
        NSString *cancelButton = @"Cancel";
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:nil];
        [actionSheet bk_setDestructiveButtonWithTitle:deleteButton handler:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"写真を削除しています", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            
            NSArray *indexPaths = sself.collectionView.indexPathsForSelectedItems;
            NSUInteger maxCount = indexPaths.count;
            __block NSUInteger count = 0;
            for (NSIndexPath *indexPath in indexPaths) {
                PWPhotoObject *photo = [sself.fetchedResultsController objectAtIndexPath:indexPath];
                [PWPicasaAPI deletePhoto:photo completion:^(NSError *error) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    
                    count++;
                    if (count == maxCount) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [alertView dismissWithClickedButtonIndex:0 animated:YES];
                            [sself reloadData];
                        });
                    }
                    
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                }];
            }
        }];
        [actionSheet bk_setCancelButtonWithTitle:cancelButton handler:nil];
        
        [actionSheet showFromTabBar:sself.tabBarController.tabBar];
    }];
}

@end
