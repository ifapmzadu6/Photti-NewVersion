//
//  PWImagePickerWebPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerWebPhotoListViewController.h"

#import "PWPicasaAPI.h"
#import "PAColors.h"
#import "PAIcons.h"
#import "PAString.h"
#import "PWRefreshControl.h"
#import <BlocksKit+UIKit.h>
#import <Reachability.h>
#import <SDImageCache.h>

#import "PWPhotoViewCell.h"
#import "PLCollectionFooterView.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PATabBarController.h"
#import "PWNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PWImagePickerController.h"


@interface PWImagePickerWebPhotoListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIImageView *noItemImageView;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isRequesting;
@property (nonatomic) BOOL isRefreshControlAnimating;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray *selectedPhotoIDs;

@end

@implementation PWImagePickerWebPhotoListViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [super init];
    if (self) {
        _album = album;
        
        _selectedPhotoIDs = @[].mutableCopy;
        
        self.title = album.title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PAPhotoCollectionViewFlowLayout *collectionViewLayout = [[PAPhotoCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.backgroundColor = [PAColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.allowsMultipleSelection = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _collectionView.contentInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
    }
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.tintColor = [PAColors getColor:PWColorsTypeTintWebColor];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
    [self setRightNavigationItemSelectButton];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", _album.id_str];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    [_fetchedResultsController performFetch:nil];
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        [_activityIndicatorView stopAnimating];
        
        [_collectionView reloadData];
        
        PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
        for (NSString *id_str in tabBarController.selectedPhotoIDs) {
            NSArray *filteredPhotos = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
            if (filteredPhotos.count > 0) {
                PWPhotoObject *photo = filteredPhotos.firstObject;
                NSIndexPath *indexPath = [_fetchedResultsController indexPathForObject:photo];
                [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
        
        if (_fetchedResultsController.fetchedObjects.count == _collectionView.indexPathsForSelectedItems.count) {
            [self setRightNavigationItemDeselectButton];
        }
        else {
            [self setRightNavigationItemSelectButton];
        }
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        [_activityIndicatorView startAnimating];
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
    
    [self loadDataWithStartIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

#pragma mark UIBarButtonItem
- (void)setRightNavigationItemSelectButton {
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = selectBarButtonItem;
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
}

- (void)setRightNavigationItemDeselectButton {
    UIBarButtonItem *deselectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Deselect all", nil) style:UIBarButtonItemStylePlain target:self action:@selector(deselectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = deselectBarButtonItem;
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
}

#pragma mark UIBarButtonAction
- (void)selectBarButtonAction {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    for (size_t i=0; i<_fetchedResultsController.fetchedObjects.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
        [tabBarController addSelectedPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    }
    
    [self setRightNavigationItemDeselectButton];
}

- (void)deselectBarButtonAction {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    for (size_t i=0; i<_fetchedResultsController.fetchedObjects.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [_collectionView deselectItemAtIndexPath:indexPath animated:NO];
        
        [tabBarController removeSelectedPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    }
    
    [self setRightNavigationItemSelectButton];
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
    cell.isSelectWithCheckMark = YES;
    [cell setPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];;
    
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
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    [tabBarController addSelectedPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    
    if (_fetchedResultsController.fetchedObjects.count == _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemDeselectButton];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    [tabBarController removeSelectedPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    
    if (_fetchedResultsController.fetchedObjects.count != _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemSelectButton];
    }
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
    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:_album.id_str index:0 completion:^(NSUInteger nextIndex, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.isRequesting = NO;
        
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            if (error.code == 401) {
                [sself openLoginViewController];
            }
        }
        else {
            sself.requestIndex = nextIndex;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
        });
    }];
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
        
        PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
        for (NSString *id_str in tabBarController.selectedPhotoIDs) {
            NSArray *filteredPhotos = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
            if (filteredPhotos.count > 0) {
                PWPhotoObject *photo = filteredPhotos.firstObject;
                NSIndexPath *indexPath = [_fetchedResultsController indexPathForObject:photo];
                [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
        
        if (_fetchedResultsController.fetchedObjects.count > 0) {
            if (_fetchedResultsController.fetchedObjects.count == _collectionView.indexPathsForSelectedItems.count) {
                [self setRightNavigationItemDeselectButton];
            }
            else {
                [self setRightNavigationItemSelectButton];
            }
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        else {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
        
        [self refreshNoItemWithNumberOfItem:controller.fetchedObjects.count];
    });
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
