//
//  PLPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPhotoListViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PWString.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLPhotoViewCell.h"
#import "PLCollectionFooterView.h"
#import "PWTabBarController.h"
#import "PLPhotoPageViewController.h"
#import "PWBaseNavigationController.h"
#import "PLAlbumEditViewController.h"
#import "BlocksKit+UIKit.h"
#import "PDTaskManager.h"
#import "PWImagePickerController.h"
#import "PWAlbumPickerController.h"
#import "PWModelObject.h"
#import "PDTaskManager.h"

@interface PLPhotoListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *moveBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectAllBarButtonItem;

@property (nonatomic) BOOL isSelectMode;
@property (strong, nonatomic) NSMutableArray *selectedPhotoURLs;

@end

@implementation PLPhotoListViewController

- (id)initWithAlbum:(PLAlbumObject *)album {
    self = [super init];
    if (self) {
        self.title = album.name;
        
        _album = album;
        
        NSManagedObjectContext *context = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification) name:NSManagedObjectContextDidSaveNotification object:context];
        
        _selectedPhotoURLs = @[].mutableCopy;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _collectionView.contentInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
    }
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
//    NSFetchRequest *request = [NSFetchRequest new];
//    request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
//    request.predicate = [NSPredicate predicateWithFormat:@"ANY albums = %@", _album];
//    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
//    _fetchedResultsController.delegate = self;
//    
//    [_fetchedResultsController performFetch:nil];
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
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PWIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        [tabBarController setToolbarTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
}

#pragma mark UIBarButtonAction
- (void)mapBarButtonAction {
    
}

- (void)actionBarButtonAction {
    [self showAlbumActionSheet:_album];
}

- (void)addBarButtonAction {
    PWImagePickerController *imagePickerController = [[PWImagePickerController alloc] initWithAlbumTitle:_album.name completion:^(NSArray *selectedPhotos) {
        
    }];
    [self.tabBarController presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)selectBarButtonAction {
    [self enableSelectMode];
}

- (void)cancelBarButtonAction {
    [self disableSelectMode];
}

- (void)selectActionBarButtonAction {
    if (_selectedPhotoURLs.count == 0) {
        return;
    }
    
    __block NSMutableArray *assets = @[].mutableCopy;
    for (NSManagedObjectID *photoURL in _selectedPhotoURLs) {
        __block PLPhotoObject *photoObject = nil;
        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"url = %@", photoURL];
            NSArray *objects = [context executeFetchRequest:request error:nil];
            if (objects.count > 0) {
                photoObject = objects.firstObject;
            }
        }];
        if (!photoObject) return;
        
        __weak typeof(self) wself = self;
        [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:photoObject.url] resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [assets addObject:asset];
            
            if (assets.count == sself.selectedPhotoURLs.count) {
                UIActivityViewController *activityViewcontroller = [[UIActivityViewController alloc] initWithActivityItems:assets applicationActivities:nil];
                [sself.tabBarController presentViewController:activityViewcontroller animated:YES completion:nil];
            }
        } failureBlock:^(NSError *error) {
            
        }];
    }
}

- (void)selectAllBarButtonAction {
    if (_album.photos.count == _collectionView.indexPathsForSelectedItems.count) {
        [_selectAllBarButtonItem setTitle:NSLocalizedString(@"Select all", nil)];
        [_selectedPhotoURLs removeAllObjects];
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
        
        _selectActionBarButton.enabled = NO;
        _moveBarButtonItem.enabled = NO;
        _trashBarButtonItem.enabled = NO;
    }
    else {
        [_selectAllBarButtonItem setTitle:NSLocalizedString(@"Deselect all", nil)];
        for (PLPhotoObject *photoObject in _album.photos) {
            if (![_selectedPhotoURLs containsObject:photoObject.objectID]) {
                [_selectedPhotoURLs addObject:photoObject.url];
            }
            
            [_collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:[_album.photos indexOfObject:photoObject] inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        _selectActionBarButton.enabled = YES;
        _moveBarButtonItem.enabled = YES;
        _trashBarButtonItem.enabled = YES;
    }
}

- (void)moveBarButtonAction {
    __weak typeof(self) wself = self;
    PWAlbumPickerController *albumPickerController = [[PWAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSMutableArray *selectLocalPhotos = @[].mutableCopy;
        for (NSIndexPath *indexPath in sself.collectionView.indexPathsForSelectedItems) {
            [selectLocalPhotos addObject:sself.album.photos[indexPath.row]];
        }
        
        void (^completion)() = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                [sself disableSelectMode];
                
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            });
        };
        
        if (isWebAlbum) {
            [[PDTaskManager sharedManager] addTaskPhotos:selectLocalPhotos toWebAlbum:album completion:^(NSError *error) {
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                completion();
            }];
        }
        else {
            [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                PLAlbumObject *albumObject = (PLAlbumObject *)album;
                for (PLPhotoObject *photoObject in selectLocalPhotos) {
                    [albumObject addPhotosObject:photoObject];
                }
                completion();
            }];
        }
    }];
    albumPickerController.prompt = NSLocalizedString(@"Choose an album to copy to.", nil);
    [self.tabBarController presentViewController:albumPickerController animated:YES completion:nil];
}

