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
#import "SDImageCache.h"
#import "PDTaskManager.h"
#import "Reachability.h"

#import "PWPhotoViewCell.h"
#import "PWTabBarController.h"
#import "PWNavigationController.h"
#import "PWPhotoPageViewController.h"
#import "PWBaseNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PWImagePickerController.h"
#import "PWAlbumPickerController.h"

@interface PWPhotoListViewController ()

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *moveBarButtonItem;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isSelectMode;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) NSMutableArray *selectedPhotoIDs;

@property (weak, nonatomic) PWPhotoPageViewController *photoPageViewController;

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
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setToolbarTintColor:[PWColors getColor:PWColorsTypeTintWebColor]];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.alwaysBounceVertical = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _collectionView.contentInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
    }
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
//    UIBarButtonItem *mapBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Info"] style:UIBarButtonItemStylePlain target:self action:@selector(mapBarButtonAction)];
//    self.navigationItem.rightBarButtonItem = mapBarButtonItem;
    
    [_refreshControl beginRefreshing];
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", _album.id_str];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    [_fetchedResultsController performFetch:nil];
    
    if (_fetchedResultsController.fetchedObjects.count == 0) {
        [_activityIndicatorView startAnimating];
    }
    if (_collectionView.indexPathsForVisibleItems.count == 0) {
        [_collectionView reloadData];
    }
    
    [self reloadData];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = rect;
    
    NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
        return obj1.row > obj2.row;
    }];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_isSelectMode) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
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
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
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
        if (selectedPhotos.count == 0) {
            return;
        }
        
//        [PDTaskManager sharedManager] add
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
    __weak typeof(self) wself = self;
    PWAlbumPickerController *albumPickerController = [[PWAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSMutableArray *selectedPhotos = @[].mutableCopy;
        NSArray *photos = _fetchedResultsController.fetchedObjects;
        for (NSString *id_str in _selectedPhotoIDs) {
            NSArray *searched = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
            if (searched.count > 0) {
                [selectedPhotos addObject:searched.firstObject];
            }
        }
        if (selectedPhotos.count == 0) {
            return;
        }
        
        if (isWebAlbum) {
            PWAlbumObject *webAlbum = (PWAlbumObject *)album;
            [[PDTaskManager sharedManager] addTaskFromLocalPhotos:selectedPhotos toWebAlbum:webAlbum completion:^(NSError *error) {
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                
                NSLog(@"web album added tasks");
            }];
        }
        else {
            PLAlbumObject *localAlbum = (PLAlbumObject *)album;
            [[PDTaskManager sharedManager] addTaskFromWebPhotos:selectedPhotos toLocalAlbum:localAlbum completion:^(NSError *error) {
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                
                NSLog(@"local album added tasks");
            }];
        }
        
        [sself disableSelectMode];
    }];
    albumPickerController.prompt = NSLocalizedString(@"Choose an album to copy to.", nil);
    [self.tabBarController presentViewController:albumPickerController animated:YES completion:nil];
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
    
    [self reloadData];
    
    [self moveImageCacheFromDiskToMemoryAtVisibleCells];
}

