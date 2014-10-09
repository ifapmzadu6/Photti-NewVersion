//
//  PAHorizontalScrollView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PAHorizontalScrollView : UIView

@property (strong, nonatomic, readonly) UICollectionView *collectionView;

@property (weak, nonatomic) id<UICollectionViewDataSource> dataSource;
@property (weak, nonatomic) id<UICollectionViewDelegate> delegate;

@end
