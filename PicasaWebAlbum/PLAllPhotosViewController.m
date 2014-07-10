//
//  PLAllPhotosViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAllPhotosViewController.h"

#import "PWColors.h"
#import "PLPhotoViewCell.h"
#import "PLPhotoViewHeaderView.h"
#import "PLCollectionFooterView.h"
#import "PWTabBarController.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLDateFormatter.h"
#import "PWString.h"
#import "PLPhotoPageViewController.h"

@interface PLAllPhotosViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *headers;

@property (nonatomic) NSUInteger photosCount;
@property (nonatomic) NSUInteger videosCount;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PLAllPhotosViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"All Items", nil);
        
        _headers = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLPhotoViewHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"tag_albumtype != %@", @(ALAssetsGroupPhotoStream)];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"tag_adjusted_date" cacheName:nil];
    [_fetchedResultsController performFetch:nil];
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
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    }
    else {
        _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top, 20.0f, viewInsets.bottom, 20.0f);
    }
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Methods
- (void)setIsSelectMode:(BOOL)isSelectMode withSelectIndexPaths:(NSArray *)selectIndexPaths {
    _isSelectMode = isSelectMode;
    
    _collectionView.allowsMultipleSelection = isSelectMode;
    for (PLPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = isSelectMode;
    }
    if (isSelectMode) {
        for (NSIndexPath *indexPath in selectIndexPaths) {
            [_collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
    if (!isSelectMode) {
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        
        for (PLPhotoViewHeaderView *headerView in _headers) {
            [headerView setSelectButtonIsDeselect:NO];
        }
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
        NSArray *filteredPhotoObjects = [sectionInfo.objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypePhoto]];
        NSArray *filteredVideoObjects = [sectionInfo.objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypeVideo]];
        [headerView setDetail:[PWString photoAndVideoStringWithPhotoCount:filteredPhotoObjects.count videoCount:filteredVideoObjects.count]];
        __weak typeof(self) wself = self;
        headerView.selectButtonActionBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            NSMutableArray *indexPaths = [NSMutableArray array];
            id<NSFetchedResultsSectionInfo> sectionInfo = sself.fetchedResultsController.sections[indexPath.section];
            for (size_t i=0; i<sectionInfo.numberOfObjects; i++) {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [indexPaths addObject:tmpIndexPath];
            }
            [sself setIsSelectMode:YES withSelectIndexPaths:indexPaths];
            
            if (sself.headerViewDidTapBlock) {
                sself.headerViewDidTapBlock(YES);
            }
            
            if (sself.photoDidSelectedInSelectModeBlock) {
                sself.photoDidSelectedInSelectModeBlock(indexPaths);
            }
        };
        headerView.deselectButtonActionBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            id<NSFetchedResultsSectionInfo> sectionInfo = sself.fetchedResultsController.sections[indexPath.section];
            for (size_t i=0; i<sectionInfo.numberOfObjects; i++) {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [sself.collectionView deselectItemAtIndexPath:tmpIndexPath animated:YES];
            }
        };
        
        reusableView = headerView;
        
        [_headers addObject:headerView];
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (indexPath.section == _fetchedResultsController.sections.count - 1) {
            PLCollectionFooterView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
            
            NSString *localizedString = NSLocalizedString(@"All Photos:%lu, All Videos:%lu", nil);
            [footer setText:[NSString stringWithFormat:localizedString, _photosCount, _videosCount]];
            
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
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(112.0f, 112.0f);
        }
        else {
            return CGSizeMake(106.0f, 106.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(172.0f, 187.0f);
        }
        else {
            return CGSizeMake(172.0f, 187.0f);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return 2.0f;
        }
        else {
            return 1.0f;
        }
    }
    else {
        return 10.0f;
    }
}

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

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

@end
