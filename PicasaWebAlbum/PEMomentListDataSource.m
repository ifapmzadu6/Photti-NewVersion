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
#import "NSIndexSet+methods.h"

@interface PEMomentListDataSource () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PHFetchResult *fetchResult;
@property (strong, nonatomic) NSArray *assetCollectionFetchResults;

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
- (void)prepareForUse:(UICollectionView *)collectionView {
    [collectionView registerClass:[PEMomentViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PEMomentViewCell class])];
    
    _collectionView = collectionView;
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
    PEMomentViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PEMomentViewCell class]) forIndexPath:indexPath];
    __weak typeof(cell) wcell = cell;
    NSUInteger index = indexPath.row;
    cell.tag = index;
    for (UIImageView *imageView in cell.imageViews) {
        imageView.image = nil;
    }
    
    PHFetchResult *assetsResult = _assetCollectionFetchResults[indexPath.row];
    cell.numberOfImageView = assetsResult.count;
    for (int i=0; i<cell.numberOfImageView; i++) {
        PHAsset *asset = assetsResult[i];
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:_cellSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            typeof(wcell) scell = wcell;
            if (!scell) return;
            if (scell.tag == index) {
                UIImageView *imageView = scell.imageViews[i];
                imageView.image = result;
            }
        }];
    }
    
    PHAssetCollection *collection = _fetchResult[indexPath.row];
    cell.titleLabel.text = [PEMomentListDataSource titleForMoment:collection];
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
