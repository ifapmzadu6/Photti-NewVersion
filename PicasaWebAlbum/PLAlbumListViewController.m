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
#import "PWAlbumCollectionViewFlowLayout.h"
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
@property (strong, nonatomic) UIImageView *noItemImageView;

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
    
    PWAlbumCollectionViewFlowLayout *collectionViewLayout = [[PWAlbumCollectionViewFlowLayout alloc] init];
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
    
    if (_fetchedResultsController.fetchedObjects.count == 0) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setAdsHidden:NO animated:NO];
    
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
    
    NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {return [obj1 compare:obj2];}];
    NSIndexPath *indexPath = nil;
    if (indexPaths.count > 0) {
        indexPath = indexPaths[indexPaths.count / 2];
    }
    
    PWTabBarController *tabBarViewController = (PWTabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 10.0f, 10.0f, viewInsets.bottom, 10.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    _collectionView.frame = rect;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    
    _indicatorView.center = self.view.center;
    
    [self layoutNoItem];
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
    cell.actionButtonActionBlock = ^(PLAlbumObject *album) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself showAlbumActionSheet:album];
    };
    
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

#pragma mark UICollectionViewFlowLayout
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
        
        [self refreshNoItemWithNumberOfItem:controller.fetchedObjects.count];
    });
}

#pragma mark UIAlertView
- (void)showAlbumActionSheet:(PLAlbumObject *)album {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:album.name];
    __weak typeof(self) wself = self;
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Edit", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself editActionSheetAciton:album];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Share", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself shareActionSheetAction:album];
    }];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Upload", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself uploadActionSheetAction:album];
    }];
    [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself deleteActionSheetAction:album];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)editActionSheetAciton:(PLAlbumObject *)album {
    PLAlbumEditViewController *viewController = [[PLAlbumEditViewController alloc] initWithTitle:album.name timestamp:album.timestamp uploading_type:album.tag_uploading_type];
    NSManagedObjectID *albumID = album.objectID;
    viewController.saveButtonBlock = ^(NSString *name, NSNumber *timestamp, NSNumber *uploading_type) {
        [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumID];
            albumObject.name = name;
            albumObject.tag_date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue / 1000];
            if (![albumObject.timestamp isEqualToNumber:timestamp]) {
                albumObject.timestamp = timestamp;
                albumObject.edited = @(YES);
            }
            albumObject.tag_uploading_type = uploading_type;
        }];
    };
    PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)shareActionSheetAction:(PLAlbumObject *)album {
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
            NSLog(@"%@", error);
        }];
    }
}

- (void)uploadActionSheetAction:(PLAlbumObject *)album {
    [[PDTaskManager sharedManager] addTaskFromLocalAlbum:album toWebAlbum:nil completion:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        });
    }];
}

- (void)deleteActionSheetAction:(PLAlbumObject *)album {
    UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] bk_initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.name]];
    NSManagedObjectID *albumID = album.objectID;
    [deleteActionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Delete", nil) handler:^{
        [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PWAlbumObject *albumObject = (PWAlbumObject *)[context objectWithID:albumID];
            [context deleteObject:albumObject];
        }];
    }];
    [deleteActionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    [deleteActionSheet showFromTabBar:self.tabBarController.tabBar];
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
        _noItemImageView.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.2f];
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
