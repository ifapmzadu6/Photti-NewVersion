//
//  PWImagePickerLocalAllPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerLocalAllPhotoViewController.h"

#import "PWColors.h"
#import "PLPhotoViewCell.h"
#import "PLPhotoViewHeaderView.h"
#import "PLCollectionFooterView.h"
#import "PWImagePickerController.h"
#import "PWString.h"
#import "PLDateFormatter.h"
#import "PLAssetsManager.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"


@interface PWImagePickerLocalAllPhotoViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL isChangingContext;

@property (nonatomic) NSUInteger photosCount;
@property (nonatomic) NSUInteger videosCount;

@property (strong, nonatomic) NSMutableDictionary *headerViews;

@end

@implementation PWImagePickerLocalAllPhotoViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"All Items", nil);
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
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.allowsMultipleSelection = YES;
    [self.view addSubview:_collectionView];
    
    _headerViews = [NSMutableDictionary dictionary];
    
    __weak typeof(self) wself = self;
    [PLCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"tag_albumtype != %@", @(ALAssetsGroupPhotoStream)];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        
        sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"tag_adjusted_date" cacheName:nil];
        [sself.fetchedResultsController performFetch:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [sself.collectionView reloadData];
        });
    }];
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
    
    PWImagePickerController *tabBarViewController = (PWImagePickerController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
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
    PLPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (_isChangingContext) {
        cell.photo = nil;
    }
    else {
        cell.photo = [_fetchedResultsController objectAtIndexPath:indexPath];
    }
    cell.isSelectWithCheckMark = YES;
    
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
        [headerView setSelectButtonActionBlock:^{
        }];
        headerView.selectButtonActionBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PWImagePickerController *tabBarController = (PWImagePickerController *)sself.tabBarController;
            for (size_t i=0; i<sectionInfo.numberOfObjects; i++) {
                NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [sself.collectionView selectItemAtIndexPath:selectIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                
                [tabBarController addSelectedPhoto:sectionInfo.objects[selectIndexPath.row]];
            }
        };
        headerView.deselectButtonActionBlock = ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PWImagePickerController *tabBarController = (PWImagePickerController *)sself.tabBarController;
            for (size_t i=0; i<sectionInfo.numberOfObjects; i++) {
                NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [sself.collectionView deselectItemAtIndexPath:selectIndexPath animated:NO];
                
                [tabBarController removeSelectedPhoto:sectionInfo.objects[selectIndexPath.row]];
            }
        };
        NSUInteger count = 0;
        for (NSIndexPath *selectedIndexPath in _collectionView.indexPathsForSelectedItems) {
            if (indexPath.section == selectedIndexPath.section) {
                count++;
            }
        }
        if (count == sectionInfo.numberOfObjects) {
            [headerView setSelectButtonIsDeselect:YES];
        }
        else {
            [headerView setSelectButtonIsDeselect:NO];
        }
        
        [_headerViews setObject:headerView forKey:@(indexPath.section)];
        
        reusableView = headerView;
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
        [_headerViews removeObjectForKey:@(indexPath.section)];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(78.5f, 78.5f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0f;
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
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    [tabBarController addSelectedPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    
    NSUInteger count = 0;
    for (NSIndexPath *selectedIndexPath in _collectionView.indexPathsForSelectedItems) {
        if (indexPath.section == selectedIndexPath.section) {
            count++;
        }
    }
    for (NSNumber *sectionIndex in _headerViews.allKeys) {
        if (sectionIndex.integerValue == indexPath.section) {
            PLPhotoViewHeaderView *headerView = [_headerViews objectForKey:@(indexPath.section)];
            id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[indexPath.section];
            if (count == sectionInfo.numberOfObjects) {
                [headerView setSelectButtonIsDeselect:YES];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    [tabBarController removeSelectedPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    
    NSUInteger count = 0;
    for (NSIndexPath *selectedIndexPath in _collectionView.indexPathsForSelectedItems) {
        if (indexPath.section == selectedIndexPath.section) {
            count++;
        }
    }
    for (NSNumber *sectionIndex in _headerViews.allKeys) {
        if (sectionIndex.integerValue == indexPath.section) {
            PLPhotoViewHeaderView *headerView = [_headerViews objectForKey:@(indexPath.section)];
            id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[indexPath.section];
            if (count == sectionInfo.numberOfObjects) {
                [headerView setSelectButtonIsDeselect:NO];
            }
        }
    }
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = NO;
    
    NSError *coredataError = nil;
    [_fetchedResultsController performFetch:&coredataError];
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.collectionView reloadData];
    });
}

@end
