//
//  PLAlbumListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumListViewController.h"

#import "PAColors.h"
#import "PASnowFlake.h"
#import "PADateFormatter.h"
#import "PADateTimestamp.h"
#import "PLAlbumViewCell.h"
#import "PLAssetsManager.h"
#import "PATabBarAdsController.h"
#import "PLCollectionFooterView.h"
#import "PAAlbumCollectionViewFlowLayout.h"
#import "PAViewControllerKit.h"
#import "PLPhotoListViewController.h"
#import "PABaseNavigationController.h"
#import "PLAlbumEditViewController.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PAActivityIndicatorView.h"

#import "PDTaskManager.h"

#import "PWPicasaAPI.h"

@interface PLAlbumListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PAActivityIndicatorView *indicatorView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) PLAlbumObject *actionSheetItem;

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
    
    PAAlbumCollectionViewFlowLayout *collectionViewLayout = [PAAlbumCollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        abort();
        return;
    }
    
    if (_fetchedResultsController.fetchedObjects.count == 0) {
        _indicatorView = [PAActivityIndicatorView new];
        [self.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
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
    
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    UIEdgeInsets contentInset = UIEdgeInsetsMake(viewInsets.top + 15.0f, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
    
    _indicatorView.center = self.view.center;
    
    [self layoutNoItem];
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
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"- %lu Albums -", nil), (unsigned long)_fetchedResultsController.fetchedObjects.count];
        [footerView setText:albumCountString];
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

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == 1001) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Edit", nil)]) {
            [self editActionSheetAciton:self.actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Share", nil)]) {
            [self shareActionSheetAction:self.actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Upload", nil)]) {
            [self uploadActionSheetAction:self.actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            [self deleteActionSheetAction:self.actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1002) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            NSManagedObjectID *albumID = self.actionSheetItem.objectID;
            [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PWAlbumObject *albumObject = (PWAlbumObject *)[context objectWithID:albumID];
                [context deleteObject:albumObject];
            }];
        }
    }
}

#pragma mark UIAlertView
- (void)showAlbumActionSheet:(PLAlbumObject *)album {
    _actionSheetItem = album;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:album.name delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:NSLocalizedString(@"Edit", nil), NSLocalizedString(@"Share", nil), NSLocalizedString(@"Upload", nil), nil];
    actionSheet.tag = 1001;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)editActionSheetAciton:(PLAlbumObject *)album {
    PLAlbumEditViewController *viewController = [[PLAlbumEditViewController alloc] initWithTitle:album.name timestamp:album.timestamp uploading_type:album.tag_uploading_type];
    NSManagedObjectID *albumID = album.objectID;
    viewController.saveButtonBlock = ^(NSString *name, NSNumber *timestamp, NSNumber *uploading_type) {
        [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumID];
            albumObject.name = name;
            albumObject.tag_date = [PADateTimestamp dateForTimestamp:timestamp.stringValue];
            if (![albumObject.timestamp isEqualToNumber:timestamp]) {
                albumObject.timestamp = timestamp;
                albumObject.edited = @YES;
            }
            albumObject.tag_uploading_type = uploading_type;
        }];
    };
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? YES : NO;
    if (isPhone) {
        navigationController.transitioningDelegate = (id)navigationController;
    }
    else {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
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
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }];
    }
}

- (void)uploadActionSheetAction:(PLAlbumObject *)album {
    [[PDTaskManager sharedManager] addTaskFromLocalAlbum:album toWebAlbum:nil completion:^(NSError *error) {
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        });
    }];
}

- (void)deleteActionSheetAction:(PLAlbumObject *)album {
    _actionSheetItem = album;
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.name];
    UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    deleteActionSheet.tag = 1002;
    [deleteActionSheet showFromTabBar:self.tabBarController.tabBar];
}

@end
