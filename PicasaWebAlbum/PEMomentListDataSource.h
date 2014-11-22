//
//  PHMomentDataSource.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

@interface PEMomentListDataSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (copy, nonatomic) void (^didSelectCollectionBlock)(PHAssetCollection *collection);
@property (copy, nonatomic) void (^didChangeItemCountBlock)(NSUInteger count);
@property (copy, nonatomic) void (^didChangeSelectedItemCountBlock)(NSUInteger count);

@property (strong, nonatomic) PHFetchResult *fetchResult;

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic) CGSize cellSize;
@property (nonatomic) UIColor *cellBackgroundColor;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGFloat minimumLineSpacing;

@property (nonatomic) BOOL isSelectMode;
@property (nonatomic, readonly) NSArray *selectedCollections;

@end
