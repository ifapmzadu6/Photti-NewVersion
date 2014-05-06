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

#import "PWPhotoListViewController.h"

@interface PWAlbumListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSMutableArray *albums;
@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isDisplayed;

@end

@implementation PWAlbumListViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"ウェブアルバム";
        
        _albums = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.contentInset = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    _collectionView.autoresizesSubviews = YES;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [_collectionView addSubview:_refreshControl];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[addBarButtonItem, searchBarButtonItem];
    
    [self loadLocalData];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
    
}

- (void)addBarButtonAction {
    
}

#pragma mark LoadData
- (void)loadDataWithStartIndex:(NSUInteger)index {
    __weak typeof(self) wself = self;
    [PWOAuthManager authorizeActionWithViewController:self actionBlock:^{
        [PWPicasaAPI getListOfAlbumsWithIndex:index completion:^(NSArray *albums, NSUInteger nextIndex, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            
            sself.requestIndex = nextIndex;
            [sself.albums addObjectsFromArray:albums];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.collectionView reloadData];
            });
        }];
    }];
}

- (void)reloadData {
    __weak typeof(self) wself = self;
    [PWOAuthManager authorizeActionWithViewController:self actionBlock:^{
        [PWPicasaAPI getListOfAlbumsWithIndex:0 completion:^(NSArray *albums, NSUInteger nextIndex, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (error) {
                NSLog(@"%@", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sself.refreshControl endRefreshing];
                });
                return;
            }
            
            sself.requestIndex = nextIndex;
            sself.albums = albums.mutableCopy;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.collectionView reloadData];
                [sself.refreshControl endRefreshing];
            });
        }];
    }];
}

- (void)loadLocalData {
    __weak typeof(self) wself = self;
    [PWCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:@"PWAlbumManagedObject" inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        NSError *error;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        
        sself.albums = albums.mutableCopy;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!sself.isDisplayed) {
                [sself.collectionView reloadData];
            }
        });
    }];
}


@end
