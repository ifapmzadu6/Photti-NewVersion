//
//  PWImagePickerController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerController.h"

#import "PAColors.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWOAuthManager.h"

#import "PWImagePickerNavigationController.h"
#import "PWImagePickerLocalPageViewController.h"
#import "PWImagePickerWebAlbumListViewController.h"

@interface PWImagePickerController ()

@property (strong, nonatomic) UIToolbar *toolbar;

@property (strong, nonatomic) PWImagePickerLocalPageViewController *localPageViewController;
@property (strong, nonatomic) PWImagePickerNavigationController *localNavigationcontroller;
@property (strong, nonatomic) PWImagePickerWebAlbumListViewController *webAlbumViewController;
@property (strong, nonatomic) PWImagePickerNavigationController *webNavigationController;

@property (nonatomic) NSUInteger countOfSelectedWebPhoto;
@property (nonatomic) NSUInteger countOfSelectedLocalPhoto;

@property (copy, nonatomic) void (^completion)();

@end

@implementation PWImagePickerController

- (id)initWithAlbumTitle:(NSString *)albumTitle completion:(void (^)(NSArray *))completion {
    self = [super init];
    if (self) {
        _completion = completion;
        
        NSString *titleOnNavigationBarString = [NSString stringWithFormat:NSLocalizedString(@"Select items to add to \"%@\".", nil), albumTitle];
        
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized && [PLAssetsManager sharedManager].autoCreateAlbumType != PLAssetsManagerAutoCreateAlbumTypeUnknown) {
            PWImagePickerLocalPageViewController *localPageViewController = [[PWImagePickerLocalPageViewController alloc] init];
            _localPageViewController = localPageViewController;
            PWImagePickerNavigationController *localNavigationcontroller = [[PWImagePickerNavigationController alloc] initWithRootViewController:localPageViewController];
            localNavigationcontroller.titleOnNavigationBar = titleOnNavigationBarString;
            _localNavigationcontroller = localNavigationcontroller;
        }
        
        if ([PWOAuthManager isLogined]) {
            PWImagePickerWebAlbumListViewController *webAlbumViewController = [[PWImagePickerWebAlbumListViewController alloc] init];
            _webAlbumViewController = webAlbumViewController;
            PWImagePickerNavigationController *webNavigationController = [[PWImagePickerNavigationController alloc] initWithRootViewController:_webAlbumViewController];
            webNavigationController.titleOnNavigationBar = titleOnNavigationBarString;
            _webNavigationController = webNavigationController;
        }
        
        self.delegate = self;
        
        if (_localNavigationcontroller && _webAlbumViewController) {
            self.viewControllers = @[_localNavigationcontroller, _webNavigationController];
            self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        }
        else if (_localNavigationcontroller) {
            self.viewControllers = @[_localNavigationcontroller];
            self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        }
        else if (_webAlbumViewController) {
            self.viewControllers = @[_webNavigationController];
            self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
        }
        
        _selectedPhotoIDs = @[];
        _countOfSelectedWebPhoto = 0;
        _countOfSelectedLocalPhoto = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    self.tabBar.barTintColor = [UIColor blackColor];
    
    _toolbar = [[UIToolbar alloc] init];
    _toolbar.barTintColor = [UIColor blackColor];
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    if (_selectedPhotoIDs.count > 0) {
        NSMutableArray *photos = @[].mutableCopy;
        for (NSString *id_str in _selectedPhotoIDs) {
            id photo = [self getPhotoByID:id_str];
            if (photo) {
                [photos addObject:photo];
            }
        }
        
        if (_completion) {
            _completion(photos);
        }
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
    
    if (viewController == _webNavigationController) {
        self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    }
    else if (viewController == _localNavigationcontroller) {
        self.tabBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
    }    
}

#pragma methods
- (UIEdgeInsets)viewInsets {
    CGFloat nHeight = 44.0f + 30.0f;
    CGFloat tHeight = 44.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if(UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            nHeight = 32.0f + 22.0f;
            tHeight = 32.0f;
        }
    }
    else {
        tHeight = 56.0f;
        nHeight = 79.0f;
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

#pragma mark GetPhotos
- (id)getPhotoByID:(NSString *)id_str {
    __block id photo = nil;
    
    void (^pwBlock)() = ^{
        [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
            request.fetchLimit = 1;
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count > 0) {
                photo = objects.firstObject;
            }
        }];
    };
    
    void (^plBlock)() = ^{
        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
            request.fetchLimit = 1;
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects.count > 0) {
                photo = objects.firstObject;
            }
        }];
    };
    
    if ([id_str hasPrefix:@"1"]) {
        plBlock();
        if (!photo) {
            pwBlock();
        }
    }
    else {
        pwBlock();
        if (!photo) {
            plBlock();
        }
    }
    
    return photo;
}

@end
