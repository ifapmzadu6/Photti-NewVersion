//
//  PWImagePickerWebAlbumListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSWebAlbumListViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PWRefreshControl.h"
#import "PRAlbumListDataSource.h"
#import "PAAlbumCollectionViewFlowLayout.h"
#import "PSWebPhotoListViewController.h"
#import "PSImagePickerController.h"
#import "PAActivityIndicatorView.h"
#import "PAViewControllerKit.h"
#import "PAAlertControllerKit.h"
#import "PWCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import <Reachability.h>
#import <SDImageCache.h>

@interface PSWebAlbumListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) PRAlbumListDataSource *albumListDataSource;
@property (nonatomic) BOOL isRefreshControlAnimating;

@end

@implementation PSWebAlbumListViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Web Album", nil);
        
        NSManagedObjectContext *context = [PWCoreDataAPI readContext];
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        
        _albumListDataSource = [[PRAlbumListDataSource alloc] initWithFetchRequest:request];
        __weak typeof(self) wself = self;
        _albumListDataSource.didChangeItemCountBlock = ^(NSUInteger count) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself refreshNoItemWithNumberOfItem:count];
        };
        _albumListDataSource.didSelectAlbumBlock = ^(PWAlbumObject *album, NSUInteger index) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PSWebPhotoListViewController *viewController = [[PSWebPhotoListViewController alloc] initWithAlbum:album];
            viewController.navigationItem.prompt = sself.navigationItem.prompt;
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        _albumListDataSource.didRefresh = ^() {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
        };
        _albumListDataSource.openLoginViewController = ^() {
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
                    [sself.albumListDataSource loadDataWithStartIndex:0];
                });
            }];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PAAlbumCollectionViewFlowLayout *collectionViewLayout = [[PAAlbumCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _albumListDataSource.collectionView = _collectionView;
    _collectionView.dataSource = _albumListDataSource;
    _collectionView.delegate = _albumListDataSource;
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[PWRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    _refreshControl.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.view addSubview:_activityIndicatorView];
    
    UIBarButtonItem *doneBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonitem;
    UIBarButtonItem *cancelBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonitem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    if (_albumListDataSource.numberOfAlbums == 0) {
        [_activityIndicatorView startAnimating];
    }
    
    [self refreshNoItemWithNumberOfItem:_albumListDataSource.numberOfAlbums];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSArray *indexPaths = _collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
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
    UIEdgeInsets contentInset = UIEdgeInsetsMake(viewInsets.top + 15.0f, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    UIEdgeInsets scrollIndicatorInsets = viewInsets;
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
    
    _activityIndicatorView.center = self.view.center;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_albumListDataSource.isRequesting && _isRefreshControlAnimating) {
        [_refreshControl beginRefreshing];
    }
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    [tabBarController doneBarButtonAction];
}

- (void)cancelBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIRefreshControl
- (void)refreshControlAction {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [PAAlertControllerKit showNotCollectedToNetwork];
        return;
    }
    
    [_albumListDataSource loadDataWithStartIndex:0];
}

@end
