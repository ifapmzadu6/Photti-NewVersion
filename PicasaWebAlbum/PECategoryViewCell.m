//
//  PALeftCollectionViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PECategoryViewCell.h"

#import "PAColors.h"
#import "PEHorizontalScrollView.h"
#import "PEAlbumViewCell.h"
#import "PEMomentViewCell.h"

@interface PECategoryViewCell ()

@end

@implementation PECategoryViewCell

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

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:16.0f];
    _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _moreButton = [UIButton new];
    [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _moreButton.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [_moreButton setTitle:@"全て見る>" forState:UIControlStateNormal];
    [_moreButton setTitleColor:[PAColors getColor:PAColorsTypeTextLightSubColor] forState:UIControlStateNormal];
    [self.contentView addSubview:_moreButton];
    
    _horizontalScrollView = [PEHorizontalScrollView new];
    [_horizontalScrollView.collectionView registerClass:[PEAlbumViewCell class] forCellWithReuseIdentifier:@"PHAlbumViewCell"];
    [_horizontalScrollView.collectionView registerClass:[PEMomentViewCell class] forCellWithReuseIdentifier:@"PHCollectionViewCell"];
    _horizontalScrollView.collectionView.contentInset = UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 15.0f);
    [self.contentView addSubview:_horizontalScrollView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _titleLabel.frame = CGRectMake(15.0f, 20.0f, 200.0f, 20.0f);
    [_moreButton sizeToFit];
    _moreButton.frame = CGRectMake(CGRectGetWidth(rect) - CGRectGetWidth(_moreButton.bounds) - 15.0f, 20.0f, CGRectGetWidth(_moreButton.bounds), 20.0f);
    _horizontalScrollView.frame = CGRectMake(0.0f, 38.0f, CGRectGetWidth(rect), CGRectGetHeight(rect) - 38.0f);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    UIEdgeInsets contentInsets = _horizontalScrollView.collectionView.contentInset;
    _horizontalScrollView.collectionView.contentOffset = CGPointMake(-contentInsets.left, 0.0f);
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource {
    _dataSource = dataSource;
    
    _horizontalScrollView.dataSource = dataSource;
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate {
    _delegate = delegate;
    
    _horizontalScrollView.delegate = delegate;
}

- (void)moreButtonAction {
    if (_moreButtonActionBlock) {
        _moreButtonActionBlock();
    }
}

@end
