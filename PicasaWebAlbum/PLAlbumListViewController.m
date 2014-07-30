//
//  PLAlbumListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumListViewController.h"

#import "PWColors.h"
#import "PWSnowFlake.h"
#import "PLDateFormatter.h"
#import "PLAlbumViewCell.h"
#import "PLAssetsManager.h"
#import "PWTabBarController.h"
#import "PLCollectionFooterView.h"
#import "PLPhotoListViewController.h"
#import "PWBaseNavigationController.h"
#import "PLAlbumEditViewController.h"
#import "BlocksKit+UIKit.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"

#import "PDTaskManager.h"

#import "PWPicasaAPI.h"

@interface PLAlbumListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

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
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"%@", error.description);
        abort();
        return;
    }
    
    if (_fetchedResultsController.fetchedObjects == 0) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
    }
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
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 10.0f, 10.0f, viewInsets.bottom, 10.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    PLAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.album = [_fetchedResultsController objectAtIndexPath:indexPath];
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
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
        
        [_indicatorView stopAnimating];
    });
}

#pragma mark UIAlertView
- (void)showAlbumActionSheet:(PLAlbumObject *)album {
    NSManagedObjectID *albumID = album.objectID;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.name];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Edit", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PLAlbumEditViewController *viewController = [[PLAlbumEditViewController alloc] initWithTitle:album.name timestamp:album.timestamp uploading_type:album.tag_uploading_type];
        viewController.saveButtonBlock = ^(NSString *name, NSNumber *timestamp, NSNumber *uploading_type) {
            [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                PLAlbumObject *album = (PLAlbumObject *)[context objectWithID:albumID];
                album.name = name;
                album.tag_date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue];
                if (![album.timestamp isEqualToNumber:timestamp]) {
                    album.timestamp = timestamp;
                    album.edited = @(YES);
                }
                album.tag_uploading_type = uploading_type;
            }];
        };
        PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
        [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            });
        }];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] bk_initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.name]];
        [deleteActionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
            [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                PWAlbumObject *albumObject = (PWAlbumObject *)[context objectWithID:albumID];
                [context deleteObject:albumObject];
            }];
        }];
        [deleteActionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
        [deleteActionSheet showFromTabBar:sself.tabBarController.tabBar];
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
