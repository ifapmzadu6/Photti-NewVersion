//
//  PAScrollBannerReusableView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHScrollBannerHeaderView.h"

#import "PHScrollBannerView.h"

@interface PHScrollBannerHeaderView ()

@property (strong, nonatomic) PHScrollBannerView *scrollBannerView;
@property (nonatomic) CGRect rect;

@end

@implementation PHScrollBannerHeaderView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, _rect)) {
        _rect = self.bounds;
        
        if (_scrollBannerView) {
            [_scrollBannerView removeFromSuperview];
            _scrollBannerView = nil;
        }
        
        _scrollBannerView = [PHScrollBannerView new];
        _scrollBannerView.views = _views;
        _scrollBannerView.frame = self.bounds;
        [self addSubview:_scrollBannerView];
    }
}

- (void)setViews:(NSArray *)views {
    _views = views;
    
    _scrollBannerView.views = views;
}

@end
