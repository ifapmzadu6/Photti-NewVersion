//
//  PHMomentDataSource.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEMomentListDataSource.h"

@import Photos;

#import "PEMomentViewCell.h"
#import "PADateFormatter.h"
#import "PAString.h"
#import "NSIndexSet+methods.h"
#import "PLCollectionFooterView.h"

@interface PEMomentListDataSource () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSMutableArray *assetCollectionFetchResults;

@end

@implementation PEMomentListDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        PHFetchOptions *options = [PHFetchOptions new];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:NO]];
        _fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeMoment subtype:PHAssetCollectionSubtypeAny options:options];
        NSMutableArray *assetCollectionFetchResults = @[].mutableCopy;
        for (PHAssetCollection *collection in _fetchResult) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            [assetCollectionFetchResults addObject:fetchResult];
        }
        _assetCollectionFetchResults = assetCollectionFetchResults;
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark Methods
- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    
    if (collectionView) {
        [collectionView registerClass:[PEMomentViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PEMomentViewCell class])];
        [collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class])];
    }
}

- (void)setIsSelectMode:(BOOL)isSelectMode {
    _isSelectMode = isSelectMode;
    
    UICollectionView *collectionView = _collectionView;
    if (collectionView) {
        for (NSIndexPath *indexPath in collectionView.indexPathsForSelectedItems) {
            [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
        for (PEMomentViewCell *cell in collectionView.visibleCells) {
            cell.isSelectWithCheckmark = isSelectMode;
        }
    }
}

- (NSArray *)selectedCollections {
    if (!_isSelectMode) {
        return nil;
    }
    
    NSMutableArray *selectedCollections = @[].mutableCopy;
    UICollectionView *collectionView = _collectionView;
    if (collectionView) {
        for (NSIndexPath *indexPath in collectionView.indexPathsForSelectedItems) {
            PHAssetCollection *assetCollection = _fetchResult[indexPath.item];
            [selectedCollections addObject:assetCollection];
        }
    }
    return selectedCollections;
}

#pragma mark PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:_fetchResult];
    if (!changeDetails) {
        return;
    }
    NSArray *deleteIndexPaths = [changeDetails.removedIndexes indexPathsForSection:0];
    NSArray *insertIndexPaths = [changeDetails.insertedIndexes indexPathsForSection:0];
    NSArray *reloadIndexPaths = [changeDetails.changedIndexes indexPathsForSection:0];
    NSMutableArray *assetCollectionFetchResults = @[].mutableCopy;
    for (PHAssetCollection *collection in changeDetails.fetchResultAfterChanges) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        [assetCollectionFetchResults addObject:fetchResult];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger count = changeDetails.fetchResultAfterChanges.count;
        _fetchResult = changeDetails.fetchResultAfterChanges;
        _assetCollectionFetchResults = assetCollectionFetchResults;
        
        UICollectionView *collectionView = _collectionView;
        [collectionView performBatchUpdates:^{
            if (deleteIndexPaths) {
                [collectionView deleteItemsAtIndexPaths:deleteIndexPaths];
            }
            if (insertIndexPaths) {
                [collectionView insertItemsAtIndexPaths:insertIndexPaths];
            }
            if (reloadIndexPaths) {
                [collectionView reloadItemsAtIndexPaths:reloadIndexPaths];
            }
        } completion:^(BOOL finished) {
            if (_didChangeItemCountBlock) {
                _didChangeItemCountBlock(count);
            }
        }];
    });
}

#pragma mark UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _fetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PEMomentViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PEMomentViewCell class]) forIndexPath:indexPath];
    __weak typeof(cell) wcell = cell;
    NSUInteger tag = indexPath.row;
    cell.tag = tag;
    cell.isSelectWithCheckmark = _isSelectMode;
    for (UIImageView *imageView in cell.imageViews) {
        imageView.image = nil;
    }
    cell.backgroundColor = (_cellBackgroundColor) ? _cellBackgroundColor : [UIColor whiteColor];
    
    PHFetchResult *assetsResult = _assetCollectionFetchResults[indexPath.row];
    cell.numberOfImageView = assetsResult.count;
    NSUInteger numberOfColAndRow = sqrtf(cell.numberOfImageView);
    CGSize targetSize = CGSizeMake(_cellSize.width/numberOfColAndRow, _cellSize.height/numberOfColAndRow);
    for (int i=0; i<cell.numberOfImageView; i++) {
        PHAsset *asset = assetsResult[i];
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            typeof(wcell) scell = wcell;
            if (!scell) return;
            if (scell.tag == tag) {
                UIImageView *imageView = scell.imageViews[i];
                imageView.image = result;
            }
        }];
    }
    
    PHAssetCollection *collection = _fetchResult[indexPath.row];
    cell.titleLabel.text = [PEMomentListDataSource titleForMoment:collection];
    NSUInteger numberOfPhoto = 0;
    NSUInteger numberOfVideo = 0;
    for (PHAsset *asset in assetsResult) {
        if (asset.mediaType == PHAssetMediaTypeImage) {
            numberOfPhoto++;
        }
        else if (asset.mediaType == PHAssetMediaTypeVideo) {
            numberOfVideo++;
        }
    }
    cell.detailLabel.text = [PAString photoAndVideoStringWithPhotoCount:numberOfPhoto videoCount:numberOfVideo isInitialUpperCase:YES];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class]) forIndexPath:indexPath];
        
        if (_fetchResult.count > 0) {
            NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"- %lu Albums -", nil), (unsigned long)_fetchResult.count];
            [footerView setText:albumCountString];
        }
        
        return footerView;
    }
    return nil;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return _minimumInteritemSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return _minimumLineSpacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        if (_didChangeSelectedItemCountBlock) {
            _didChangeSelectedItemCountBlock(collectionView.indexPathsForSelectedItems.count);
        }
    }
    else {
        PHAssetCollection *collection = _fetchResult[indexPath.row];
        if (_didSelectCollectionBlock) {
            _didSelectCollectionBlock(collection);
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        if (_didChangeSelectedItemCountBlock) {
            _didChangeSelectedItemCountBlock(collectionView.indexPathsForSelectedItems.count);
        }
    }
}

#pragma mark Title
+ (NSString *)titleForMoment:(PHAssetCollection *)moment {
    NSString *title = moment.localizedTitle;
    if (!title) {
        NSString *startDate = [[PADateFormatter mmmddFormatter] stringFromDate:moment.startDate];
        NSString *endDate = [[PADateFormatter mmmddFormatter] stringFromDate:moment.endDate];
        if ([startDate isEqualToString:endDate]) {
            title = startDate;
        }
        else {
            title = [NSString stringWithFormat:@"%@ - %@", startDate, endDate];
        }
    }
    return title;
}

@end
