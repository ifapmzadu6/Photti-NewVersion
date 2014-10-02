//
//  PAScrollBannerReusableView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEScrollBannerHeaderView.h"

#import "PEScrollBannerView.h"

@interface PEScrollBannerHeaderView ()

@property (strong, nonatomic) PEScrollBannerView *scrollBannerView;
@property (nonatomic) CGSize size;

@end

@implementation PEScrollBannerHeaderView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = CGRectMake(_contentInsets.left, _contentInsets.top, CGRectGetWidth(self.bounds)-_contentInsets.left-_contentInsets.right, CGRectGetHeight(self.bounds)-_contentInsets.top-_contentInsets.bottom);
    
    if (!CGSizeEqualToSize(rect.size, _size)) {
        _size = rect.size;
        
        if (_scrollBannerView) {
            [_scrollBannerView removeFromSuperview];
            _scrollBannerView = nil;
        }
        _scrollBannerView = [PEScrollBannerView new];
        _scrollBannerView.views = _views;
        [self addSubview:_scrollBannerView];
    }
    
    _scrollBannerView.frame = rect;
}

- (void)setShouldAnimate:(BOOL)shouldAnimate {
    _shouldAnimate = shouldAnimate;
    
    _scrollBannerView.shouldAnimate = shouldAnimate;
}

- (void)setViews:(NSArray *)views {
    _views = views;
    
    _scrollBannerView.views = views;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets {
    if (!UIEdgeInsetsEqualToEdgeInsets(_contentInsets, contentInsets)) {
        [self setNeedsLayout];
    }
    
    _contentInsets = contentInsets;
}

@end
