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

@interface PEMomentListDataSource () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PHFetchResult *fetchResult;

@end

@implementation PEMomentListDataSource

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
    [collectionView registerClass:[PEMomentViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PEMomentViewCell class])];
    
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
    PEMomentViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PEMomentViewCell class]) forIndexPath:indexPath];
    
    PHAssetCollection *collection = _fetchResult[indexPath.row];
    PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    cell.numberOfImageView = assetsResult.count;
    CGSize thumbnailTargetSize = CGSizeMake(80.0f, 80.0f);
    if (cell.numberOfImageView == 1) {
        thumbnailTargetSize = CGSizeMake(160.0f, 160.0f);
    }
    for (int i=0; i<cell.numberOfImageView; i++) {
        UIImageView *imageView = cell.imageViews[i];
        imageView.image = nil;
        PHAsset *asset = assetsResult[i];
        if (asset.mediaType == PHAssetMediaTypeImage) {
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:thumbnailTargetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
                imageView.image = result;
            }];
        }
    }
    
    NSString *title = collection.localizedTitle;
    if (!title) {
        NSString *startDate = [[PADateFormatter mmmddFormatter] stringFromDate:collection.startDate];
        NSString *endDate = [[PADateFormatter mmmddFormatter] stringFromDate:collection.endDate];
        if ([startDate isEqualToString:endDate]) {
            title = startDate;
        }
        else {
            title = [NSString stringWithFormat:@"%@ - %@", startDate, endDate];
        }
    }
    cell.titleLabel.text = title;
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
    PHAssetCollection *assetCollection = _fetchResult[indexPath.row];
    if (_didSelectCollectionBlock) {
        _didSelectCollectionBlock(assetCollection);
    }
}

@end
