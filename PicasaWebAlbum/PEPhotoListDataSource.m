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

@import Photos;

@interface PEPhotoListDataSource () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSMutableArray *requestIDs;

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
        NSUInteger count = changeDetails.fetchResultAfterChanges.count;
        _fetchResult = changeDetails.fetchResultAfterChanges;
        
        [_collectionView performBatchUpdates:^{
            if (deleteIndexPaths) {
                [_collectionView deleteItemsAtIndexPaths:deleteIndexPaths];
            }
            if (insertIndexPaths) {
                [_collectionView insertItemsAtIndexPaths:insertIndexPaths];
            }
            if (reloadIndexPaths) {
                [_collectionView reloadItemsAtIndexPaths:reloadIndexPaths];
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
        else {
            cell.videoIconView.hidden = NO;
        }
    }
    
    return cell;
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

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelectMode) {
        if (_didChangeSelectedItemCountBlock) {
            _didChangeSelectedItemCountBlock(collectionView.indexPathsForSelectedItems.count);
        }
    }
    else {
        NSUInteger index = (_ascending) ? _fetchResult.count-indexPath.item-1 : indexPath.item;
        PHAsset *asset = _fetchResult[index];
        if (_didSelectAssetBlock) {
            _didSelectAssetBlock(asset, index);
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