- (void)trashBarButtonAction {
    
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _album.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.photo = _album.photos[indexPath.row];
    cell.isSelectWithCheckMark = _isSelectMode;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    if (_album.photos.count > 0) {
        NSArray *photos = [_album.photos.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypePhoto]];
        NSArray *videos = [_album.photos.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypeVideo]];
        
        NSString *albumCountString = [PWString photoAndVideoStringWithPhotoCount:photos.count videoCount:videos.count isInitialUpperCase:YES];
        [footerView setText:albumCountString];
    }
    else {
        [footerView setText:nil];
    }
    
    return footerView;
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        _selectActionBarButton.enabled = YES;
        _moveBarButtonItem.enabled = YES;
        _trashBarButtonItem.enabled = YES;
        
        PLPhotoObject *photoObject = _album.photos[indexPath.row];
        [_selectedPhotoURLs addObject:photoObject.url];
        
        if (_selectedPhotoURLs.count == _album.photos.count) {
            [_selectAllBarButtonItem setTitle:NSLocalizedString(@"Deselect all", nil)];
        }
    }
    else {
        PLPhotoPageViewController *viewController = [[PLPhotoPageViewController alloc] initWithPhotos:_album.photos.array index:indexPath.row];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        PLPhotoObject *photoObject = _album.photos[indexPath.row];
        [_selectedPhotoURLs removeObject:photoObject.url];
        
        if (_selectedPhotoURLs.count == 0) {
            _selectActionBarButton.enabled = NO;
            _moveBarButtonItem.enabled = NO;
            _trashBarButtonItem.enabled = NO;
        }
        
        [_selectAllBarButtonItem setTitle:NSLocalizedString(@"Select all", nil)];
    }
}


#pragma mark SelectMode
- (void)enableSelectMode {
    if (_isSelectMode) {
        return;
    }
    _isSelectMode = YES;
    
    [_selectedPhotoURLs removeAllObjects];
    
    _collectionView.allowsMultipleSelection = YES;
    for (PLPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = YES;
    }
    
    _selectActionBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction)];
    _selectActionBarButton.enabled = NO;
    _moveBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PWIcons imageWithText:NSLocalizedString(@"Copy", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(moveBarButtonAction)];
    _moveBarButtonItem.enabled = NO;
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction)];
    _trashBarButtonItem.enabled = NO;
    UIBarButtonItem *fixedBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedBarButtonItem.width = 32.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButton, flexibleSpace, _moveBarButtonItem, flexibleSpace, fixedBarButtonItem, _trashBarButtonItem];
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    _selectAllBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(selectAllBarButtonAction)];
    [_selectAllBarButtonItem setTitle:NSLocalizedString(@"Select all", nil)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Select items", nil)];
    [navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:NO];
    [navigationItem setRightBarButtonItem:_selectAllBarButtonItem animated:NO];
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
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
    
    _collectionView.allowsMultipleSelection = YES;
    for (PLPhotoViewCell *cell in _collectionView.visibleCells) {
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

#pragma mark NSFetchedResultsControllerDelegate
- (void)contextDidSaveNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

#pragma mark UIAlertView
- (void)showAlbumActionSheet:(PLAlbumObject *)album {
    NSManagedObjectID *albumID = album.objectID;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.name];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Edit", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PLAlbumEditViewController *viewController = [[PLAlbumEditViewController alloc] initWithTitle:album.name timestamp:album.timestamp uploading_type:album.tag_uploading_type];
        viewController.saveButtonBlock = ^(NSString *name, NSNumber *timestamp, NSNumber *uploading_type) {
            [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                PLAlbumObject *album = (PLAlbumObject *)[context objectWithID:albumID];
                album.name = name;
                album.tag_date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue];
                if (![album.timestamp isEqualToNumber:timestamp]) {
                    album.timestamp = timestamp;
                    album.edited = @(YES);
                }
                album.tag_uploading_type = uploading_type;
            }];
        };
        PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
        [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Share", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself shareAlbum:album];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Upload", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [[PDTaskManager sharedManager] addTaskFromLocalAlbum:album toWebAlbum:nil completion:^(NSError *error) {
            if (error) NSLog(@"%@", error.description);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            });
        }];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] bk_initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.name]];
        [deleteActionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
            [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                PWAlbumObject *albumObject = (PWAlbumObject *)[context objectWithID:albumID];
                [context deleteObject:albumObject];
            }];
        }];
        [deleteActionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
        [deleteActionSheet showFromTabBar:sself.tabBarController.tabBar];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark HandleModelObject
- (void)shareAlbum:(PLAlbumObject *)album {
    NSMutableArray *assets = [NSMutableArray array];
    for (PLPhotoObject *photo in album.photos) {
        [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:photo.url] resultBlock:^(ALAsset *asset) {
            if (asset) {
                [assets addObject:asset];
            }
            if (assets.count == album.photos.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIActivityViewController *viewControlle = [[UIActivityViewController alloc] initWithActivityItems:assets applicationActivities:nil];
                    [self.tabBarController presentViewController:viewControlle animated:YES completion:nil];
                });
            }
        } failureBlock:^(NSError *error) {
            
        }];
    }
}

@end
