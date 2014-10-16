//
//  PWPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoListViewController.h"

#import "PWPicasaAPI.h"
#import "PAColors.h"
#import "PAIcons.h"
#import "PAString.h"
#import "PASnowFlake.h"
#import "PWRefreshControl.h"
#import "PDTaskManager.h"
#import <SDImageCache.h>
#import <Reachability.h>

#import "PWPhotoViewCell.h"
#import "PLCollectionFooterView.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PATabBarAdsController.h"
#import "PWNavigationController.h"
#import "PWPhotoPageViewController.h"
#import "PABaseNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PWImagePickerController.h"
#import "PWAlbumPickerController.h"
#import "PAActivityIndicatorView.h"
#import "PAActivityIndicatorView.h"

static NSString * const kPWPhotoListViewControllerName = @"PWPLVCN";

@interface PWPhotoListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIImageView *noItemImageView;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *organizeBarButtonItem;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isRequesting;
@property (nonatomic) BOOL isRefreshControlAnimating;
@property (nonatomic) BOOL isSelectMode;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) NSMutableArray *selectedPhotoIDs;
@property (nonatomic) BOOL isActionLoadingCancel;
@property (nonatomic) NSUInteger actionLoadingVideoQuality;
@property (strong, nonatomic) id actionSheetItem;

@property (weak, nonatomic) PWPhotoPageViewController *photoPageViewController;
@property (strong, nonatomic) NSCache *photoViewCache;

@end

@implementation PWPhotoListViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [self init];
    if (self) {
        _album = album;
        
        self.title = album.title;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedPhotoIDs = @[].mutableCopy;
        _photoViewCache = [NSCache new];
        _photoViewCache.countLimit = 10;
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    self.navigationItem.rightBarButtonItem = searchBarButtonItem;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarTintColor:[PAColors getColor:PAColorsTypeTintWebColor]];
    
    PAPhotoCollectionViewFlowLayout *collectionViewLayout = [[PAPhotoCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [PWRefreshControl new];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.view addSubview:_activityIndicatorView];
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    if (_album) {
        request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", _album.id_str];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    }
    else {
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO]];
    }
    NSString *cacheName = [kPWPhotoListViewControllerName stringByAppendingString:_album.id_str];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:cacheName];
    _fetchedResultsController.delegate = self;
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        abort();
    }
    
    if (_fetchedResultsController.fetchedObjects.count == 0) {
        [_activityIndicatorView startAnimating];
    }
    else {
        [_activityIndicatorView stopAnimating];
        [_collectionView reloadData];
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
    
    [self loadDataWithStartIndex:0];
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
    
    _activityIndicatorView.center = self.view.center;
    
    [self layoutNoItem];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_isRequesting && _isRefreshControlAnimating) {
        [_refreshControl beginRefreshing];
    }
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
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setToolbarTintColor:[PAColors getColor:PAColorsTypeTintWebColor]];
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        __weak typeof(self) wself = self;
        [tabBarController setToolbarHidden:NO animated:animated completion:^(BOOL finished) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
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
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    
    [_collectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark UIBarButtonAction
- (void)searchBarButtonAction {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:YES animated:NO];
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

- (void)actionBarButtonAction:(id)sender {
    [self showAlbumActionSheet:_album sender:sender];
}

- (void)addBarButtonAction {
    __weak typeof(self) wself = self;
    PWImagePickerController *viewController = [[PWImagePickerController alloc] initWithAlbumTitle:_album.title completion:^(NSArray *selectedPhotos) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toWebAlbum:sself.album completion:^(NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            });
        }];
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
    if (_selectedPhotoIDs.count == 0) {
        return;
    }
    
    BOOL isContainVideo = NO;
    NSArray *photos = _fetchedResultsController.fetchedObjects;
    NSMutableArray *selectedPhotos = @[].mutableCopy;
    for (NSString *id_str in _selectedPhotoIDs) {
        NSArray *results = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
        if (results.count > 0) {
            PWPhotoObject *photo = results.firstObject;
            [selectedPhotos addObject:photo];
            if (photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
                isContainVideo = YES;
            }
        }
    }
    if (selectedPhotos.count == 0) return;
    
    _isActionLoadingCancel = NO;
    _actionLoadingVideoQuality = 0;
    
    if (isContainVideo) {
        NSString *title = NSLocalizedString(@"Choose a video quality to share (If don't match, choose a highest quality video that is smaller than you have chosen.)", nil);
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"1080", @"720", @"480", @"360", @"240", nil];
        actionSheet.tag = 1001;
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
    else {
        [self loadAndSavePhotos];
    }
}

- (void)loadAndSavePhotos {
    NSArray *photos = _fetchedResultsController.fetchedObjects;
    NSMutableArray *selectedPhotos = @[].mutableCopy;
    for (NSString *id_str in _selectedPhotoIDs) {
        NSArray *results = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
        if (results.count > 0) {
            PWPhotoObject *photo = results.firstObject;
            [selectedPhotos addObject:photo];
        }
    }
    if (selectedPhotos.count == 0) return;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading...", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
    PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    alertView.tag = 100;
    [alertView show];
    
    __weak typeof(self) wself = self;
    [self loadAndSaveWithPhotos:selectedPhotos savedLocations:@[].mutableCopy alertView:alertView completion:^(NSArray *savedLocations) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.isActionLoadingCancel) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:savedLocations applicationActivities:nil];
            [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
            
            [sself disableSelectMode];
        });
    }];
}

