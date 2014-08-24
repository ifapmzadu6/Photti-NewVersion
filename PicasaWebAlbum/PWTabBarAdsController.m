//
//  PWTabBarAdsController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWTabBarAdsController.h"

#import "GADBannerView.h"

@interface PWTabBarAdsController ()

@property (strong, nonatomic) GADBannerView *bannerView;

@end

@implementation PWTabBarAdsController

- (id)initWithIndex:(NSUInteger)index viewControllers:(NSArray *)viewControllers colors:(NSArray *)colors isRemoveAdsAddonPurchased:(BOOL)isRemoveAdsAddonPurchased {
    self = [super initWithIndex:index viewControllers:viewControllers colors:colors];
    if (self) {
        _isRemoveAdsAddonPurchased = isRemoveAdsAddonPurchased;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_isRemoveAdsAddonPurchased) {
        _bannerView = [GADBannerView new];
        _bannerView.adUnitID = kPWTabBarAdsControllerAdUnitID;
        _bannerView.rootViewController = self;
        [self.view insertSubview:_bannerView belowSubview:self.tabBar];
        
        [self disableBannerBounce:_bannerView];
        
        [_bannerView loadRequest:[GADRequest request]];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    CGFloat adViewHeight = self.adViewHeight;
    _bannerView.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - self.tabBarHeight - adViewHeight, CGRectGetWidth(rect), adViewHeight);
}

- (CGFloat)adViewHeight {
    if (_isRemoveAdsAddonPurchased) {
        return 0.0f;
    }
    
    CGFloat height = 50.0f;
    if (self.isPhone) {
        if(self.isLandscape) {
            height = 32.0f;
        }
    }
    else {
        height = 90.0f;
    }
    return height;
}

- (UIEdgeInsets)viewInsets {
    return UIEdgeInsetsMake(self.navigationBarHeight, 0.0f, self.tabBarHeight + self.adViewHeight, 0.0f);
}

#pragma mark methods

- (void)setIsRemoveAdsAddonPurchased:(BOOL)isRemoveAdsAddonPurchased {
    _isRemoveAdsAddonPurchased = isRemoveAdsAddonPurchased;
    
    _isAdsHidden = isRemoveAdsAddonPurchased;
    
    void (^block)() = ^{
        _bannerView.alpha = isRemoveAdsAddonPurchased ? 0.0f : 1.0f;
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)setAdsHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_isRemoveAdsAddonPurchased) {
        _isAdsHidden = YES;
        _bannerView.alpha = 0.0f;
        return;
    }
    
    if (_isAdsHidden == hidden) {
        return;
    }
    _isAdsHidden = hidden;
    
    void (^animation)() = ^{
        _bannerView.alpha = hidden ? 0.0f : 1.0f;
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation];
    }
    else {
        animation();
    }
}

- (void)disableBannerBounce:(GADBannerView *)bannerView{
    for (UIWebView *webView in bannerView.subviews) {
        if ([webView isKindOfClass:[UIWebView class]]) {
            
            webView.scrollView.bounces = NO;
        }
    }
}

@end
