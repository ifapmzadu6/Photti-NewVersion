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

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL isChangingContext;

@end

@implementation PLAlbumListViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Albums", nil);
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
    _collectionView.scrollsToTop = NO;
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_indicatorView];
    [_indicatorView startAnimating];
    
    __weak typeof(self) wself = self;
    [[PLAssetsManager sharedManager] enumurateAssetsWithCompletion:^(NSError *error) {
        if (error) return;
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [PLCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
            
            sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
            sself.fetchedResultsController.delegate = sself;
            
            NSError *error = nil;
            [sself.fetchedResultsController performFetch:&error];
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself.indicatorView stopAnimating];
                
                if (sself.collectionView.indexPathsForVisibleItems.count == 0) {
                    [sself.collectionView reloadData];
                }
            });
        }];
    }];
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
    
    PWTabBarController *tabBarViewController = (PWTabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 10.0f , 10.0f, viewInsets.bottom, 10.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    
    if (_indicatorView) {
        _indicatorView.center = self.view.center;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (_isChangingContext) {
        return 0;
    }
    
    return _fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_isChangingContext) {
        return 0;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (_isChangingContext) {
        cell.album = nil;
    }
    else {
        cell.album = [_fetchedResultsController objectAtIndexPath:indexPath];
    }
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
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"%lu Albums", nil), (unsigned long)_fetchedResultsController.fetchedObjects.count];
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
            return CGSizeMake(177.0f, ceilf(177.0f * 3.0f / 4.0f) + 40.0f);
        }
        else {
            return CGSizeMake(146.0f, ceilf(146.0f * 3.0f / 4.0f) + 40.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(192.0f, ceilf(192.0f * 3.0f / 4.0f) + 40.0f);
        }
        else {
            return CGSizeMake(181.0f, ceilf(181.0f * 3.0f / 4.0f) + 40.0f);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 8.0f;
    }
    return 20.0f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PLPhotoListViewController *viewController = [[PLPhotoListViewController alloc] initWithAlbum:[_fetchedResultsController objectAtIndexPath:indexPath]];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = NO;
    
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

#pragma mark UIAlertView
- (void)showAlbumActionSheet:(PLAlbumObject *)album {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.name];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Edit", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        UIAlertView *alertView = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"Edit Album", nil) message:NSLocalizedString(@"Enter album title.", nil)];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [alertView textFieldAtIndex:0];
        textField.text = album.name;
        [alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
        [alertView bk_addButtonWithTitle:NSLocalizedString(@"Save", nil) handler:^{
            [PLCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
                album.name = textField.text;
                
                [context save:nil];
            }];
        }];
        [alertView show];
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
            [[PDTaskManager sharedManager] start];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Added new tasks.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alertView show];
            });
        }];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [PLCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
            [context deleteObject:album];
            [context save:nil];
        }];
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
