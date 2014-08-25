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
#import "PWPhotoCollectionViewFlowLayout.h"
#import "PWTabBarAdsController.h"
#import "PLPhotoPageViewController.h"
#import "PWBaseNavigationController.h"
#import "PLAlbumEditViewController.h"
#import <BlocksKit+UIKit.h>
#import "PDTaskManager.h"
#import "PWImagePickerController.h"
#import "PWAlbumPickerController.h"
#import "PWModelObject.h"
#import "PDTaskManager.h"

@interface PLPhotoListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIImageView *noItemImageView;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *organizeBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectAllBarButtonItem;

@property (nonatomic) BOOL isSelectMode;
@property (strong, nonatomic) NSMutableArray *selectedPhotoIDs;

@end

@implementation PLPhotoListViewController

- (id)initWithAlbum:(PLAlbumObject *)album {
    self = [super init];
    if (self) {
        self.title = album.name;
        
        _album = album;
        
        _selectedPhotoIDs = @[].mutableCopy;
        
        NSManagedObjectContext *context = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification) name:NSManagedObjectContextDidSaveNotification object:context];
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PWPhotoCollectionViewFlowLayout *collectionViewLayout = [[PWPhotoCollectionViewFlowLayout alloc] init];
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
    
    [self refreshNoItemWithNumberOfItem:_album.photos.count];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_isSelectMode) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction:)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PWIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        [tabBarController setToolbarTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
        __weak typeof(self) wself = self;
        [tabBarController setToolbarHidden:NO animated:animated completion:^(BOOL finished) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)sself.tabBarController;
            [tabBarController setTabBarHidden:YES animated:NO completion:nil];
        }];
    }
    else {
        [tabBarController setToolbarItems:toolbarItems animated:YES];
    }
    [tabBarController setAdsHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {return [obj1 compare:obj2];}];
    NSIndexPath *indexPath = nil;
    if (indexPaths.count > 0) {
        indexPath = indexPaths[indexPaths.count / 2];
    }
    
    PWTabBarController *tabBarViewController = (PWTabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    }
    else {
        _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 20.0f, 20.0f, viewInsets.bottom + 20.0f, 20.0f);
    }
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    _collectionView.frame = rect;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    
    [self layoutNoItem];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
}

#pragma mark UIBarButtonAction
- (void)actionBarButtonAction:(id)sender {
    [self showAlbumActionSheet:_album sender:sender];
}

