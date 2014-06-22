//
//  PWAlbumPickerController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumPickerController.h"

#import "PWColors.h"

#import "PWAlbumPickerNavigationController.h"
#import "PWAlbumPickerWebAlbumListViewController.h"
#import "PWAlbumPickerLocalAlbumListViewController.h"

@interface PWAlbumPickerController ()

@property (strong, nonatomic) UIToolbar *toolbar;

@property (copy, nonatomic) void (^completion)(id, BOOL);

@end

@implementation PWAlbumPickerController

- (id)initWithCompletion:(void (^)(id, BOOL))completion {
    self = [super init];
    if (self) {
        _completion = completion;
        
        PWAlbumPickerLocalAlbumListViewController *localAlbumViewcontroller = [[PWAlbumPickerLocalAlbumListViewController alloc] init];
        PWAlbumPickerNavigationController *localNavigationController = [[PWAlbumPickerNavigationController alloc] initWithRootViewController:localAlbumViewcontroller];
        
        PWAlbumPickerWebAlbumListViewController *webAlbumViewcontroller = [[PWAlbumPickerWebAlbumListViewController alloc] init];
        PWAlbumPickerNavigationController *webNavigationController = [[PWAlbumPickerNavigationController alloc] initWithRootViewController:webAlbumViewcontroller];
        
        self.delegate = self;
        self.viewControllers = @[localNavigationController, webNavigationController];
        self.selectedIndex = 1;
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundDarkColor];
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
    if(isLandscape) {
        tHeight = 32.0f;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    if (index == 0) {
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    }
    else if (index == 1) {
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
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

- (UIEdgeInsets)viewInsets {
    CGFloat nHeight = 44.0f + 30.0f;
    CGFloat tHeight = 44.0f;
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if(isLandscape) {
        nHeight = 32.0f + 22.0f;
        tHeight = 32.0f;
    }
    
    return UIEdgeInsetsMake(nHeight + 20.0f, 0.0f, tHeight, 0.0f);
}

@end
