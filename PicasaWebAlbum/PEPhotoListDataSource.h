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

@property (copy, nonatomic) void (^didSelectAssetBlock)(PHAsset *asset, NSUInteger index);

@property (strong, nonatomic, readonly) PHAssetCollection *assetCollection;
@property (strong, nonatomic, readonly) PHFetchResult *fetchResult;

@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic) CGSize cellSize;
@property (nonatomic) CGSize landscapeCellSize;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGFloat minimumLineSpacing;

- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult;
- (instancetype)initWithFetchResultOfPhoto:(PHFetchResult *)fetchResult assetCollection:(PHAssetCollection *)assetCollection;

- (void)prepareForUse:(UICollectionView *)collectionView;

@end
