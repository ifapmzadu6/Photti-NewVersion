//
//  PLParallelNavigationTitleView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLParallelNavigationTitleView.h"

#import "PAColors.h"

@interface PLParallelNavigationTitleView ()

@property (strong, nonatomic) UIView *clipBackgroundView;
@property (strong, nonatomic) UILabel *beforeTitleLabel;
@property (strong, nonatomic) UILabel *currentTitleLabel;
@property (strong, nonatomic) UILabel *afterTitleLabel;
@property (strong, nonatomic) UIPageControl *pageControll;

@end

@implementation PLParallelNavigationTitleView

- (id)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _isDisableLayoutSubViews = NO;
    
    _clipBackgroundView = [UIView new];
    _clipBackgroundView.clipsToBounds = YES;
    [self addSubview:_clipBackgroundView];
    
    _beforeTitleLabel = [UILabel new];
    _beforeTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    _beforeTitleLabel.textColor = [PAColors getColor:PWColorsTypeTextColor];
    _beforeTitleLabel.textAlignment = NSTextAlignmentCenter;
    [_clipBackgroundView addSubview:_beforeTitleLabel];
    
    _currentTitleLabel = [UILabel new];
    _currentTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    _currentTitleLabel.textColor = [PAColors getColor:PWColorsTypeTextColor];
    _currentTitleLabel.textAlignment = NSTextAlignmentCenter;
    [_clipBackgroundView addSubview:_currentTitleLabel];
    
    _afterTitleLabel = [UILabel new];
    _afterTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    _afterTitleLabel.textColor = [PAColors getColor:PWColorsTypeTextColor];
    _afterTitleLabel.textAlignment = NSTextAlignmentCenter;
    [_clipBackgroundView addSubview:_afterTitleLabel];
    
    _titleTextColor = [PAColors getColor:PWColorsTypeTextColor];
    
    _pageControll = [UIPageControl new];
    _pageControll.currentPageIndicatorTintColor = [PAColors getColor:PWColorsTypeTintLocalColor];
    _pageControll.pageIndicatorTintColor = [[PAColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.2f];
    _pageControll.userInteractionEnabled = NO;
    [_clipBackgroundView addSubview:_pageControll];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_isDisableLayoutSubViews) {
        return;
    }
    
    CGRect superViewRect = self.superview.bounds;
    
    CGFloat halfwidth = CGRectGetMaxX(self.frame) - CGRectGetWidth(superViewRect) / 2.0f;
    
    BOOL isLandScape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    CGFloat tHeight = 44.0f;
    if (isLandScape) {
        tHeight = 32.0f;
    }
    
    _clipBackgroundView.frame = CGRectMake(CGRectGetWidth(superViewRect) / 2.0f - halfwidth - self.frame.origin.x, CGRectGetMaxY(superViewRect) - tHeight - self.frame.origin.y, halfwidth * 2.0f, tHeight);
    
    CGRect rect = _clipBackgroundView.bounds;
    CGSize size = rect.size;
    
    CGFloat labelY = 10.0f;
    CGFloat pageControlY = size.height - 18.0f;
    if (isLandScape) {
        labelY = 4.0f;
        pageControlY = size.height - 16.0f;
    }
    
    _beforeTitleLabel.frame = CGRectMake(-size.width * 0.5f, labelY, size.width, 17.0f);
    _currentTitleLabel.frame = CGRectMake(0.0f, labelY, size.width, 17.0f);
    _afterTitleLabel.frame = CGRectMake(size.width * 0.5f, labelY, size.width, 17.0f);
    _pageControll.frame = CGRectMake(0.0f, pageControlY, size.width, 18.0f);
    
    if (isLandScape) {
        _beforeTitleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        _currentTitleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        _afterTitleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    }
    else {
        _beforeTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        _currentTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        _afterTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    }
}

- (void)setScrollRate:(CGFloat)rate {
    CGRect rect = self.bounds;
    CGSize size = rect.size;
    CGFloat moveX = size.width * (fabsf(rate) * rate) * 0.5f;
    
    _currentTitleLabel.frame = (CGRect){.origin = CGPointMake(-moveX, _currentTitleLabel.frame.origin.y), _currentTitleLabel.frame.size};
    if (rate >= 0) {
        _afterTitleLabel.frame = (CGRect){.origin = CGPointMake(size.width * 0.5f - moveX, _afterTitleLabel.frame.origin.y), _afterTitleLabel.frame.size};
    }
    if (rate <= 0) {
        _beforeTitleLabel.frame = (CGRect){.origin = CGPointMake(-size.width * 0.5f - moveX, _beforeTitleLabel.frame.origin.y), _beforeTitleLabel.frame.size};
    }
    
    if (rate >= -0.5f && rate <= 0.5f) {
        _beforeTitleLabel.alpha = 0.0f;
        _currentTitleLabel.alpha = 1.0f;
        _afterTitleLabel.alpha = 0.0f;
    }
    else if (rate > 0.5f) {
        _beforeTitleLabel.alpha = 0.0f;
        CGFloat alpha = (rate - 0.5f) * 2.0f;
        _currentTitleLabel.alpha = 1.0f - alpha;
        _afterTitleLabel.alpha = alpha;
    }
    else if (rate < -0.5f) {
        CGFloat alpha = (-rate - 0.5f) * 2.0f;
        _beforeTitleLabel.alpha = alpha;
        _currentTitleLabel.alpha = 1.0f - alpha;
        _afterTitleLabel.alpha = 0.0f;
    }
}

- (void)setNumberOfPages:(NSUInteger)numberOfPages {
    _pageControll.numberOfPages = numberOfPages;
}

- (void)setCurrentIndex:(NSUInteger)index {
    _pageControll.currentPage = index;
}

- (void)setCurrentTitle:(NSString *)title {
    _currentTitleLabel.text = title;
    
    if (_titleAfterCurrentTitle) {
        _afterTitleLabel.text = _titleAfterCurrentTitle(_currentTitleLabel.text);
    }
    if (_titleBeforeCurrentTitle) {
        _beforeTitleLabel.text = _titleBeforeCurrentTitle(_currentTitleLabel.text);
    }
}

- (void)setTitleTextColor:(UIColor *)titleTextColor {
    _titleTextColor = titleTextColor;
    
    _beforeTitleLabel.textColor = titleTextColor;
    _currentTitleLabel.textColor = titleTextColor;
    _afterTitleLabel.textColor = titleTextColor;
}

@end
