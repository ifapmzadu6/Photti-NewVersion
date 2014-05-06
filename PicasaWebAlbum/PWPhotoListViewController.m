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

#import "PWPhotoViewCell.h"

@interface PWPhotoListViewController ()

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSMutableArray *photos;
@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isDisplayed;

@end

@implementation PWPhotoListViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [super init];
    if (self) {
        _album = album;
        
        _photos = [NSMutableArray array];
        
        self.title = album.title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PWPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.autoresizesSubviews = YES;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [_collectionView addSubview:_refreshControl];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[addBarButtonItem, searchBarButtonItem];
    
    [self loadDataWithStartIndex:0];
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
    return _photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PWPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.photo = _photos[indexPath.row];
    
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
}

#pragma mark BarButtonAction
- (void)searchBarButtonAction {
    
}

- (void)addBarButtonAction {
    
}

#pragma mark LoadData
- (void)loadDataWithStartIndex:(NSUInteger)index {
    NSString *albumID = _album.id_str;
    
    __weak typeof(self) wself = self;
    [PWOAuthManager authorizeActionWithViewController:self actionBlock:^{
        [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:albumID index:index completion:^(NSArray *photos, NSUInteger nextIndex, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            
            sself.requestIndex = nextIndex;
            [sself.photos addObjectsFromArray:photos];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.collectionView reloadData];
            });
        }];
    }];
}

@end
