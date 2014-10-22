//
//  PACollectionViewDaisyChain.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PACollectionViewDaisyChain : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) id<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> dataSource;
@property (weak, nonatomic) id<UICollectionViewDelegate, UIScrollViewDelegate> delegate;

@end