- (void)moveImageCacheFromDiskToMemoryAtVisibleCells {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        for (PWPhotoViewCell *cell in _collectionView.visibleCells) {
            NSString *thumbnailUrl = cell.photo.tag_thumbnail_url;
            [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumbnailUrl];
        }
    });
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
    PWPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.isSelectWithCheckMark = _isSelectMode;
    [cell setPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];;
    
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(112.0f, 112.0f);
        }
        else {
            return CGSizeMake(106.0f, 106.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(172.0f, 187.0f);
        }
        else {
            return CGSizeMake(172.0f, 187.0f);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return 2.0f;
        }
        else {
            return 1.0f;
        }
    }
    else {
        return 10.0f;
    }
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
        PWPhotoViewCell *cell = (PWPhotoViewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        UIImage *image = cell.imageView.image;
        
        NSArray *photos = [_fetchedResultsController fetchedObjects];
        PWPhotoPageViewController *viewController = [[PWPhotoPageViewController alloc] initWithPhotos:photos index:indexPath.row image:image];
        [self.navigationController pushViewController:viewController animated:YES];
        
        _photoPageViewController = viewController;
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
    _moveBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Copy", nil) style:UIBarButtonItemStylePlain target:self action:@selector(moveBarButtonAction)];
    _moveBarButtonItem.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButton, flexibleSpace, _moveBarButtonItem, flexibleSpace, _trashBarButtonItem];
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PWColors getColor:PWColorsTypeTintWebColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Select items", nil)];
    [navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:NO];
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationTintColor:[PWColors getColor:PWColorsTypeTintWebColor]];
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
    }];
}

- (void)reloadData {
    __weak typeof(self) wself = self;
    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:_album.id_str index:0 completion:^(NSArray *photos, NSUInteger nextIndex, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (error) {
            NSLog(@"%@", error);
            if (error.code == 401) {
                [sself openLoginviewController];
            }
        }
        
        sself.requestIndex = nextIndex;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
        });
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

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [_collectionView reloadData];
}

#pragma mark UIActionSheet
- (void)showAlbumActionSheet:(PWAlbumObject *)album {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.title];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Edit", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWAlbumEditViewController *viewController = [[PWAlbumEditViewController alloc] initWithAlbum:album];
        viewController.successBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself loadDataWithStartIndex:0];
        };
        PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Share", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWAlbumShareViewController *viewController = [[PWAlbumShareViewController alloc] initWithAlbum:album];
        viewController.changedAlbumBlock = ^() {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.collectionView reloadItemsAtIndexPaths:sself.collectionView.indexPathsForVisibleItems];
            });
        };
        PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Download", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:album.id_str index:0 completion:^(NSArray *photos, NSUInteger nextIndex, NSError *error) {
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            
            [[PDTaskManager sharedManager] addTaskFromWebAlbum:album toLocalAlbum:nil completion:^(NSError *error) {
                NSLog(@"added");
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                [[PDTaskManager sharedManager] start];
            }];
        }];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] bk_initWithTitle:NSLocalizedString(@"本当に削除しますか？アルバム内の写真はすべて削除されます。", nil)];
        [deleteActionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
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
                    NSLog(@"%@", error.description);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alertView dismissWithClickedButtonIndex:0 animated:YES];
                    [sself loadDataWithStartIndex:0];
                });
            }];
        }];
        [deleteActionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
        
        [deleteActionSheet showFromTabBar:sself.tabBarController.tabBar];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    
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
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            indicator.center = CGPointMake((sself.view.bounds.size.width / 2) - 20, (sself.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            
            NSArray *indexPaths = sself.collectionView.indexPathsForSelectedItems;
            __block NSUInteger maxCount = indexPaths.count;
            __block NSUInteger count = 0;
            for (NSIndexPath *indexPath in indexPaths) {
                PWPhotoObject *photo = [sself.fetchedResultsController objectAtIndexPath:indexPath];
                [PWPicasaAPI deletePhoto:photo completion:^(NSError *error) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (error) {
                        NSLog(@"%@", error.description);
                        maxCount--;
                        return;
                    }
                    
                    count++;
                    if (count == maxCount) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [alertView dismissWithClickedButtonIndex:0 animated:YES];
                            [sself reloadData];
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            alertView.title = [NSString stringWithFormat:@"%@(%ld+1/%ld)", NSLocalizedString(@"Deleting...", nil), (unsigned long)count, (unsigned long)maxCount];
                        });
                    }
                }];
            }
        }];
        [actionSheet bk_setCancelButtonWithTitle:cancelButton handler:^{}];
        
        [actionSheet showFromTabBar:sself.tabBarController.tabBar];
    }];
}

@end
