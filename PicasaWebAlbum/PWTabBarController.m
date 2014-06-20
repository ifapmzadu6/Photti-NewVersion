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

#import "PWNavigationController.h"
#import "PWSearchNavigationController.h"
#import "PLPageViewController.h"
#import "PWAlbumListViewController.h"
#import "PDTaskManagerViewController.h"

static const CGFloat animationDuration = 0.25f;

@interface PWTabBarController ()

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIToolbar *actionToolbar;
@property (strong, nonatomic) UINavigationBar *actionNavigationBar;

@property (nonatomic) BOOL isTabBarHidden;
@property (nonatomic) BOOL isToolbarHidden;
@property (nonatomic) BOOL isActionToolbarHidden;
@property (nonatomic) BOOL isActionNavigationBarHidden;

@end

@implementation PWTabBarController

- (id)init {
    self = [super init];
    if (self) {
        PLPageViewController *localPageViewController = [[PLPageViewController alloc] init];
        PWSearchNavigationController *localNavigationController = [[PWSearchNavigationController alloc] initWithRootViewController:localPageViewController];
        
        PWAlbumListViewController *albumListViweController = [[PWAlbumListViewController alloc] init];
        PWSearchNavigationController *albumNavigationController = [[PWSearchNavigationController alloc] initWithRootViewController:albumListViweController];
        
        PDTaskManagerViewController *taskManagerViewController = [[PDTaskManagerViewController alloc] init];
        PWNavigationController *autoUploadNavigationController = [[PWNavigationController alloc] initWithRootViewController:taskManagerViewController];
        
        self.viewControllers = @[localNavigationController, albumNavigationController, autoUploadNavigationController];
        self.selectedIndex = 1;
        self.delegate = self;
        
        _toolbar = [[UIToolbar alloc] init];
        [self.view addSubview:_toolbar];
        
        _toolbar.alpha = 0.0f;
        _isToolbarHidden = YES;
        
        _actionToolbar = [[UIToolbar alloc] init];
        _actionToolbar.barTintColor = [UIColor blackColor];
        [self.view addSubview:_actionToolbar];
        
        _actionToolbar.alpha = 0.0f;
        _isActionToolbarHidden = YES;
        
        _actionNavigationBar = [[UINavigationBar alloc] init];
        _actionNavigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8f alpha:1.0f]};
        _actionNavigationBar.barTintColor = [UIColor blackColor];
        _actionNavigationBar.delegate = self;
        [self.view addSubview:_actionNavigationBar];
        
        _actionNavigationBar.alpha = 0.0f;
        _isActionNavigationBarHidden = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tabBar.barTintColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
    self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for(UIView *view in self.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            view.alpha = !_isTabBarHidden;
        }
    }
    _actionNavigationBar.alpha = !_isActionNavigationBarHidden;
    _toolbar.alpha = !_isToolbarHidden;
    _actionToolbar.alpha = !_isActionToolbarHidden;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
    
    CGRect rect = self.view.bounds;
    CGFloat tHeight = 44.0f;
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if(isLandscape) {
        tHeight = 32.0f;
    }
    for(UIView *view in self.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            [view setFrame:CGRectMake(view.frame.origin.x, rect.size.height - tHeight, view.frame.size.width, tHeight)];
        }
    }
    
    CGRect toolbarFrame = CGRectMake(0.0f, rect.size.height - tHeight, rect.size.width, tHeight);
    _toolbar.frame = toolbarFrame;
    _actionToolbar.frame = toolbarFrame;
    
    CGRect navigationbarFrame = CGRectMake(0.0f, 0.0f, rect.size.width, tHeight + 20.0f);
    _actionNavigationBar.frame = navigationbarFrame;
    
    if (isLandscape) {
        for (UIViewController *viewController in self.viewControllers) {
            viewController.tabBarItem.imageInsets = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
        }
    }
    else {
        for (UIViewController *viewController in self.viewControllers) {
            viewController.tabBarItem.imageInsets = UIEdgeInsetsZero;
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
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if(isLandscape) {
        tHeight = 32.0f;
    }
    
    return UIEdgeInsetsMake(tHeight + 20.0f, 0.0f, tHeight, 0.0f);
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
    
    void (^animation)() = ^{
        for(UIView *view in self.view.subviews) {
            if([view isKindOfClass:[UITabBar class]]) {
                if (hidden) {
                    view.alpha = 0.0f;
                }
                else {
                    view.alpha = 1.0f;
                }
            }
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:completion];
    }
    else {
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
    
    void (^animation)() = ^{
        if (hidden) {
            _toolbar.alpha = 0.0f;
        }
        else {
            _toolbar.alpha = 1.0f;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:completion];
    }
    else {
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setToolbarFadeout:(BOOL)fadeout animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    _isToolbarHidden = fadeout;
    
    CGRect rect = self.view.bounds;
    CGFloat tHeight = 44.0f;
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if(isLandscape) {
        tHeight = 32.0f;
    }
    if (fadeout) {
        _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight, rect.size.width, tHeight);
    }
    else {
        _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight + tHeight, rect.size.width, tHeight);
    }
    
    void (^animation)() = ^{
        if (fadeout) {
            _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight + tHeight, rect.size.width, tHeight);
        }
        else {
            _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight, rect.size.width, tHeight);
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:completion];
    }
    else {
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated {
    [_toolbar setItems:toolbarItems animated:animated];
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
    
    void (^animation)() = ^{
        if (hidden) {
            _actionToolbar.alpha = 0.0f;
        }
        else {
            _actionToolbar.alpha = 1.0f;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:completion];
    }
    else {
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setActionToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated {
    [_actionToolbar setItems:toolbarItems animated:animated];
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
    
    void (^animation)() = ^{
        if (hidden) {
            _actionNavigationBar.alpha = 0.0f;
        }
        else {
            _actionNavigationBar.alpha = 1.0f;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animation completion:completion];
    }
    else {
        animation();
        if (completion) {
            completion(YES);
        }
    }
}

- (void)setActionNavigationItem:(UINavigationItem *)item animated:(BOOL)animated {
    [_actionNavigationBar setItems:@[item] animated:animated];
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
