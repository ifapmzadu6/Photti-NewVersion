//
//  PHAlbumDataSource.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEAlbumListDataSource.h"

#import "PEAlbumViewCell.h"
#import "PAString.h"
#import "NSIndexSet+methods.h"

@import Photos;

@interface PEAlbumListDataSource () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSArray *assetCollectionFetchResults;

@end

@implementation PEAlbumListDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        _fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
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
        [collectionView registerClass:[PEAlbumViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PEAlbumViewCell class])];
    }
}

- (void)setIsSelectMode:(BOOL)isSelectMode {
    _isSelectMode = isSelectMode;
    
    UICollectionView *collectionView = _collectionView;
    if (collectionView) {
        for (NSIndexPath *indexPath in collectionView.indexPathsForSelectedItems) {
            [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
        for (PEAlbumViewCell *cell in collectionView.visibleCells) {
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
    PEAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PEAlbumViewCell class]) forIndexPath:indexPath];
    __weak typeof(cell) wcell = cell;
    NSUInteger tag = indexPath.row;
    cell.tag = tag;
    cell.isSelectWithCheckmark = _isSelectMode;
    cell.firstImageView.image = nil;
    cell.secondImageView.image = nil;
    cell.thirdImageView.image = nil;
    cell.backgroundColor = (_cellBackgroundColor) ? _cellBackgroundColor : [UIColor whiteColor];
    
    PHFetchResult *assetsResult = _assetCollectionFetchResults[indexPath.row];
    if (assetsResult.count >= 1) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[0] targetSize:CGSizeMake(100.0f, 100.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            typeof(wcell) scell = wcell;
            if (!scell) return;
            if (scell.tag == tag) {
                scell.firstImageView.image = result;
            }
        }];
    }
    if (assetsResult.count >= 2) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[1] targetSize:CGSizeMake(75.0f, 75.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            typeof(wcell) scell = wcell;
            if (!scell) return;
            if (scell) {
                scell.secondImageView.image = result;
            }
        }];
    }
    if (assetsResult.count >= 3) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[2] targetSize:CGSizeMake(50.0f, 50.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            typeof(wcell) scell = wcell;
            if (!scell) return;
            if (scell) {
                scell.thirdImageView.image = result;
            }
        }];
    }
    
    PHAssetCollection *collection = _fetchResult[indexPath.row];
    cell.titleLabel.text = collection.localizedTitle;
    cell.detailLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Items", nil), collection.estimatedAssetCount];;
    return cell;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_flowLayout) {
        return _flowLayout.itemSize;
    }
    
    return _cellSize;
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

@end
