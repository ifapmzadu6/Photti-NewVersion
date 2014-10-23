//
//  PWAlbumPickerController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PTAlbumPickerController.h"

#import "PAColors.h"
#import "PAIcons.h"

#import "PLAssetsManager.h"
#import "PEAssetsManager.h"
#import "PWOAuthManager.h"
#import "PADepressingTransition.h"

#import "PABaseNavigationController.h"
#import "PTWebAlbumListViewController.h"
#import "PTLocalAlbumListViewController.h"
#import "PTNewLocalAlbumListViewController.h"

@interface PTAlbumPickerController () <UITabBarControllerDelegate>

@property (strong, nonatomic) UIViewController *localAlbumPickerController;
@property (strong, nonatomic) UIViewController *webAlbumPickerController;

@property (copy, nonatomic) void (^completion)(id, BOOL);

@property (strong, nonatomic) PADepressingTransition *transition;

@end

@implementation PTAlbumPickerController

- (id)initWithCompletion:(void (^)(id, BOOL))completion {
    self = [super init];
    if (self) {
        _completion = completion;
        
        UINavigationController *localNavigationController = nil;
        if ([PEAssetsManager isStatusAuthorized]) {
            if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
                _localAlbumPickerController = [PTNewLocalAlbumListViewController new];
            }
            else {
                _localAlbumPickerController = [PTLocalAlbumListViewController new];
            }
            
            localNavigationController = [[PABaseNavigationController alloc] initWithRootViewController:_localAlbumPickerController];
            localNavigationController.navigationBar.barTintColor = [UIColor blackColor];
            localNavigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [PAColors getColor:kPAColorsTypeBackgroundColor]};
        }
        
        UINavigationController *webNavigationController = nil;
        if ([PWOAuthManager isLogined]) {
            _webAlbumPickerController = [PTWebAlbumListViewController new];
            webNavigationController = [[PABaseNavigationController alloc] initWithRootViewController:_webAlbumPickerController];
            webNavigationController.navigationBar.barTintColor = [UIColor blackColor];
            webNavigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [PAColors getColor:kPAColorsTypeBackgroundColor]};
        }
        
        self.delegate = self;
        BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? YES : NO;
        if (isPhone) {
            self.transitioningDelegate = (id)self;
        }
        
        if (localNavigationController && webNavigationController) {
            self.viewControllers = @[localNavigationController, webNavigationController];
            self.selectedIndex = 1;
            self.colors = @[[PAColors getColor:kPAColorsTypeTintLocalColor], [PAColors getColor:kPAColorsTypeTintWebColor]];
        }
        else if (localNavigationController) {
            self.viewControllers = @[localNavigationController];
            self.tabBar.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
            self.colors = @[[PAColors getColor:kPAColorsTypeTintLocalColor]];
        }
        else if (webNavigationController) {
            self.viewControllers = @[webNavigationController];
            self.tabBar.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
            self.colors = @[[PAColors getColor:kPAColorsTypeTintWebColor]];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    self.tabBar.barTintColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [self setPrompt:_prompt];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    CGFloat tHeight = [self viewInsets].bottom;
    
    for (UIView *view in self.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            [view setFrame:CGRectMake(view.frame.origin.x, rect.size.height - tHeight, view.frame.size.width, tHeight)];
        }
    }
    
    UINavigationController *webNavigationController = _webAlbumPickerController.navigationController;
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        webNavigationController.tabBarItem.image = [PAIcons imageWithImage:[UIImage imageNamed:@"Picasa"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        webNavigationController.tabBarItem.selectedImage = [PAIcons imageWithImage:[UIImage imageNamed:@"PicasaSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        webNavigationController.tabBarItem.image = [UIImage imageNamed:@"Picasa"];
        webNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"PicasaSelected"];
    }
    
    UINavigationController *localNavigationController = _localAlbumPickerController.navigationController;
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        localNavigationController.tabBarItem.image = [PAIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        localNavigationController.tabBarItem.selectedImage = [PAIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        localNavigationController.tabBarItem.image = [UIImage imageNamed:@"Picture"];
        localNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"PictureSelected"];
    }
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonActionWithSelectedAlbum:(id)selectedAlbum isWebAlbum:(BOOL)isWebAlbum {
    if (_completion) {
        _completion(selectedAlbum, isWebAlbum);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
