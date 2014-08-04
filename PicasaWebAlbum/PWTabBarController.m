//
//  PWTabBarController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWTabBarController.h"

#import "PWColors.h"
#import "SDImageCache.h"
#import "PDInAppPurchase.h"

#import "PWNavigationController.h"
#import "PLNavigationController.h"
#import "PDNavigationController.h"

#import "GADBannerView.h"

static const CGFloat animationDuration = 0.25f;

@interface PWTabBarController () <UITabBarControllerDelegate, UINavigationBarDelegate>

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIToolbar *actionToolbar;
@property (strong, nonatomic) UINavigationBar *actionNavigationBar;

@property (nonatomic) BOOL isTabBarHidden;
@property (nonatomic) BOOL isTabBarAnimation;
@property (nonatomic) BOOL isToolbarHidden;
@property (nonatomic) BOOL isToolbarAnimation;
@property (nonatomic) BOOL isActionToolbarHidden;
@property (nonatomic) BOOL isActionToolbarAnimation;
@property (nonatomic) BOOL isActionNavigationBarHidden;
@property (nonatomic) BOOL isActionNavigationBarAnimation;

@property (strong, nonatomic) GADBannerView *bannerView;

@end

@implementation PWTabBarController

- (id)init {
    self = [super init];
    if (self) {
        PLNavigationController *localNavigationController = [[PLNavigationController alloc] init];
        PWNavigationController *webNavigationViewController = [[PWNavigationController alloc] init];
        PDNavigationController *taskNavigationController = [[PDNavigationController alloc] init];
        
        self.viewControllers = @[localNavigationController, webNavigationViewController, taskNavigationController];
        self.selectedIndex = 1;
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tabBar.barTintColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
    self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    
    _toolbar = [[UIToolbar alloc] init];
    _toolbar.exclusiveTouch = YES;
    [self.view addSubview:_toolbar];
    
    _toolbar.alpha = 0.0f;
    _isToolbarHidden = YES;
    
    _actionToolbar = [[UIToolbar alloc] init];
    _actionToolbar.barTintColor = [UIColor blackColor];
    _actionToolbar.exclusiveTouch = YES;
    [self.view addSubview:_actionToolbar];
    
    _actionToolbar.alpha = 0.0f;
    _isActionToolbarHidden = YES;
    
    _actionNavigationBar = [[UINavigationBar alloc] init];
    _actionNavigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8f alpha:1.0f]};
    _actionNavigationBar.barTintColor = [UIColor blackColor];
    _actionNavigationBar.delegate = self;
    _actionNavigationBar.exclusiveTouch = YES;
    [self.view addSubview:_actionNavigationBar];
    
    _actionNavigationBar.alpha = 0.0f;
    _isActionNavigationBarHidden = YES;
    
    [self setGoogleAdsBannerView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for(UIView *view in self.view.subviews) {
            if([view isKindOfClass:[UITabBar class]]) {
                view.alpha = !_isTabBarHidden;
            }
        }
        _actionNavigationBar.alpha = !_isActionNavigationBarHidden;
        _toolbar.alpha = !_isToolbarHidden;
        _actionToolbar.alpha = !_isActionToolbarHidden;
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for(UIView *view in self.view.subviews) {
            if([view isKindOfClass:[UITabBar class]]) {
                view.alpha = !_isTabBarHidden;
            }
        }
        _actionNavigationBar.alpha = !_isActionNavigationBarHidden;
        _toolbar.alpha = !_isToolbarHidden;
        _actionToolbar.alpha = !_isActionToolbarHidden;
    });
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    CGFloat tHeight = 44.0f;
    CGFloat nHeight = 44.0f;
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if(isLandscape) {
            tHeight = 32.0f;
            nHeight = 32.0f;
        }
    }
    else {
        tHeight = 56.0f;
    }
    
    if (!_isTabBarAnimation) {
        for(UIView *view in self.view.subviews) {
            if([view isKindOfClass:[UITabBar class]]) {
                [view setFrame:CGRectMake(view.frame.origin.x, rect.size.height - tHeight, view.frame.size.width, tHeight)];
            }
        }
    }
    
    CGRect toolbarFrame = CGRectMake(0.0f, rect.size.height - tHeight, rect.size.width, tHeight);
    if (!_isToolbarAnimation) {
        _toolbar.frame = toolbarFrame;
    }
    if (!_isActionToolbarAnimation) {
        _actionToolbar.frame = toolbarFrame;
    }
    
    CGRect navigationbarFrame = CGRectMake(0.0f, 0.0f, rect.size.width, nHeight + 20.0f);
    if (!_isActionNavigationBarAnimation) {
        _actionNavigationBar.frame = navigationbarFrame;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController respondsToSelector:@selector(updateTabBarItem)]) {
            [viewController performSelector:@selector(updateTabBarItem)];
        }
    }
