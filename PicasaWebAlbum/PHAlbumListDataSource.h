//
//  PHAlbumDataSource.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

@interface PHAlbumListDataSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (copy, nonatomic) void (^didSelectCollectionBlock)(PHAssetCollection *collection);

@property (nonatomic) CGSize cellSize;
@property (nonatomic) UIColor *cellBackgroundColor;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGFloat minimumLineSpacing;

- (void)prepareForUse:(UICollectionView *)collectionView;

@end
