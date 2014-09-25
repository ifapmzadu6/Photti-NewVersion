//
//  PHMomentDataSource.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHMomentListDataSource.h"

@import Photos;

#import "PHMomentViewCell.h"

@interface PHMomentListDataSource () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PHFetchResult *fetchResult;

@end

@implementation PHMomentListDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        _fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeMoment subtype:PHAssetCollectionSubtypeAny options:0];
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark Methods
- (void)prepareForUse:(UICollectionView *)collectionView {
    [collectionView registerClass:[PHMomentViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PHMomentViewCell class])];
    
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
    PHMomentViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PHMomentViewCell class]) forIndexPath:indexPath];
    
    PHAssetCollection *collection = _fetchResult[indexPath.row];
    PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    cell.numberOfImageView = assetsResult.count;
    for (int i=0; i<cell.numberOfImageView; i++) {
        UIImageView *imageView = cell.imageViews[i];
        imageView.image = nil;
        PHAsset *asset = assetsResult[i];
        if (asset.mediaType == PHAssetMediaTypeImage) {
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(100.0f, 100.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
                imageView.image = result;
            }];
        }
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

@end