#pragma clang diagnostic pop
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    CGFloat tHeight = 44.0f;
    CGFloat adHeight = 50.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if(UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            tHeight = 32.0f;
            adHeight = 32.0f;
        }
    }
    else {
        tHeight = 56.0f;
        adHeight = 90.0f;
    }
    
    if (!_isAdsHidden) {
        _bannerView.frame = CGRectMake(0.0f, CGRectGetHeight(rect) - tHeight - adHeight, CGRectGetWidth(rect), adHeight);
        
        if(UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _bannerView.adSize = kGADAdSizeSmartBannerLandscape;
        }
        else {
            _bannerView.adSize = kGADAdSizeSmartBannerPortrait;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[SDImageCache sharedImageCache] clearMemory];
}

#pragma mark UINavigationBarDelegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma methods
- (UIEdgeInsets)viewInsets {
    CGFloat tHeight = 44.0f;
    CGFloat nHeight = 44.0f;
    CGFloat adHeight = 50.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if(UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            tHeight = 32.0f;
            nHeight = 32.0f;
            adHeight = 32.0f;
        }
    }
    else {
        tHeight = 56.0f;
        adHeight = 90.0f;
    }
    
    if (_isAdsHidden) {
        adHeight = 0;
    }
    
    return UIEdgeInsetsMake(nHeight + 20.0f, 0.0f, tHeight + adHeight, 0.0f);
}

#pragma mark UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
//    [viewController viewWillAppear:NO];
    
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [viewController viewDidAppear:NO];
    
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    if (index == 0) {
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    }
    else if (index == 1) {
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    }
    else if (index == 2) {
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintUploadColor];
    }
}


