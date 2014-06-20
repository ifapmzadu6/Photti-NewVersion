//
//  PWImagePickerController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerController.h"

#import "PWColors.h"
#import "PLModelObject.h"
#import "PWModelObject.h"

#import "PWImagePickerNavigationController.h"
#import "PWImagePickerLocalPageViewController.h"
#import "PWImagePickerWebAlbumListViewController.h"

@interface PWImagePickerController ()

@property (strong, nonatomic) UIToolbar *toolbar;

@property (weak, nonatomic) PWImagePickerLocalPageViewController *localPageViewController;
@property (weak, nonatomic) PWImagePickerNavigationController *localNavigationcontroller;
@property (weak, nonatomic) PWImagePickerWebAlbumListViewController *webAlbumViewController;
@property (weak, nonatomic) PWImagePickerNavigationController *webNavigationController;

@property (nonatomic) NSUInteger countOfSelectedWebPhoto;
@property (nonatomic) NSUInteger countOfSelectedLocalPhoto;

@property (copy, nonatomic) void (^completion)();

@end

@implementation PWImagePickerController

- (id)initWithAlbumTitle:(NSString *)albumTitle completion:(void (^)(NSArray *))completion {
    self = [super init];
    if (self) {
        _completion = completion;
        
        PWImagePickerLocalPageViewController *localPageViewController = [[PWImagePickerLocalPageViewController alloc] init];
        _localPageViewController = localPageViewController;
        PWImagePickerNavigationController *localNavigationcontroller = [[PWImagePickerNavigationController alloc] initWithRootViewController:localPageViewController];
        localNavigationcontroller.titleOnNavigationBar = [NSString stringWithFormat:NSLocalizedString(@"Select items to add to \"%@\".", nil), albumTitle];
        _localNavigationcontroller = localNavigationcontroller;
        
        PWImagePickerWebAlbumListViewController *webAlbumViewController = [[PWImagePickerWebAlbumListViewController alloc] init];
        _webAlbumViewController = webAlbumViewController;
        PWImagePickerNavigationController *webNavigationController = [[PWImagePickerNavigationController alloc] initWithRootViewController:_webAlbumViewController];
        webNavigationController.titleOnNavigationBar = [NSString stringWithFormat:NSLocalizedString(@"Select items to add to \"%@\".", nil), albumTitle];
        _webNavigationController = webNavigationController;
        
        self.viewControllers = @[localNavigationcontroller, webNavigationController];
        self.delegate = self;
        
        _selectedPhotoIDs = @[];
        _countOfSelectedWebPhoto = 0;
        _countOfSelectedLocalPhoto = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    self.tabBar.barTintColor = [UIColor blackColor];
    
    _toolbar = [[UIToolbar alloc] init];
    [self.view insertSubview:_toolbar belowSubview:self.tabBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    if (_completion) {
        _completion(_selectedPhotoIDs);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [viewController viewWillAppear:NO];
    
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
}

#pragma methods
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

- (void)addSelectedPhoto:(id)photo {
    if (!photo) {
        return;
    }
    
    if ([photo isKindOfClass:[PLPhotoObject class]]) {
        NSString *id_str = ((PLPhotoObject *)photo).id_str;
        if ([_selectedPhotoIDs containsObject:id_str]) {
            return;
        }
        
        _selectedPhotoIDs = [_selectedPhotoIDs arrayByAddingObject:id_str];
        
        _countOfSelectedLocalPhoto++;
        
        _localPageViewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)_countOfSelectedLocalPhoto];
    }
    else if ([photo isKindOfClass:[PWPhotoObject class]]) {
        NSString *id_str = ((PWPhotoObject *)photo).id_str;
        if ([_selectedPhotoIDs containsObject:id_str]) {
            return;
        }
        
        _selectedPhotoIDs = [_selectedPhotoIDs arrayByAddingObject:id_str];
        
        _countOfSelectedWebPhoto++;
        
        _webAlbumViewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)_countOfSelectedWebPhoto];
    }
    else {
        
    }
}

- (void)removeSelectedPhoto:(id)photo {
    if (!photo) {
        return;
    }
    
    if ([photo isKindOfClass:[PLPhotoObject class]]) {
        NSString *id_str = ((PLPhotoObject *)photo).id_str;
        NSMutableArray *selectedPhotoIDs = _selectedPhotoIDs.mutableCopy;
        [selectedPhotoIDs removeObject:id_str];
        _selectedPhotoIDs = selectedPhotoIDs.copy;
        
        _countOfSelectedLocalPhoto--;
        
        if (_countOfSelectedLocalPhoto) {
            _localPageViewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)_countOfSelectedLocalPhoto];
        }
        else {
            _localPageViewController.tabBarItem.badgeValue = nil;
        }
    }
    else if ([photo isKindOfClass:[PWPhotoObject class]]) {
        NSString *id_str = ((PLPhotoObject *)photo).id_str;
        NSMutableArray *selectedPhotoIDs = _selectedPhotoIDs.mutableCopy;
        [selectedPhotoIDs removeObject:id_str];
        _selectedPhotoIDs = selectedPhotoIDs.copy;
        
        _countOfSelectedWebPhoto--;
        
        if (_countOfSelectedWebPhoto) {
            _webAlbumViewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)_countOfSelectedWebPhoto];
        }
        else {
            _webAlbumViewController.tabBarItem.badgeValue = nil;
        }
    }
    else {
        
    }
}

@end
