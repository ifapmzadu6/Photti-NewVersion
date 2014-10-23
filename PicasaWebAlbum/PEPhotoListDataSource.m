//
//  PHAllPhotoListDataSource.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoListDataSource.h"

#import "PEPhotoViewCell.h"
#import "NSIndexSet+methods.h"
#import "PADateFormatter.h"
#import "PLCollectionFooterView.h"

@import Photos;

@interface PEPhotoListDataSource () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSMutableArray *requestIDs;

@property (weak, nonatomic) PLCollectionFooterView *footerView;

@end

@implementation PEPhotoListDataSource

- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult {
    self = [self initWithFetchResultOfPhoto:fetchResult assetCollection:nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult assetCollection:(PHAssetCollection *)assetCollection {
    self = [self initWithFetchResultOfPhoto:fetchResult assetCollection:assetCollection ascending:NO];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult assetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        _fetchResult = fetchResult;
        _assetCollection = assetCollection;
        _ascending = ascending;
        
        _requestIDs = @[].mutableCopy;
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
        [collectionView registerClass:[PEPhotoViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PEPhotoViewCell class])];
        [collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class])];
        
        collectionView.allowsMultipleSelection = YES;
    }
}

- (void)setIsSelectMode:(BOOL)isSelectMode {
    _isSelectMode = isSelectMode;
    
    UICollectionView *collectionView = _collectionView;
    if (collectionView) {
        for (NSIndexPath *indexPath in collectionView.indexPathsForSelectedItems) {
            [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
        for (PEPhotoViewCell *cell in collectionView.visibleCells) {
            cell.isSelectWithCheckmark = isSelectMode;
        }
    }
}

- (NSArray *)selectedAssets {
    if (!_isSelectMode) {
        return nil;
    }
    
    NSMutableArray *selectedAssets = @[].mutableCopy;
    UICollectionView *collectionView = _collectionView;
    if (collectionView) {
        for (NSIndexPath *indexPath in collectionView.indexPathsForSelectedItems) {
            NSUInteger index = (_ascending) ? _fetchResult.count-indexPath.item-1 : indexPath.item;
            PHAsset *asset = _fetchResult[index];
            [selectedAssets addObject:asset];
        }
    }
    return selectedAssets;
}

- (void)selectAssets:(NSArray *)assets animated:(BOOL)animated {
    for (PHAsset *asset in assets) {
        for (PHAsset *object in _fetchResult) {
            if ([asset isEqual:object]) {
                NSUInteger tmpIndex = [_fetchResult indexOfObject:object];
                NSUInteger index = (_ascending) ? _fetchResult.count-tmpIndex-1 : tmpIndex;
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [_collectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:UICollectionViewScrollPositionNone];
                break;
            }
        }
    }
}

- (void)selectAssetIdentifiers:(NSArray *)assetIdentifiers animated:(BOOL)animated {
    PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:assetIdentifiers options:nil];
    NSMutableArray *assetsArray = @[].mutableCopy;
    for (PHAsset *asset in assets) {
        [assetsArray addObject:asset];
    }
    [self selectAssets:assetsArray animated:animated];
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
    if (_ascending) {
        deleteIndexPaths = [self.class convertIndexPaths:deleteIndexPaths reverseIndex:_fetchResult.count-1];
        insertIndexPaths = [self.class convertIndexPaths:insertIndexPaths reverseIndex:_fetchResult.count-1];
        reloadIndexPaths = [self.class convertIndexPaths:reloadIndexPaths reverseIndex:_fetchResult.count-1];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _fetchResult = changeDetails.fetchResultAfterChanges;
        
        NSUInteger count = changeDetails.fetchResultAfterChanges.count;
        void (^completionBlock)() = ^{
            _didChangeItemCountBlock ? _didChangeItemCountBlock(count) : 0;
            
            PLCollectionFooterView *footerView = _footerView;
            if (footerView) {
                NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"- %lu Photos -", nil), (unsigned long)count];
                [footerView setText:albumCountString];
            }
        };
        
        UICollectionView *collectionView = _collectionView;
        if (collectionView) {
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
                completionBlock();
            }];
        }
        else {
            completionBlock();
        }
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
    PEPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PEPhotoViewCell class]) forIndexPath:indexPath];
    __weak typeof(cell) wcell = cell;
    NSUInteger tag = indexPath.row;
    cell.tag = tag;
    cell.isSelectWithCheckmark = _isSelectMode;
    cell.backgroundColor = _cellBackgroundColor;
    CGSize targetSize = (_flowLayout) ? _flowLayout.itemSize : _cellSize;
    NSUInteger index = (_ascending) ? (_fetchResult.count-indexPath.item-1) : indexPath.item;
    PHAsset *asset = _fetchResult[index];
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wcell) scell = wcell;
        if (!scell) return;
        if (scell.tag == tag) {
            scell.imageView.image = result;
        }
    }];
    cell.favoriteIconView.hidden = (asset.favorite) ? NO : YES;
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        cell.videoBackgroundView.hidden = NO;
        cell.videoDurationLabel.hidden = NO;
        cell.videoDurationLabel.text = [PADateFormatter arrangeDuration:asset.duration];
        if (asset.mediaSubtypes == PHAssetMediaSubtypeVideoTimelapse) {
            cell.videoTimelapseIconView.hidden = NO;
        }
        else if (asset.mediaSubtypes == PHAssetMediaSubtypeVideoHighFrameRate) {
            cell.videoSlomoIconView.hidden = NO;
        }
        else {
            cell.videoIconView.hidden = NO;
        }
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class]) forIndexPath:indexPath];
        
        NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"- %lu Photos -", nil), (unsigned long)_fetchResult.count];
        [footerView setText:albumCountString];
        
        _footerView = footerView;
        
        return footerView;
    }
    return nil;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_flowLayout) {
        return _flowLayout.itemSize;
    }
    
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return _landscapeCellSize;
    }
    else {
        return _cellSize;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (_flowLayout) {
        return _flowLayout.minimumInteritemSpacing;
    }
    
    return _minimumInteritemSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (_flowLayout) {
        return _flowLayout.minimumLineSpacing;
    }
    
    return _minimumLineSpacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_didChangeSelectedItemCountBlock) {
        _didChangeSelectedItemCountBlock(collectionView.indexPathsForSelectedItems.count);
    }
    
    NSUInteger index = (_ascending) ? _fetchResult.count-indexPath.item-1 : indexPath.item;
    PHAsset *asset = _fetchResult[index];
    if (_didSelectAssetBlock) {
        _didSelectAssetBlock(asset, index, _isSelectMode);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_didChangeSelectedItemCountBlock) {
        _didChangeSelectedItemCountBlock(collectionView.indexPathsForSelectedItems.count);
    }
    
    NSUInteger index = (_ascending) ? _fetchResult.count-indexPath.item-1 : indexPath.item;
    PHAsset *asset = _fetchResult[index];
    if (_didDeselectAssetBlock) {
        _didDeselectAssetBlock(asset, index, _isSelectMode);
    }
}

#pragma mark Ascending
+ (NSArray *)convertIndexPaths:(NSArray *)indexPaths reverseIndex:(NSUInteger)index {
    NSMutableArray *convertedIndexPaths = @[].mutableCopy;
    
    for (NSIndexPath *indexPath in indexPaths) {
        NSIndexPath *convertedIndexPath = [NSIndexPath indexPathForItem:(index-indexPath.item) inSection:indexPath.section];
        [convertedIndexPaths addObject:convertedIndexPath];
    }
    
    return convertedIndexPaths;
}

@end