- (void)loadAndSaveWithPhotos:(NSMutableArray *)photos  savedLocations:(NSMutableArray *)savedLocations alertView:(UIAlertView *)alertView completion:(void (^)(NSArray *savedLocations))completion {
    if (self.isActionLoadingCancel) {
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"Loading...(%ld/%ld)", (long)savedLocations.count+1, (long)(photos.count + savedLocations.count)];
    dispatch_async(dispatch_get_main_queue(), ^{
        alertView.title = title;
    });
    PWPhotoObject *photo = photos.firstObject;
    NSURL *url = nil;
    if (photo.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
        url = [NSURL URLWithString:photo.tag_originalimage_url];
    }
    else if (photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
        for (PWPhotoMediaContentObject *content in photo.media.content.reversedOrderedSet) {
            if ([content.type isEqualToString:@"video/mpeg4"]) {
                NSUInteger quality = content.width.unsignedIntegerValue > content.height.unsignedIntegerValue ? content.width.unsignedIntegerValue : content.height.unsignedIntegerValue;
                if (quality <= _actionLoadingVideoQuality) {
                    url = [NSURL URLWithString:content.url];
                    break;
                }
            }
        }
    }
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        [[[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (!error) {
                NSString *filePath = nil;
                if (photo.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
                    filePath = [[PWPhotoListViewController makeUniquePathInTmpDir] stringByAppendingPathExtension:@"jpg"];
                }
                else {
                    filePath = [[PWPhotoListViewController makeUniquePathInTmpDir] stringByAppendingPathExtension:@"mp4"];
                }
                NSURL *filePathURL = [NSURL fileURLWithPath:filePath];
                NSError *fileManagerError = nil;
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:filePathURL error:&fileManagerError];
                
                [savedLocations addObject:filePathURL];
            }
            
            [photos removeObject:photo];
            if (photos.count > 0) {
                [sself loadAndSaveWithPhotos:photos savedLocations:savedLocations alertView:alertView completion:completion];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alertView dismissWithClickedButtonIndex:0 animated:YES];
                });
                
                if (completion) {
                    completion(savedLocations.copy);
                }
            }
        }] resume];
    }];
}

- (void)trashBarButtonAction:(id)sender {
    [self showTrashPhotosActionSheet:sender];
}

- (void)organizeBarButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Copy", nil), nil];
    actionSheet.tag = 1002;
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)copyPhoto {
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
        if (selectedPhotos.count == 0) return;
        
        if (isWebAlbum) {
            PWAlbumObject *webAlbum = (PWAlbumObject *)album;
            
            [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toWebAlbum:webAlbum completion:^(NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            }];
        }
        else {
            PLAlbumObject *localAlbum = (PLAlbumObject *)album;
            [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toLocalAlbum:localAlbum completion:^(NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
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
    
    [self loadDataWithStartIndex:0];
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
    [cell setPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        NSArray *photos = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(PWPhotoManagedObjectTypePhoto)]];
        NSArray *videos = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(PWPhotoManagedObjectTypeVideo)]];
        NSString *albumCountString = [PAString photoAndVideoStringWithPhotoCount:photos.count videoCount:videos.count isInitialUpperCase:YES];
        NSString *footerString =[NSString stringWithFormat:@"- %@ -", albumCountString];
        [footerView setText:footerString];
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
        _trashBarButtonItem.enabled = YES;
        _organizeBarButtonItem.enabled = YES;
        
        PWPhotoObject *photo = [_fetchedResultsController objectAtIndexPath:indexPath];
        [_selectedPhotoIDs addObject:photo.id_str];
    }
    else {
        PWPhotoViewCell *cell = (PWPhotoViewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        id placeholder = nil;
        if (cell.animatedImage) {
            placeholder = cell.animatedImage;
        }
        else {
            placeholder = cell.image;
        }
        
        NSArray *photos = [_fetchedResultsController fetchedObjects];
        PWPhotoPageViewController *viewController = [[PWPhotoPageViewController alloc] initWithPhotos:photos index:indexPath.row placeholder:placeholder cache:_photoViewCache];
        [self.navigationController pushViewController:viewController animated:YES];
        
        _photoPageViewController = viewController;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        if (_collectionView.indexPathsForSelectedItems.count == 0) {
            _selectActionBarButton.enabled = NO;
            _trashBarButtonItem.enabled = NO;
            _organizeBarButtonItem.enabled = NO;
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
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction:)];
    _trashBarButtonItem.enabled = NO;
    _organizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(organizeBarButtonAction:)];
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
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
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
    _selectedPhotoIDs = @[].mutableCopy;
    
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
        [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:_album.id_str index:index completion:^(NSUInteger nextIndex, NSError *error) {
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
                typeof(wself) sself = wself;
                if (!sself) return;
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
        _collectionView.userInteractionEnabled = NO;
        
        [_collectionView reloadData];
        
        [self refreshNoItemWithNumberOfItem:controller.fetchedObjects.count];
        
        for (NSString *id_str in _selectedPhotoIDs) {
            NSArray *selectedPhotos = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
            PWPhotoObject *photo = selectedPhotos.firstObject;
            if (photo) {
                NSUInteger index = [_fetchedResultsController.fetchedObjects indexOfObject:photo];
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
        
        _collectionView.userInteractionEnabled = YES;
    });
}

#pragma mark UIActionSheet
- (void)showAlbumActionSheet:(PWAlbumObject *)album sender:(id)sender {
    _actionSheetItem = album;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:album.title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:NSLocalizedString(@"Edit", nil), NSLocalizedString(@"Share", nil), NSLocalizedString(@"Download", nil), nil];
    actionSheet.tag = 1003;
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)editActionSheetAction:(PWAlbumObject *)album {
    PWAlbumEditViewController *viewController = [[PWAlbumEditViewController alloc] initWithAlbum:album];
    __weak typeof(self) wself = self;
    viewController.successBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself loadDataWithStartIndex:0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.navigationItem.title = album.title;
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

- (void)shareActionSheetAction:(PWAlbumObject *)album {
    PWAlbumShareViewController *viewController = [[PWAlbumShareViewController alloc] initWithAlbum:album];
    __weak typeof(self) wself = self;
    viewController.changedAlbumBlock = ^() {
        typeof(wself) sself = wself;
        if (!sself) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_collectionView reloadItemsAtIndexPaths:_collectionView.indexPathsForVisibleItems];
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
    PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
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
    actionSheet.tag = 1004;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark Trash
- (void)showTrashPhotosActionSheet:(id)sender {
    __weak typeof(self) wself = self;
    NSMutableArray *selectedPhotos = @[].mutableCopy;
    for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
        [selectedPhotos addObject:[_fetchedResultsController objectAtIndexPath:indexPath]];
    }
    [PWPhotoObject getCountFromPhotoObjects:selectedPhotos completion:^(NSUInteger countOfPhoto, NSUInteger countOfVideo) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete %@?", nil), [PAString photoAndVideoStringWithPhotoCount:countOfPhoto videoCount:countOfVideo]];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:sself cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
        actionSheet.tag = 1005;
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }];
}

