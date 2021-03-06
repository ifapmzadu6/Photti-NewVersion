//
//  PWImagePickerController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSImagePickerController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLModelObject.h"
#import "PEAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWOAuthManager.h"
#import "PADepressingTransition.h"
#import "PAPhotoKit.h"

#import "PABaseNavigationController.h"
#import "PSNewLocalHomeViewController.h"
#import "PSLocalPageViewController.h"
#import "PSWebAlbumListViewController.h"

@interface PSImagePickerController () <UITabBarControllerDelegate>

@property (strong, nonatomic) UIViewController *localPageViewController;
@property (strong, nonatomic) UIViewController *webAlbumViewController;

@property (nonatomic) NSUInteger countOfSelectedWebPhoto;
@property (nonatomic) NSUInteger countOfSelectedLocalPhoto;

@property (copy, nonatomic) void (^completion)();

@property (strong, nonatomic) NSString *prompt;

@property (strong, nonatomic) PADepressingTransition *transition;

@end

@implementation PSImagePickerController

- (id)initWithAlbumTitle:(NSString *)albumTitle completion:(void (^)(NSArray *))completion {
    self = [super init];
    if (self) {
        _completion = completion;
        
        _prompt = [NSString stringWithFormat:NSLocalizedString(@"Select items to add to \"%@\".", nil), albumTitle];
        
        UINavigationController *localNavigationController = nil;
        if ([PEAssetsManager isStatusAuthorized]) {
            if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
                _localPageViewController = [PSNewLocalHomeViewController new];
            }
            else {
                _localPageViewController = [PSLocalPageViewController new];
            }
            localNavigationController = [[PABaseNavigationController alloc] initWithRootViewController:_localPageViewController];
            localNavigationController.navigationBar.barTintColor = [UIColor blackColor];
            localNavigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [PAColors getColor:kPAColorsTypeBackgroundColor]};
        }
        
        UINavigationController *webNavigationController = nil;
        if ([PWOAuthManager isLogined]) {
            _webAlbumViewController = [PSWebAlbumListViewController new];
            webNavigationController = [[PABaseNavigationController alloc] initWithRootViewController:_webAlbumViewController];
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
            self.colors = @[[PAColors getColor:kPAColorsTypeTintLocalColor], [PAColors getColor:kPAColorsTypeTintWebColor]];
        }
        else if (localNavigationController) {
            self.viewControllers = @[localNavigationController];
            self.colors = @[[PAColors getColor:kPAColorsTypeTintLocalColor]];
        }
        else if (webNavigationController) {
            self.viewControllers = @[webNavigationController];
            self.colors = @[[PAColors getColor:kPAColorsTypeTintWebColor]];
        }
        
        _selectedPhotoIDs = @[];
        _countOfSelectedWebPhoto = 0;
        _countOfSelectedLocalPhoto = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
    self.tabBar.barTintColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [self setPrompt:_prompt];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UINavigationController *webNavigationController = _webAlbumViewController.navigationController;
    if (self.isLandscape) {
        webNavigationController.tabBarItem.image = [PAIcons imageWithImage:[UIImage imageNamed:@"Picasa"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        webNavigationController.tabBarItem.selectedImage = [PAIcons imageWithImage:[UIImage imageNamed:@"PicasaSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        webNavigationController.tabBarItem.image = [UIImage imageNamed:@"Picasa"];
        webNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"PicasaSelected"];
    }
    
    UINavigationController *localNavigationController = _localPageViewController.navigationController;
    if (self.isLandscape) {
        localNavigationController.tabBarItem.image = [PAIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        localNavigationController.tabBarItem.selectedImage = [PAIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        localNavigationController.tabBarItem.image = [UIImage imageNamed:@"Picture"];
        localNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"PictureSelected"];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    __weak typeof(self) wself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.selectedPhotoIDs.count > 0) {
            NSMutableArray *photos = @[].mutableCopy;
            for (NSString *id_str in sself.selectedPhotoIDs) {
                id photo = [sself getPhotoByID:id_str];
                if (photo) {
                    [photos addObject:photo];
                }
            }
            
            if (sself.completion) {
                sself.completion(photos);
            }
        }
    }];
}

#pragma mark Methods
- (void)addSelectedPhoto:(id)photo {
    if (!photo) {
        return;
    }
    
    if ([photo isKindOfClass:[PLPhotoObject class]] ||
        [photo isKindOfClass:[PHAsset class]]) {
        NSString *id_str = nil;
        if ([photo isKindOfClass:[PHAsset class]]) {
            id_str = ((PHAsset *)photo).localIdentifier;
        }
        else {
            id_str = ((PLPhotoObject *)photo).id_str;
        }
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
}

- (void)removeSelectedPhoto:(id)photo {
    if (!photo) {
        return;
    }
    
    if ([photo isKindOfClass:[PLPhotoObject class]] ||
        [photo isKindOfClass:[PHAsset class]]) {
        NSString *id_str = nil;
        if ([photo isKindOfClass:[PHAsset class]]) {
            id_str = ((PHAsset *)photo).localIdentifier;
        }
        else {
            id_str = ((PLPhotoObject *)photo).id_str;
        }
        if (![_selectedPhotoIDs containsObject:id_str]) {
            return;
        }
        
        NSMutableArray *selectedPhotoIDs = _selectedPhotoIDs.mutableCopy;
        [selectedPhotoIDs removeObject:id_str];
        _selectedPhotoIDs = selectedPhotoIDs.copy;
        
        _countOfSelectedLocalPhoto--;
        
        if (_countOfSelectedLocalPhoto > 0) {
            _localPageViewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)_countOfSelectedLocalPhoto];
        }
        else {
            _localPageViewController.tabBarItem.badgeValue = nil;
        }
    }
    else if ([photo isKindOfClass:[PWPhotoObject class]]) {
        NSString *id_str = ((PLPhotoObject *)photo).id_str;
        if (![_selectedPhotoIDs containsObject:id_str]) {
            return;
        }
        
        NSMutableArray *selectedPhotoIDs = _selectedPhotoIDs.mutableCopy;
        [selectedPhotoIDs removeObject:id_str];
        _selectedPhotoIDs = selectedPhotoIDs.copy;
        
        _countOfSelectedWebPhoto--;
        
        if (_countOfSelectedWebPhoto > 0) {
            _webAlbumViewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)_countOfSelectedWebPhoto];
        }
        else {
            _webAlbumViewController.tabBarItem.badgeValue = nil;
        }
    }
}

#pragma mark GetPhotos
- (id)getPhotoByID:(NSString *)id_str {
    __block id photo = nil;
    
    photo = [PWPhotoObject getPhotoObjectWithID:id_str];
    if (!photo) {
        if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
            photo = [PAPhotoKit getAssetWithIdentifier:id_str];
        }
        else {
            photo = [PLPhotoObject getPhotoObjectWithID:id_str];
        }
    }
    
    return photo;
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
