//
//  PAViewControllerKit.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PAViewControllerKit : NSObject

+ (CGFloat)statusBarHeight;

+ (void)rotateCollectionView:(UICollectionView *)collectionView rect:(CGRect)rect contentInset:(UIEdgeInsets)contentInset scrollIndicatorInsets:(UIEdgeInsets)scrollIndicatorInsets;

+ (void)rotateCollectionView:(UICollectionView *)collectionView rect:(CGRect)rect;

@end
