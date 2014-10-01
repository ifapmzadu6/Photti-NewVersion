//
//  PHScrollBannerView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEScrollBannerView.h"

static NSUInteger KPHScrollBannerViewMaxNumberOfRows = 20000;

@interface PEScrollBannerView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIView *buttomLineView;
@property (nonatomic) NSUInteger ticktock;

@end

@implementation PEScrollBannerView

- (instancetype)init {
    self = [super init];
    if (self) {
        UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
        _collectionView.pagingEnabled = YES;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.exclusiveTouch = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.scrollsToTop = NO;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_collectionView];
        
        _buttomLineView = [UIView new];
        _buttomLineView.backgroundColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
        [self addSubview:_buttomLineView];
        
        _shouldAnimate = YES;
        _animateInterval = 7.0f;
        _index = KPHScrollBannerViewMaxNumberOfRows/2;
        
        [self animateToNextCell];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _collectionView.frame = self.bounds;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_index inSection:0];
    [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    
    _buttomLineView.frame = CGRectMake(0.0f, CGRectGetMaxY(self.bounds) - 0.5f, CGRectGetWidth(self.bounds), 0.5f);
}

- (void)dealloc {
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

#pragma mark Methods
- (void)setViews:(NSArray *)views {
    for (UIView *view in views) {
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    _views = views;
    
    [_collectionView reloadData];
}

- (void)setShouldAnimate:(BOOL)shouldAnimate {
    _shouldAnimate = shouldAnimate;
    
    _ticktock = 0;
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return KPHScrollBannerViewMaxNumberOfRows;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    for (UIView *view in cell.contentView.subviews) {
        if ([_views containsObject:view]) {
            [view removeFromSuperview];
        }
    }
    
    NSUInteger index = indexPath.row % _views.count;
    UIView *view = _views[index];
    view.frame = self.bounds;
    [cell.contentView addSubview:view];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    _index = indexPath.item;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _collectionView.bounds.size;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _shouldAnimate = NO;
    _ticktock = 0;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    _shouldAnimate = YES;
    _ticktock = 0;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _shouldAnimate = YES;
    _ticktock = 0;
}

#pragma mark Animation
- (void)animateToNextCell {
    if (_ticktock < _animateInterval) {
        _ticktock++;
    }
    else {
        _ticktock = 0;
        
        if (_shouldAnimate) {
            NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
                return [obj1 compare:obj2];
            }];
            if (indexPaths.count > 0) {
                NSIndexPath *indexPath = indexPaths[indexPaths.count / 2];
                
                NSIndexPath *nextIndexPath = nil;
                if (indexPath.row == KPHScrollBannerViewMaxNumberOfRows) {
                    nextIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
                }
                else {
                    nextIndexPath = [NSIndexPath indexPathForItem:indexPath.row + 1 inSection:0];
                }
                
                [_collectionView scrollToItemAtIndexPath:nextIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            }
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self animateToNextCell];
    });
}

@end