- (void)addBarButtonAction {
    __weak typeof(self) wself = self;
    PWImagePickerController *imagePickerController = [[PWImagePickerController alloc] initWithAlbumTitle:_album.name completion:^(NSArray *selectedPhotos) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        BOOL isOnlyLocal = YES;
        for (id photo in selectedPhotos) {
            if ([photo isKindOfClass:[PWPhotoObject class]]) {
                isOnlyLocal = NO;
            }
        }
        
        [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toLocalAlbum:sself.album completion:^(NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
            
            if (!isOnlyLocal) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            }
        }];
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
    if (_selectedPhotoIDs.count == 0) {
        return;
    }
    
    __block NSMutableArray *assets = @[].mutableCopy;
    for (NSString *id_str in _selectedPhotoIDs) {
        __block PLPhotoObject *photoObject = nil;
        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
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
            
            if (assets.count == sself.selectedPhotoIDs.count) {
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
        _selectedPhotoIDs = @[].mutableCopy;
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
        
        _selectActionBarButton.enabled = NO;
        _organizeBarButtonItem.enabled = NO;
        _trashBarButtonItem.enabled = NO;
    }
    else {
        [_selectAllBarButtonItem setTitle:NSLocalizedString(@"Deselect all", nil)];
        for (PLPhotoObject *photoObject in _album.photos) {
            if (![_selectedPhotoIDs containsObject:photoObject.id_str]) {
                [_selectedPhotoIDs addObject:photoObject.id_str];
            }
            
            [_collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:[_album.photos indexOfObject:photoObject] inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        _selectActionBarButton.enabled = YES;
        _organizeBarButtonItem.enabled = YES;
        _trashBarButtonItem.enabled = YES;
    }
}

- (void)organizeBarButtonAction:(id)sender {
    __weak typeof(self) wself = self;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:nil];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Copy", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWAlbumPickerController *albumPickerController = [[PWAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            NSMutableArray *selectLocalPhotos = @[].mutableCopy;
            for (NSIndexPath *indexPath in sself.collectionView.indexPathsForSelectedItems) {
                PLPhotoObject *photoObject = sself.album.photos[indexPath.row];
                [selectLocalPhotos addObject:photoObject];
            }
            
            void (^completion)() = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself disableSelectMode];
                    
                    if (isWebAlbum) {
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                    }
                });
            };
            
            if (isWebAlbum) {
                [[PDTaskManager sharedManager] addTaskPhotos:selectLocalPhotos toWebAlbum:album completion:^(NSError *error) {
                    if (error) {
                        NSLog(@"%@", error);
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
        [sself.tabBarController presentViewController:albumPickerController animated:YES completion:nil];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)trashBarButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:NSLocalizedString(@"Are you sure you want to remove these items? These items will be removed from this album, but will remain in your Photo Library.", nil)];
    NSManagedObjectID *albumID = _album.objectID;
    __weak typeof(self) wself = self;
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Remove", nil) handler:^{
        [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
            request.fetchLimit = 1;
            for (NSString *id_str in sself.selectedPhotoIDs) {
                request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
                NSArray *objects = [context executeFetchRequest:request error:nil];
                PLPhotoObject *photoObject = nil;
                if (objects.count > 0) {
                    photoObject = objects.firstObject;
                }
                if (!photoObject) return;
                
                PLAlbumObject *album = (PLAlbumObject *)[context objectWithID:albumID];
                [album removePhotosObject:photoObject];
            }
        }];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    [actionSheet showFromBarButtonItem:sender animated:YES];
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

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        _selectActionBarButton.enabled = YES;
        _organizeBarButtonItem.enabled = YES;
        _trashBarButtonItem.enabled = YES;
        
        PLPhotoObject *photoObject = _album.photos[indexPath.row];
        [_selectedPhotoIDs addObject:photoObject.id_str];
        
        if (_selectedPhotoIDs.count == _album.photos.count) {
            [_selectAllBarButtonItem setTitle:NSLocalizedString(@"Deselect all", nil)];
        }
    }
    else {
        PLPhotoPageViewController *viewController = [[PLPhotoPageViewController alloc] initWithPhotos:_album.photos.array index:indexPath.row];
        viewController.isEnableDeletePhotoButton = YES;
        NSManagedObjectID *albumID = _album.objectID;
        __weak typeof(self) wself = self;
        viewController.deletePhotoButtonBlock = ^(NSUInteger index){
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PLPhotoObject *photo = sself.album.photos[index];
            NSManagedObjectID *photoID = photo.objectID;
            [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumID];
                PLPhotoObject *photoObject = (PLPhotoObject *)[context objectWithID:photoID];
                [albumObject removePhotosObject:photoObject];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.navigationController popViewControllerAnimated:YES];
            });
        };
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        PLPhotoObject *photoObject = _album.photos[indexPath.row];
        [_selectedPhotoIDs removeObject:photoObject.id_str];
        
        if (_selectedPhotoIDs.count == 0) {
            _selectActionBarButton.enabled = NO;
            _organizeBarButtonItem.enabled = NO;
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
    
    _selectedPhotoIDs = @[].mutableCopy;
    
    _collectionView.allowsMultipleSelection = YES;
    for (PLPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = YES;
    }
    
    _selectActionBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction)];
    _selectActionBarButton.enabled = NO;
    _organizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(organizeBarButtonAction:)];
    _organizeBarButtonItem.enabled = NO;
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction:)];
    _trashBarButtonItem.enabled = NO;
    UIBarButtonItem *fixedBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedBarButtonItem.width = 32.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButton, flexibleSpace, _organizeBarButtonItem, flexibleSpace, fixedBarButtonItem, _trashBarButtonItem];
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)sself.tabBarController;
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
    
    _selectedPhotoIDs = @[].mutableCopy;
    
    _collectionView.allowsMultipleSelection = NO;
    for (PLPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = NO;
    }
    NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
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
        
        [self refreshNoItemWithNumberOfItem:_album.photos.count];
        
        for (NSString *id_str in _selectedPhotoIDs) {
            NSArray *selectedPhotos = [_album.photos.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
            PWPhotoObject *photo = selectedPhotos.firstObject;
            if (photo) {
                NSUInteger index = [_album.photos indexOfObject:photo];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
        
        NSArray *selectedIndexPaths = _collectionView.indexPathsForSelectedItems;
        if (selectedIndexPaths.count == 0) {
            _selectActionBarButton.enabled = NO;
            _trashBarButtonItem.enabled = NO;
            _organizeBarButtonItem.enabled = NO;
        }
    });
}

#pragma mark UIAlertView
- (void)showAlbumActionSheet:(PLAlbumObject *)album sender:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.name];
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
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Upload", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself uploadActionSheetAction:album];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself deleteActionSheetAction:album sender:sender];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)editActionSheetAction:(PLAlbumObject *)album {
    PLAlbumEditViewController *viewController = [[PLAlbumEditViewController alloc] initWithTitle:album.name timestamp:album.timestamp uploading_type:album.tag_uploading_type];
    __weak typeof(self) wself = self;
    NSManagedObjectID *albumID = album.objectID;
    viewController.saveButtonBlock = ^(NSString *name, NSNumber *timestamp, NSNumber *uploading_type) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumID];
            albumObject.name = name;
            albumObject.tag_date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue / 1000];
            if (![albumObject.timestamp isEqualToNumber:timestamp]) {
                albumObject.timestamp = timestamp;
                albumObject.edited = @(YES);
            }
            albumObject.tag_uploading_type = uploading_type;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.navigationItem.title = name;
        });
    };
    PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)shareActionSheetAction:(PLAlbumObject *)album {
    NSMutableArray *assets = @[].mutableCopy;
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
            NSLog(@"%@", error);
        }];
    }
}

- (void)uploadActionSheetAction:(PLAlbumObject *)album {
    [[PDTaskManager sharedManager] addTaskFromLocalAlbum:album toWebAlbum:nil completion:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        });
    }];
}

- (void)deleteActionSheetAction:(PLAlbumObject *)album sender:(id)sender {
    UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] bk_initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.name]];
    __weak typeof(self) wself = self;
    NSManagedObjectID *albumID = album.objectID;
    [deleteActionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PWAlbumObject *albumObject = (PWAlbumObject *)[context objectWithID:albumID];
            [context deleteObject:albumObject];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.navigationController popViewControllerAnimated:YES];
        });
    }];
    [deleteActionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    [deleteActionSheet showFromBarButtonItem:sender animated:YES];
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
        _noItemImageView.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.2f];
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