#pragma mark TabBarHidden
- (BOOL)isTabBarHidden {
    return _isTabBarHidden;
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    _isTabBarHidden = hidden;
    _isTabBarAnimation = YES;
    
    void (^animation)() = ^{
        for(UIView *view in self.view.subviews) {
            if([view isKindOfClass:[UITabBar class]]) {
                view.alpha = !hidden;
            }
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:^(BOOL finished) {
            _isTabBarAnimation = NO;
            if (completion) {
                completion(finished);
            }
        }];
    }
    else {
        _isTabBarAnimation = NO;
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

#pragma mark Toolbar
- (BOOL)isToolbarHideen {
    return _isToolbarHidden;
}

- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    _isToolbarHidden = hidden;
    _isToolbarAnimation = YES;
    
    void (^animation)() = ^{
        _toolbar.alpha = hidden ? 0 : 1;
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:^(BOOL finished) {
            _isToolbarAnimation = NO;
            if (completion) {
                completion(finished);
            }
        }];
    }
    else {
        _isToolbarAnimation = NO;
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setToolbarFadeout:(BOOL)fadeout animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    _isToolbarHidden = fadeout;
    _isToolbarAnimation = YES;
    
    CGRect rect = self.view.bounds;
    CGFloat tHeight = 44.0f;
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if(isLandscape) {
            tHeight = 32.0f;
        }
    }
    else {
        tHeight = 56.0f;
    }
    if (fadeout) {
        _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight, rect.size.width, tHeight);
    }
    else {
        _toolbar.frame = CGRectMake(0.0f, rect.size.height, rect.size.width, tHeight);
    }
    
    void (^animation)() = ^{
        if (fadeout) {
            _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight + tHeight, rect.size.width, tHeight);
        }
        else {
            _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight, rect.size.width, tHeight);
        }
    };
    
    _toolbar.alpha = 1.0f;
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:^(BOOL finished) {
            _isToolbarAnimation = NO;
            
            _toolbar.alpha = !fadeout;
            
            if (completion) {
                completion(finished);
            }
        }];
    }
    else {
        _isToolbarAnimation = NO;
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated {
    [_toolbar setItems:toolbarItems animated:animated];
    for (UIView *view in _toolbar.subviews) {
        view.exclusiveTouch = YES;
    }
}

- (void)setToolbarTintColor:(UIColor *)tintColor {
    _toolbar.tintColor = tintColor;
}


#pragma mark Actiontoolbar
- (BOOL)isActionToolbarHidden {
    return _isActionToolbarHidden;
}

- (void)setActionToolbarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    _isActionToolbarHidden = hidden;
    _isActionToolbarAnimation = YES;
    
    void (^animation)() = ^{
        _actionToolbar.alpha = hidden ? 0 : 1;
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:^(BOOL finished) {
            _isActionToolbarAnimation = NO;
            
            if (completion) {
                completion(finished);
            }
        }];
    }
    else {
        _isActionToolbarAnimation = NO;
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setActionToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated {
    [_actionToolbar setItems:toolbarItems animated:animated];
    for (UIView *view in _actionToolbar.subviews) {
        view.exclusiveTouch = YES;
    }
}

- (void)setActionToolbarTintColor:(UIColor *)tintColor {
    _actionToolbar.tintColor = tintColor;
}

- (void)setToolbarBarTintColor:(UIColor *)color animated:(BOOL)animated {
    void (^block)() = ^{
        [_toolbar setBarTintColor:color];
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:block];
    }
    else {
        block();
    }
}


#pragma mark ActionNavigationBar
- (void)setActionNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    _isActionNavigationBarHidden = hidden;
    _isActionNavigationBarAnimation = YES;
    
    void (^animation)() = ^{
        _actionNavigationBar.alpha = hidden ? 0 : 1;
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:^(BOOL finished) {
            _isActionNavigationBarAnimation = NO;
            
            if (completion) {
                completion(finished);
            }
        }];
    }
    else {
        _isActionNavigationBarAnimation = NO;
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setActionNavigationItem:(UINavigationItem *)item animated:(BOOL)animated {
    [_actionNavigationBar setItems:@[item] animated:animated];
    for (UIView *view in _actionNavigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
}

- (void)setActionNavigationTintColor:(UIColor *)tintColor {
    _actionNavigationBar.tintColor = tintColor;
}

#pragma mark UserInteractionEnabled
- (void)setUserInteractionEnabled:(BOOL)enabled {
    [self navigationBarUserInteractionEnabled:enabled];
    _toolbar.userInteractionEnabled = enabled;
    _actionToolbar.userInteractionEnabled = enabled;
    _actionNavigationBar.userInteractionEnabled = enabled;
}

- (void)navigationBarUserInteractionEnabled:(BOOL)enabled {
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)viewController;
            navigationController.navigationBar.userInteractionEnabled = enabled;
        }
    }
}

#pragma mark GoogleAds
- (void)setGoogleAdsBannerView {
    if(UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerLandscape];
    }
    else {
        _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
    }
    _bannerView.adUnitID = @"ca-app-pub-9347360948699796/7365185266";
    _bannerView.rootViewController = self;
    [self.view insertSubview:_bannerView belowSubview:self.tabBar];
    
    [_bannerView loadRequest:[GADRequest request]];
}

- (void)setAdsHidden:(BOOL)hidden animated:(BOOL)animated {
    if ([PDInAppPurchase isPurchasedWithKey:kPDRemoveAdsPuroductID]) {
        _isAdsHidden = YES;
        
        _bannerView.alpha = 0;
        
        return;
    }
    
    _isAdsHidden = hidden;
    
    void (^animation)() = ^{
        _bannerView.alpha = hidden ? 0 : 1;
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation];
    }
    else {
        animation();
    }
}

@end
