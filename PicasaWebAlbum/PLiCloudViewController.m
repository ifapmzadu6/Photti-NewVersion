//
//  PLiCloudViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLiCloudViewController.h"

#import "PAColors.h"
#import "PLPhotoViewCell.h"
#import "PLPhotoViewHeaderView.h"
#import "PLCollectionFooterView.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PATabBarController.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PADateFormatter.h"
#import "PAString.h"
#import "PLCoreDataAPI.h"
#import "PAViewControllerKit.h"
#import "PLPhotoPageViewController.h"

@interface PLiCloudViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *headers;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PLiCloudViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"iCloud", nil);
        
        _headers = @[].mutableCopy;
        _selectedPhotos = @[].mutableCopy;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PAPhotoCollectionViewFlowLayout *collectionViewLayout = [PAPhotoCollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLPhotoViewHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"tag_albumtype = %@", @(ALAssetsGroupPhotoStream)];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"tag_adjusted_date" cacheName:nil];
    _fetchedResultsController.delegate = self;
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        abort();
        return;
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
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
    
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    UIEdgeInsets contentInset = UIEdgeInsetsZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    }
    else {
        contentInset = UIEdgeInsetsMake(viewInsets.top, 20.0f, viewInsets.bottom, 20.0f);
    }
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];    
}

#pragma mark Methods
- (void)setSelectedPhotos:(NSMutableArray *)selectedPhotos {
    _selectedPhotos = selectedPhotos;
    
    for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    for (PLPhotoObject *photoObject in selectedPhotos) {
        NSIndexPath *indexPath = [_fetchedResultsController indexPathForObject:photoObject];
        if (indexPath) {
            [_collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
}

- (void)setIsSelectMode:(BOOL)isSelectMode {
    _isSelectMode = isSelectMode;
    
    _collectionView.allowsMultipleSelection = isSelectMode;
    for (PLPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = isSelectMode;
    }
    for (PLPhotoViewHeaderView *header in _headers) {
        [header setSelectButtonIsDeselect:NO];
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
    PLPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.photo = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.isSelectWithCheckMark = _isSelectMode;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        PLPhotoViewHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
        
        PLPhotoObject *photoObject = [_fetchedResultsController objectAtIndexPath:indexPath];
        [headerView setText:photoObject.tag_adjusted_date];
        id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[indexPath.section];
        if (_isSelectMode) {
            NSUInteger count = [self numberOfSelectedIndexPathsInSection:indexPath.section];
            [headerView setSelectButtonIsDeselect:([sectionInfo numberOfObjects] == count)];
        }
        else {
            [headerView setSelectButtonIsDeselect:NO];
        }
        NSArray *filteredPhotoObjects = [sectionInfo.objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypePhoto]];
        NSArray *filteredVideoObjects = [sectionInfo.objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypeVideo]];
        [headerView setDetail:[PAString photoAndVideoStringWithPhotoCount:filteredPhotoObjects.count videoCount:filteredVideoObjects.count]];
        
        __weak typeof(self) wself = self;
        __weak typeof(headerView) wheaderView = headerView;
        headerView.selectButtonActionBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (sself.headerViewDidTapBlock) {
                sself.headerViewDidTapBlock(YES);
            }
            
            sself.isSelectMode = YES;
            NSMutableArray *indexPaths = [NSMutableArray array];
            id<NSFetchedResultsSectionInfo> sectionInfo = sself.fetchedResultsController.sections[indexPath.section];
            for (size_t i=0; i<sectionInfo.numberOfObjects; i++) {
                NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [sself.collectionView selectItemAtIndexPath:selectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                [sself.selectedPhotos addObject:[sself.fetchedResultsController objectAtIndexPath:selectedIndexPath]];
            }
            typeof(wheaderView) sheaderView = wheaderView;
            if (!sheaderView) return;
            [sheaderView setSelectButtonIsDeselect:YES];
            
            if (sself.photoDidSelectedInSelectModeBlock) {
                sself.photoDidSelectedInSelectModeBlock(indexPaths);
            }
        };
        headerView.deselectButtonActionBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            sself.isSelectMode = NO;
            id<NSFetchedResultsSectionInfo> sectionInfo = sself.fetchedResultsController.sections[indexPath.section];
            for (size_t i=0; i<sectionInfo.numberOfObjects; i++) {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [sself.collectionView deselectItemAtIndexPath:tmpIndexPath animated:YES];
                [sself.selectedPhotos removeObject:[sself.fetchedResultsController objectAtIndexPath:tmpIndexPath]];
            }
            
            if (sself.headerViewDidTapBlock) {
                sself.headerViewDidTapBlock(NO);
            }
        };
        
        reusableView = headerView;
        
        [_headers addObject:headerView];
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (indexPath.section == _fetchedResultsController.sections.count - 1) {
            PLCollectionFooterView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
            
            NSArray *photos = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypePhoto]];
            NSArray *videos = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypeVideo]];
            
            NSString *localizedString = NSLocalizedString(@"All Photos:%lu, All Videos:%lu", nil);
            [footer setText:[NSString stringWithFormat:localizedString, photos.count, videos.count]];
            
            reusableView = footer;
        }
        else {
            reusableView = [[UICollectionReusableView alloc] init];
        }
    }
    
    return reusableView;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        [_headers removeObject:view];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 60.0f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section < _fetchedResultsController.sections.count - 1) {
        return CGSizeZero;
    }
    
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        [_selectedPhotos addObject:[_fetchedResultsController objectAtIndexPath:indexPath]];
        return;
    }
    
    __block NSUInteger index = 0;
    [_fetchedResultsController.sections enumerateObjectsUsingBlock:^(id<NSFetchedResultsSectionInfo> obj, NSUInteger idx, BOOL *stop) {
        if (idx == indexPath.section) {
            *stop = YES;
            return;
        }
        index += obj.objects.count;
    }];
    index += indexPath.row;
    
    PLPhotoPageViewController *viewController = [[PLPhotoPageViewController alloc] initWithPhotos:_fetchedResultsController.fetchedObjects index:index];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        [_selectedPhotos removeObject:[_fetchedResultsController objectAtIndexPath:indexPath]];
    }
}

#pragma mark Methods
- (NSUInteger)numberOfSelectedIndexPathsInSection:(NSUInteger)section {
    NSUInteger count = 0;
    NSUInteger index = 0;
    while (index < _collectionView.indexPathsForSelectedItems.count && count < [_collectionView numberOfItemsInSection:section]) {
        NSIndexPath *tmpIndexPath = _collectionView.indexPathsForSelectedItems[index];
        if (tmpIndexPath.section == section) {
            count++;
        }
        index++;
    }
    return count;
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
        
        [self refreshNoItemWithNumberOfItem:controller.fetchedObjects.count];
    });
}

@end
