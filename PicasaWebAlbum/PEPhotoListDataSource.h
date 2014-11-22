//
//  PHAllPhotoListDataSource.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

@interface PEPhotoListDataSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (copy, nonatomic) void (^didSelectAssetBlock)(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode);
@property (copy, nonatomic) void (^didDeselectAssetBlock)(PHAsset *asset, NSUInteger index, BOOL isSelectMode);
@property (copy, nonatomic) void (^didChangeItemCountBlock)(NSUInteger count);
@property (copy, nonatomic) void (^didChangeSelectedItemCountBlock)(NSUInteger count);

@property (strong, nonatomic, readonly) PHAssetCollection *assetCollection;
@property (strong, nonatomic, readonly) PHFetchResult *fetchResult;
@property (nonatomic, readonly) BOOL ascending;

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic) CGSize cellSize;
@property (nonatomic) CGSize landscapeCellSize;
@property (nonatomic) UIColor *cellBackgroundColor;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGFloat minimumLineSpacing;

- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult;
- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult assetCollection:(PHAssetCollection *)assetCollection;
- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult assetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending;

@property (nonatomic) BOOL isSelectMode;
@property (nonatomic, readonly) NSArray *selectedAssets;

- (void)selectAssets:(NSArray *)assets animated:(BOOL)animated;
- (void)selectAssetIdentifiers:(NSArray *)assetIdentifiers animated:(BOOL)animated;

@end
