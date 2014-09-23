//
//  PALeftCollectionView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHHorizontalScrollView.h"

@interface PHHorizontalScrollView ()

@end

@implementation PHHorizontalScrollView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    self.backgroundColor = [UIColor clearColor];
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    _collectionView.dataSource = _dataSource;
    _collectionView.delegate = _delegate;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.alwaysBounceHorizontal = YES;
    _collectionView.exclusiveTouch = YES;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.scrollsToTop = NO;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.backgroundColor = [UIColor clearColor];
    [self addSubview:_collectionView];
}

- (void)dealloc {
    [_collectionView removeFromSuperview];
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _collectionView.frame = self.bounds;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
}

#pragma mark Methods
- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource {
    _dataSource = dataSource;
    
    _collectionView.dataSource = dataSource;
    [_collectionView reloadData];
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate {
    _delegate = delegate;
    
    _collectionView.delegate = delegate;
}

@end