#pragma mark Download
- (void)downloadOriginalFile:(NSString *)url completion:(void (^)(NSString *filepath, NSError *error))completion {
    if (!completion) return;
    
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:url] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            return;
        }
        
        [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                return;
            }
            
            NSString *filePath = [PWPhotoListViewController makeUniquePathInTmpDir];
            [data writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error];
            
            completion(filePath, error);
        }];
    }];
}

+ (NSString *)makeUniquePathInTmpDir {
    NSString *homeDirectory = [NSString stringWithString:NSHomeDirectory()];
    NSString *tmpDirectory = [homeDirectory stringByAppendingPathComponent:@"/tmp"];
    NSString *filePath = [tmpDirectory stringByAppendingFormat:@"/%@", [PASnowFlake generateUniqueIDString]];
    
    return filePath;
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == 1001) {
        if (![buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
            _actionLoadingVideoQuality = buttonTitle.integerValue;
            [self loadAndSavePhotos];
        }
        else  {
        }
    }
    else if (actionSheet.tag == 1002) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Copy", nil)]) {
            [self copyPhoto];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1003) {
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
    else if (actionSheet.tag == 1004) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
            indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            
            PWAlbumObject *album = _actionSheetItem;
            NSManagedObjectID *albumObjectID = album.objectID;
            __weak typeof(self) wself = self;
            [PWPicasaAPI deleteAlbum:album completion:^(NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
                [PWCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                    PWAlbumObject *albumObject = (PWAlbumObject *)[context objectWithID:albumObjectID];
                    [context deleteObject:albumObject];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alertView dismissWithClickedButtonIndex:0 animated:YES];
                        [sself.navigationController popViewControllerAnimated:YES];
                    });
                }];
            }];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1005) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
            indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            
            NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
            __block NSUInteger maxCount = indexPaths.count;
            __block NSUInteger count = 0;
            for (NSIndexPath *indexPath in indexPaths) {
                PWPhotoObject *photo = [_fetchedResultsController objectAtIndexPath:indexPath];
                __weak typeof(self) wself = self;
                [PWPicasaAPI deletePhoto:photo completion:^(NSError *error) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (error) {
#ifdef DEBUG
                        NSLog(@"%@", error);
#endif
                        maxCount--;
                        return;
                    }
                    
                    count++;
                    if (count == maxCount) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [alertView dismissWithClickedButtonIndex:0 animated:YES];
                            [sself loadDataWithStartIndex:0];
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            alertView.title = [NSString stringWithFormat:@"%@(%ld/%ld)", NSLocalizedString(@"Deleting...", nil), (long)count + 1, (long)maxCount];
                        });
                    }
                }];
            }
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) {
        if (alertView.cancelButtonIndex == buttonIndex) {
            _isActionLoadingCancel = YES;
        }
    }
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
