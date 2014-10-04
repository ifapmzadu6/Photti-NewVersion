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

@import Photos;

@interface PEPhotoListDataSource () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) UICollectionView *collectionView;
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
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        _fetchResult = fetchResult;
        _assetCollection = assetCollection;
        
        _requestIDs = @[].mutableCopy;
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark Methods
- (void)prepareForUse:(UICollectionView *)collectionView {
    [collectionView registerClass:[PEPhotoViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PEPhotoViewCell class])];
    
    _collectionView = collectionView;
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
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
        } completion:nil];
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
    NSUInteger index = indexPath.row;
    cell.tag = index;
    cell.imageView.image = nil;
    cell.isSelectWithCheckmark = _isSelectMode;
    cell.backgroundColor = _cellBackgroundColor;
    
    CGSize targetSize = (_flowLayout) ? _flowLayout.itemSize : _cellSize;
    [[PHImageManager defaultManager] requestImageForAsset:_fetchResult[indexPath.row] targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wcell) scell = wcell;
        if (!scell) return;
        if (scell.tag == index) {
            scell.imageView.image = result;
        }
    }];
    
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
        PHAsset *asset = _fetchResult[indexPath.row];
        if (_didSelectAssetBlock) {
            _didSelectAssetBlock(asset, indexPath.row);
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
