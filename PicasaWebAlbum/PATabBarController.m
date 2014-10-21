//
//  PWTabBarController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PATabBarController.h"

@interface PATabBarController () <UITabBarControllerDelegate, UINavigationBarDelegate>

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIToolbar *actionToolbar;
@property (strong, nonatomic) UINavigationBar *actionNavigationBar;

@property (nonatomic, readwrite) BOOL isTabBarHidden;
@property (nonatomic) BOOL isTabBarAnimation;
@property (nonatomic, readwrite) BOOL isToolbarHidden;
@property (nonatomic) BOOL isToolbarAnimation;
@property (nonatomic, readwrite) BOOL isActionToolbarHidden;
@property (nonatomic) BOOL isActionToolbarAnimation;
@property (nonatomic, readwrite) BOOL isActionNavigationBarHidden;
@property (nonatomic) BOOL isActionNavigationBarAnimation;

@property (nonatomic, readwrite) BOOL isPhone;
@property (nonatomic, readwrite) BOOL isLandscape;

@end

@implementation PATabBarController

- (id)initWithIndex:(NSUInteger)index viewControllers:(NSArray *)viewControllers colors:(NSArray *)colors {
    self = [self init];
    if (self) {
        if (viewControllers.count != colors.count) {
            return self;
        }
        
        self.viewControllers = viewControllers;
        self.selectedIndex = index;
        
        _colors = colors;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        
        _isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBar.tintColor = _colors[self.selectedIndex];
    
    [self resetViewHidden];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self resetViewHidden];
}

- (void)resetViewHidden {
    for(UIView *view in self.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            view.alpha = !_isTabBarHidden;
        }
    }
    _actionNavigationBar.alpha = !_isActionNavigationBarHidden;
    _toolbar.alpha = !_isToolbarHidden;
    _actionToolbar.alpha = !_isActionToolbarHidden;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    
    if (_isPhone) {
        [UIApplication sharedApplication].statusBarHidden = (_isLandscape || _isStatusBarHidden) ? YES : NO;
    }
    
    CGRect rect = self.view.bounds;
    CGFloat tHeight = self.tabBarHeight;
    CGFloat nHeight = self.navigationBarHeight;
    
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
    
    CGRect navigationbarFrame = CGRectMake(0.0f, 0.0f, rect.size.width, nHeight);
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

#pragma mark UINavigationBarDelegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma methods
- (CGFloat)tabBarHeight {
    CGFloat height = 44.0f;
    if (_isPhone) {
        if(_isLandscape) {
            height = 32.0f;
        }
    }
    else {
        height = 56.0f;
    }
    return height;
}

- (CGFloat)navigationBarHeight {
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    UINavigationController *navigationController = self.childViewControllers.firstObject;
    if ([navigationController isKindOfClass:[UINavigationController class]]) {
        return navigationController.navigationBar.bounds.size.height + statusBarHeight;
    }
    
    CGFloat height = 44.0f;
    if (_isPhone) {
        if(_isLandscape) {
            height = 32.0f;
        }
    }
    return height + statusBarHeight;
}

- (UIEdgeInsets)viewInsets {
    return UIEdgeInsetsMake(self.navigationBarHeight, 0.0f, self.tabBarHeight, 0.0f);
}

#pragma mark UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [viewController viewDidAppear:NO];
    
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    self.tabBar.tintColor = _colors[index];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    
    self.tabBar.tintColor = _colors[selectedIndex];
}

#pragma mark StatusBar
- (void)setIsStatusBarHidden:(BOOL)isStatusBarHidden animated:(BOOL)animated {
    _isStatusBarHidden = isStatusBarHidden;
    
    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:isStatusBarHidden withAnimation:UIStatusBarAnimationNone];
    }
    else {
        [[UIApplication sharedApplication] setStatusBarHidden:isStatusBarHidden withAnimation:UIStatusBarAnimationFade];
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
    CGFloat tHeight = self.tabBarHeight;
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

@end
