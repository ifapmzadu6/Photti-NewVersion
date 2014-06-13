//
//  PLAlbumListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumListViewController.h"

#import "PWColors.h"
#import "PLAlbumViewCell.h"
#import "PLAssetsManager.h"
#import "PWTabBarController.h"
#import "PLCollectionFooterView.h"
#import "PLPhotoListViewController.h"
#import "BlocksKit+UIKit.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"

#import "PDTaskManager.h"

#import "PWPicasaAPI.h"

@interface PLAlbumListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@property (strong, nonatomic) NSArray *albums;

@end

@implementation PLAlbumListViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"アルバム", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.contentInset = UIEdgeInsetsMake(10.0f, 0.0f, 0.0f, 0.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -10.0f);
    _collectionView.scrollsToTop = NO;
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_collectionView];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_indicatorView];
    [_indicatorView startAnimating];
    
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
    
    _collectionView.scrollsToTop = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _collectionView.scrollsToTop = NO;    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = CGRectMake(10.0f, 0.0f, rect.size.width - 20.0f, rect.size.height);
    
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
    
    PWTabBarController *tabBarViewController = (PWTabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 10.0f, 0.0f, viewInsets.bottom, 0.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, -10.0f);
    
    if (_indicatorView) {
        _indicatorView.center = self.view.center;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!_albums) {
        return 0;
    }
    return _albums.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.album = _albums[indexPath.row];
    __weak typeof(self) wself = self;
    [cell setActionButtonActionBlock:^(PLAlbumObject *album) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself showAlbumActionSheet:album];
    }];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    if (_albums) {
        NSString *localizedString = NSLocalizedString(@"%lu個のアルバム", nil);
        NSString *albumCountString = [NSString stringWithFormat:localizedString, (unsigned long)_albums.count];
        [footerView setText:albumCountString];
    }
    
    return footerView;
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PLPhotoListViewController *viewController = [[PLPhotoListViewController alloc] initWithAlbum:_albums[indexPath.row]];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark LoadData
- (void)reloadData {
    if (![[PLAssetsManager sharedManager] isLibraryUpDated]) {
        __weak typeof(self) wself = self;
        [PLAssetsManager getAllAlbumsWithCompletion:^(NSArray *allAlbums, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            sself.albums = allAlbums;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [sself.indicatorView removeFromSuperview];
                sself.indicatorView = nil;
                
                [sself.collectionView reloadData];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sself.albums.count-1 inSection:0];
                [sself.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            });
        }];
    }
}

#pragma mark UIAlertView
- (void)showAlbumActionSheet:(PLAlbumObject *)album {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.name];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"共有", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself shareAlbum:album];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"アップロード", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself makeNewWebAlbumWithLocalAlbum:album completion:^(PWAlbumObject *webAlbum, NSError *error) {
            [PDTaskManager addTaskFromLocalAlbum:album toWebAlbum:webAlbum completion:^(NSError *error) {
                NSLog(@"成功したよ！！！！やったよ！！！！");
                if (error) {
                    NSLog(@"%@", error.description);
                }
            }];
        }];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"削除", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself removeAlbum:album completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself reloadData];
            });
        }];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{
    }];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark HandleModelObject
- (void)removeAlbum:(PLAlbumObject *)album completion:(void (^)())completion {
    [PLCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
        [context deleteObject:album];
        NSError *error = nil;
        [context save:&error];
        
        if (completion) {
            completion();
        }
    }];
}

- (void)shareAlbum:(PLAlbumObject *)album {
    NSMutableArray *assets = [NSMutableArray array];
    for (PLPhotoObject *photo in album.photos) {
        [PLAssetsManager assetForURL:[NSURL URLWithString:photo.url] resultBlock:^(ALAsset *asset) {
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

- (void)makeNewWebAlbumWithLocalAlbum:(PLAlbumObject *)album completion:(void(^)(PWAlbumObject *album, NSError *error))completion {
    [PWPicasaAPI postCreatingNewAlbumRequestWithTitle:album.name
                                              summary:nil
                                             location:nil
                                               access:kPWPicasaAPIGphotoAccessProtected
                                            timestamp:album.timestamp.stringValue
                                             keywords:nil
                                           completion:completion];
}

@end
