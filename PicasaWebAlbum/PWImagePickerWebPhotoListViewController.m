//
//  PWImagePickerWebPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerWebPhotoListViewController.h"

#import "PWPicasaAPI.h"
#import "PWColors.h"
#import "PWString.h"
#import "PWRefreshControl.h"
#import "BlocksKit+UIKit.h"

#import "PWPhotoViewCell.h"
#import "PWTabBarController.h"
#import "PWNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PWImagePickerController.h"


@interface PWImagePickerWebPhotoListViewController ()

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isNowRequesting;

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
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.allowsMultipleSelection = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _collectionView.contentInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
    }
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicatorView];
    
    [self setRightNavigationItemSelectButton];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    //    UIBarButtonItem *mapBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Info"] style:UIBarButtonItemStylePlain target:self action:@selector(mapBarButtonAction)];
    //    self.navigationItem.rightBarButtonItem = mapBarButtonItem;
    
    [_refreshControl beginRefreshing];
    [_activityIndicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", sself.album.id_str];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        
        sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        NSError *error = nil;
        [sself.fetchedResultsController performFetch:&error];
        if (error) {
            NSLog(@"%@", error.description);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (sself.fetchedResultsController.fetchedObjects.count) {
                [sself.activityIndicatorView stopAnimating];
                
                [sself.collectionView reloadData];
                
                PWImagePickerController *tabBarController = (PWImagePickerController *)sself.tabBarController;
                for (NSString *id_str in tabBarController.selectedPhotoIDs) {
                    NSArray *filteredPhotos = [sself.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
                    if (filteredPhotos.count) {
                        PWPhotoObject *photo = filteredPhotos.firstObject;
                        NSIndexPath *indexPath = [sself.fetchedResultsController indexPathForObject:photo];
                        [sself.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    }
                }
                
                if (sself.fetchedResultsController.fetchedObjects.count == sself.collectionView.indexPathsForSelectedItems.count) {
                    [sself setRightNavigationItemDeselectButton];
                }
                else {
                    [sself setRightNavigationItemSelectButton];
                }
                sself.navigationItem.rightBarButtonItem.enabled = YES;
            }
            else {
                sself.navigationItem.rightBarButtonItem.enabled = NO;
            }
            
            [sself reloadData];
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_isNowRequesting) {
        [_refreshControl endRefreshing];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = rect;
    
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

#pragma mark UIBarButtonItem
- (void)setRightNavigationItemSelectButton {
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"すべて選択", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = selectBarButtonItem;
}

- (void)setRightNavigationItemDeselectButton {
    UIBarButtonItem *deselectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"選択解除", nil) style:UIBarButtonItemStylePlain target:self action:@selector(deselectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = deselectBarButtonItem;
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
    if (!_isNowRequesting) {
        [self reloadData];
    }
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
    [cell setPhoto:[_fetchedResultsController objectAtIndexPath:indexPath] isNowLoading:_isNowRequesting];;
    
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
    __weak typeof(self) wself = self;
    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:_album.id_str index:index completion:^(NSArray *photos, NSUInteger nextIndex, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (error) {
            NSLog(@"%@", error);
            [sself openLoginviewController];
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
        NSError *coredataError = nil;
        [sself.fetchedResultsController performFetch:&coredataError];
        if (coredataError) {
            NSLog(@"%@", coredataError.description);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
            
            sself.isNowRequesting = NO;
            [sself.collectionView reloadData];
            
            if (sself.fetchedResultsController.fetchedObjects.count) {
                PWImagePickerController *tabBarController = (PWImagePickerController *)sself.tabBarController;
                for (NSString *id_str in tabBarController.selectedPhotoIDs) {
                    NSArray *filteredPhotos = [sself.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
                    if (filteredPhotos.count) {
                        PWPhotoObject *photo = filteredPhotos.firstObject;
                        NSIndexPath *indexPath = [sself.fetchedResultsController indexPathForObject:photo];
                        [sself.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    }
                }
                
                if (sself.fetchedResultsController.fetchedObjects.count == sself.collectionView.indexPathsForSelectedItems.count) {
                    [sself setRightNavigationItemDeselectButton];
                }
                else {
                    [sself setRightNavigationItemSelectButton];
                }
                sself.navigationItem.rightBarButtonItem.enabled = YES;
            }
            else {
                sself.navigationItem.rightBarButtonItem.enabled = NO;
            }
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


@end
