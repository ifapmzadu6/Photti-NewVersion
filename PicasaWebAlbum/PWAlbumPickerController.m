//
//  PWAlbumPickerController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumPickerController.h"

#import "PAColors.h"

#import "PLAssetsManager.h"
#import "PWOAuthManager.h"
#import "PADepressingTransition.h"

#import "PWAlbumPickerNavigationController.h"
#import "PWAlbumPickerWebAlbumListViewController.h"
#import "PWAlbumPickerLocalAlbumListViewController.h"

@interface PWAlbumPickerController ()

@property (strong, nonatomic) PWAlbumPickerNavigationController *localNavigationController;
@property (strong, nonatomic) PWAlbumPickerNavigationController *webNavigationController;

@property (strong, nonatomic) UIToolbar *toolbar;

@property (copy, nonatomic) void (^completion)(id, BOOL);

@property (strong, nonatomic) PADepressingTransition *transition;

@end

@implementation PWAlbumPickerController

- (id)initWithCompletion:(void (^)(id, BOOL))completion {
    self = [super init];
    if (self) {
        _completion = completion;
        
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized && [PLAssetsManager sharedManager].autoCreateAlbumType != PLAssetsManagerAutoCreateAlbumTypeUnknown) {
            PWAlbumPickerLocalAlbumListViewController *localAlbumViewcontroller = [[PWAlbumPickerLocalAlbumListViewController alloc] init];
            _localNavigationController = [[PWAlbumPickerNavigationController alloc] initWithRootViewController:localAlbumViewcontroller];
        }
        
        if ([PWOAuthManager isLogined]) {
            PWAlbumPickerWebAlbumListViewController *webAlbumViewcontroller = [[PWAlbumPickerWebAlbumListViewController alloc] init];
            _webNavigationController = [[PWAlbumPickerNavigationController alloc] initWithRootViewController:webAlbumViewcontroller];
        }
        
        self.delegate = self;
        BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? YES : NO;
        if (isPhone) {
            self.transitioningDelegate = (id)self;
        }
        
        if (_localNavigationController && _webNavigationController) {
            self.viewControllers = @[_localNavigationController, _webNavigationController];
            self.selectedIndex = 1;
            self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
        }
        else if (_localNavigationController) {
            self.viewControllers = @[_localNavigationController];
            self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        }
        else if (_webNavigationController) {
            self.viewControllers = @[_webNavigationController];
            self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
        }
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    self.tabBar.barTintColor = [UIColor blackColor];
    
    _toolbar = [[UIToolbar alloc] init];
    _toolbar.barTintColor = [UIColor blackColor];
    [self.view insertSubview:_toolbar belowSubview:self.tabBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [self setPrompt:_prompt];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
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
    
    for(UIView *view in self.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            [view setFrame:CGRectMake(view.frame.origin.x, rect.size.height - tHeight, view.frame.size.width, tHeight)];
        }
    }
    
    _toolbar.frame = CGRectMake(0.0f, rect.size.height - tHeight, rect.size.width, tHeight);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController respondsToSelector:@selector(updateTabBarItem)]) {
            [viewController performSelector:@selector(updateTabBarItem)];
        }
    }
#pragma clang diagnostic pop
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonActionWithSelectedAlbum:(id)selectedAlbum isWebAlbum:(BOOL)isWebAlbum {
    if (_completion) {
        _completion(selectedAlbum, isWebAlbum);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [viewController viewDidAppear:NO];
    
    if (viewController == _localNavigationController) {
        self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
    }
    else if (viewController == _webNavigationController) {
        self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    }
}

#pragma methods
- (void)setPrompt:(NSString *)prompt {
    _prompt = prompt;
    
    for (UINavigationController *navigationController in self.viewControllers) {
        for (UIViewController *viewController in navigationController.viewControllers) {
            viewController.navigationItem.prompt = prompt;
        }
    }
}

#pragma mark - UIViewControllerTransitioningDelegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.transition = [PADepressingTransition new];
    return self.transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.transition;
}

@end
