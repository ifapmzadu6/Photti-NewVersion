//
//  PAViewControllerKit.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAViewControllerKit.h"

static CGFloat kPAViewControllerKitMaxStatusBarHeight = 20.0f;

@implementation PAViewControllerKit

+ (CGFloat)statusBarHeight {
    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    return MIN(kPAViewControllerKitMaxStatusBarHeight, MIN(statusBarSize.width, statusBarSize.height));
}

+ (void)rotateCollectionView:(UICollectionView *)collectionView rect:(CGRect)rect {
    [self rotateCollectionView:collectionView rect:rect contentInset:UIEdgeInsetsZero scrollIndicatorInsets:UIEdgeInsetsZero];
}

+ (void)rotateCollectionView:(UICollectionView *)collectionView rect:(CGRect)rect contentInset:(UIEdgeInsets)contentInset scrollIndicatorInsets:(UIEdgeInsets)scrollIndicatorInsets {
    NSArray *indexPaths = [collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {return [obj1 compare:obj2];}];
    NSIndexPath *indexPath = nil;
    if (indexPaths.count > 0) {
        NSIndexPath *firstIndexPath = indexPaths.firstObject;
        if (!(firstIndexPath.item == 0 && firstIndexPath.section == 0)) {
            indexPath = indexPaths[indexPaths.count / 2];
        }
    }
    
    collectionView.contentInset = contentInset;
    collectionView.scrollIndicatorInsets = scrollIndicatorInsets;
    collectionView.frame = rect;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
}

@end
