//
//  PACollectionViewDaisyChain.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PACollectionViewDaisyChain.h"

@implementation PACollectionViewDaisyChain

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([_dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        return [_dataSource numberOfSectionsInCollectionView:collectionView];
    }
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
        return [_dataSource collectionView:collectionView numberOfItemsInSection:section];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_dataSource respondsToSelector:@selector(collectionView:cellForItemAtIndexPath:)]) {
        return [_dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
    return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([_dataSource respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)]) {
        return [_dataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
    return nil;
}

#pragma mark UICollectionViewDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:shouldHighlightItemAtIndexPath:)]) {
        return [_delegate collectionView:collectionView shouldHighlightItemAtIndexPath:indexPath];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:didHighlightItemAtIndexPath:)]) {
        [_delegate collectionView:collectionView didHighlightItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:didUnhighlightItemAtIndexPath:)]) {
        [_delegate collectionView:collectionView didUnhighlightItemAtIndexPath:indexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)]) {
        return [_delegate collectionView:collectionView shouldSelectItemAtIndexPath:indexPath];
    }
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)]) {
        return [_delegate collectionView:collectionView shouldDeselectItemAtIndexPath:indexPath];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [_delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)]) {
        [_delegate collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        [_delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)]) {
        [_delegate collectionView:collectionView willDisplaySupplementaryView:view forElementKind:elementKind atIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)]) {
        [_delegate collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)]) {
        [_delegate collectionView:collectionView didEndDisplayingSupplementaryView:view forElementOfKind:elementKind atIndexPath:indexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collectionView:shouldShowMenuForItemAtIndexPath:)]) {
        return [_delegate collectionView:collectionView shouldShowMenuForItemAtIndexPath:indexPath];
    }
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if ([_delegate respondsToSelector:@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)]) {
        return [_delegate collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if ([_delegate respondsToSelector:@selector(collectionView:performAction:forItemAtIndexPath:withSender:)]) {
        [_delegate collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
}

- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout {
    if ([_delegate respondsToSelector:@selector(collectionView:transitionLayoutForOldLayout:newLayout:)]) {
        return [_delegate collectionView:collectionView transitionLayoutForOldLayout:fromLayout newLayout:toLayout];
    }
    return nil;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_dataSource respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        return [_dataSource collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
    return ((UICollectionViewFlowLayout *)collectionViewLayout).itemSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        return [_dataSource collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
    }
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        return [_dataSource collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
    }
    return ((UICollectionViewFlowLayout *)collectionViewLayout).minimumLineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        return [_dataSource collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
    }
    return ((UICollectionViewFlowLayout *)collectionViewLayout).minimumInteritemSpacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        return [_dataSource collectionView:collectionView layout:collectionViewLayout referenceSizeForHeaderInSection:section];
    }
    return ((UICollectionViewFlowLayout *)collectionViewLayout).headerReferenceSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]) {
        return [_dataSource collectionView:collectionView layout:collectionViewLayout referenceSizeForFooterInSection:section];
    }
    return ((UICollectionViewFlowLayout *)collectionViewLayout).footerReferenceSize;
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [_delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [_delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [_delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        [_delegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [_delegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [_delegate scrollViewDidScrollToTop:scrollView];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        [_delegate scrollViewDidZoom:scrollView];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [_delegate scrollViewShouldScrollToTop:scrollView];
    }
    return YES;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [_delegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [_delegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if ([_delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        [_delegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([_delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [_delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

@end
