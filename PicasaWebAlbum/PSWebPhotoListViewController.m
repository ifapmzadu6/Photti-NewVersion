//
//  PWImagePickerWebPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSWebPhotoListViewController.h"

#import "PWPicasaAPI.h"
#import "PAColors.h"
#import "PAIcons.h"
#import "PWRefreshControl.h"
#import <Reachability.h>
#import <SDImageCache.h>

#import "PRPhotoListDataSource.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PATabBarController.h"
#import "PWNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PSImagePickerController.h"
#import "PAActivityIndicatorView.h"
#import "PAViewControllerKit.h"
#import "PAAlertControllerKit.h"

@interface PSWebPhotoListViewController () <UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isRequesting;
@property (nonatomic) BOOL isRefreshControlAnimating;

@property (strong, nonatomic) PRPhotoListDataSource *photoListDataSource;

@end

@implementation PSWebPhotoListViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [super init];
    if (self) {
        _album = album;
        
        self.title = album.title;
        
        NSManagedObjectContext *context = [PWCoreDataAPI readContext];
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", _album.id_str];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        
        _photoListDataSource = [[PRPhotoListDataSource alloc] initWithFetchRequest:request albumID:_album.id_str];
        _photoListDataSource.delegate = self;
        _photoListDataSource.isSelectMode = YES;
        __weak typeof(self) wself = self;
        _photoListDataSource.didChangeItemCountBlock = ^(NSUInteger count) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself refreshNoItemWithNumberOfItem:count];
        };
        _photoListDataSource.didRefresh = ^() {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
        };
        _photoListDataSource.didChangeSelectedItemCountBlock = ^(NSUInteger count) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (count == sself.collectionView.indexPathsForSelectedItems.count) {
                [sself setRightNavigationItemDeselectButton];
            }
            else {
                [sself setRightNavigationItemSelectButton];
            }
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PAPhotoCollectionViewFlowLayout *collectionViewLayout = [[PAPhotoCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _photoListDataSource.collectionView = _collectionView;
    _collectionView.dataSource = _photoListDataSource;
    _collectionView.delegate = _photoListDataSource;
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.allowsMultipleSelection = YES;
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.view addSubview:_activityIndicatorView];
    
    [self setRightNavigationItemSelectButton];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (_photoListDataSource.numberOfPhotos > 0) {
        PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
        for (NSString *id_str in tabBarController.selectedPhotoIDs) {
            NSArray *filteredPhotos = [_photoListDataSource.photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
            if (filteredPhotos.count > 0) {
                PWPhotoObject *photo = filteredPhotos.firstObject;
                NSUInteger index = [_photoListDataSource.photos indexOfObject:photo];
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
        
        if (_photoListDataSource.numberOfPhotos == _collectionView.indexPathsForSelectedItems.count) {
            [self setRightNavigationItemDeselectButton];
        }
        else {
            [self setRightNavigationItemSelectButton];
        }
    }
    else {
        [_activityIndicatorView startAnimating];
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = (_photoListDataSource.numberOfPhotos > 0) ? YES : NO;
    [self refreshNoItemWithNumberOfItem:_photoListDataSource.numberOfPhotos];
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
    
    PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = tabBarController.viewInsets;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        contentInset = UIEdgeInsetsMake(viewInsets.top + 20.0f, 20.0f, viewInsets.bottom + 20.0f, 20.0f);
    }
    UIEdgeInsets scrollIndicatorInsets = viewInsets;
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
    
    _activityIndicatorView.center = self.view.center;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_isRequesting && _isRefreshControlAnimating) {
        [_refreshControl beginRefreshing];
    }
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
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    for (size_t i=0; i<_photoListDataSource.numberOfPhotos; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
        PWPhotoObject *photo = [_photoListDataSource.photos objectAtIndex:i];
        [tabBarController addSelectedPhoto:photo];
    }
    
    [self setRightNavigationItemDeselectButton];
}

- (void)deselectBarButtonAction {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    for (size_t i=0; i<_photoListDataSource.numberOfPhotos; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [_collectionView deselectItemAtIndexPath:indexPath animated:NO];
        
        PWPhotoObject *photo = [_photoListDataSource.photos objectAtIndex:i];
        [tabBarController removeSelectedPhoto:photo];
    }
    
    [self setRightNavigationItemSelectButton];
}

#pragma mark UIRefreshControl
- (void)refreshControlAction {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [PAAlertControllerKit showNotCollectedToNetwork];
        return;
    }
    
    [_photoListDataSource loadDataWithStartIndex:0];
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWPhotoObject *photo = _photoListDataSource.photos[indexPath.item];
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    [tabBarController addSelectedPhoto:photo];
    
    if (_photoListDataSource.numberOfPhotos == _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemDeselectButton];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWPhotoObject *photo = _photoListDataSource.photos[indexPath.item];
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    [tabBarController removeSelectedPhoto:photo];
    
    if (_photoListDataSource.numberOfPhotos != _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemSelectButton];
    }
}

@end
