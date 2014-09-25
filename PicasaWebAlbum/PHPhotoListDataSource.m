//
//  PHAllPhotoListDataSource.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHPhotoListDataSource.h"

#import "PHPhotoViewCell.h"

@import Photos;

@interface PHPhotoListDataSource () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) UICollectionView *collectionView;

@end

@implementation PHPhotoListDataSource

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
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark Methods
- (void)prepareForUse:(UICollectionView *)collectionView {
    [collectionView registerClass:[PHPhotoViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PHPhotoViewCell class])];
    
    _collectionView = collectionView;
}

#pragma mark PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    
}

#pragma mark UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _fetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PHPhotoViewCell class]) forIndexPath:indexPath];
    
    CGSize targetSize = CGSizeZero;
    if (_flowLayout) {
        targetSize = _flowLayout.itemSize;
    }
    else {
        targetSize = _cellSize;
    }
    [[PHImageManager defaultManager] requestImageForAsset:_fetchResult[indexPath.row] targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        cell.imageView.image = result;
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
    PHAsset *asset = _fetchResult[indexPath.row];
    if (_didSelectAssetBlock) {
        _didSelectAssetBlock(asset, indexPath.row);
    }
}

@end
