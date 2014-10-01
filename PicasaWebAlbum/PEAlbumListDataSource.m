//
//  PHAlbumDataSource.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEAlbumListDataSource.h"

#import "PEAlbumViewCell.h"

@import Photos;

@interface PEAlbumListDataSource () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PHFetchResult *fetchResult;

@end

@implementation PEAlbumListDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        [self loadData];
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark Methods
- (void)prepareForUse:(UICollectionView *)collectionView {
    [collectionView registerClass:[PEAlbumViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PEAlbumViewCell class])];
    
    _collectionView = collectionView;
}

#pragma mark PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadData];
        
        [_collectionView reloadData];
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
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[0] targetSize:CGSizeMake(100.0f, 100.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            cell.firstImageView.image = result;
        }];
    }
    if (assetsResult.count >= 2) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[1] targetSize:CGSizeMake(75.0f, 75.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            cell.secondImageView.image = result;
        }];
    }
    if (assetsResult.count >= 3) {
        [[PHImageManager defaultManager] requestImageForAsset:assetsResult[2] targetSize:CGSizeMake(50.0f, 50.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
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

- (void)loadData {
    _fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:0];
}

@end
