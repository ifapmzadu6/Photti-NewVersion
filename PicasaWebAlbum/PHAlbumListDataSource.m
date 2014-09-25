//
//  PHAlbumDataSource.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHAlbumListDataSource.h"

#import "PHAlbumViewCell.h"

@import Photos;

@interface PHAlbumListDataSource () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PHFetchResult *fetchResult;

@end

@implementation PHAlbumListDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        _fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:0];
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark Methods
- (void)prepareForUse:(UICollectionView *)collectionView {
    [collectionView registerClass:[PHAlbumViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PHAlbumViewCell class])];
    
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
    PHAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PHAlbumViewCell class]) forIndexPath:indexPath];
    
    if (_cellBackgroundColor) {
        cell.backgroundColor = _cellBackgroundColor;
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    cell.firstImageView.image = nil;
    cell.secondImageView.image = nil;
    cell.thirdImageView.image = nil;
    
    PHAssetCollection *collection = _fetchResult[indexPath.row];
    PHFetchResult *assetsResult = [PHAsset fetchKeyAssetsInAssetCollection:collection options:nil];
    if (assetsResult.count >= 1) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[0] targetSize:CGSizeMake(100.0f, 100.0f) contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions new] resultHandler:^(UIImage *result, NSDictionary *info) {
            cell.firstImageView.image = result;
        }];
    }
    if (assetsResult.count >= 2) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[1] targetSize:CGSizeMake(100.0f, 100.0f) contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions new] resultHandler:^(UIImage *result, NSDictionary *info) {
            cell.secondImageView.image = result;
        }];
    }
    if (assetsResult.count >= 3) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[2] targetSize:CGSizeMake(100.0f, 100.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            cell.thirdImageView.image = result;
        }];
    }
    
    cell.titleLabel.text = collection.localizedTitle;
    cell.detailLabel.text = [NSString stringWithFormat:@"%ld個の項目", (long)collection.estimatedAssetCount];
    return cell;
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

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *collection = _fetchResult[indexPath.row];
    if (_didSelectCollectionBlock) {
        _didSelectCollectionBlock(collection);
    }
}

@end