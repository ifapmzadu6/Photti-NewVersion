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

@property (weak, nonatomic) PWAlbumPickerNavigationController *navigationController;
@property (weak, nonatomic) UIViewController *albumViewController;

@property (nonatomic) BOOL isDownloadMode;
@property (copy, nonatomic) void (^completion)(PWAlbumObject *);

@end

@implementation PWAlbumPickerController

- (id)initWithDownloadMode:(BOOL)isDownloadMode completion:(void (^)(PWAlbumObject *album))completion {
    self = [super init];
    if (self) {
        _isDownloadMode = isDownloadMode;
        _completion = completion;
        
        UIViewController *albumViewcontroller = nil;
        if (isDownloadMode) {
            albumViewcontroller = [[PWAlbumPickerLocalAlbumListViewController alloc] init];
        }
        else {
            albumViewcontroller = [[PWAlbumPickerWebAlbumListViewController alloc] init];
        }
        _albumViewController = albumViewcontroller;
        PWAlbumPickerNavigationController *navigationController = [[PWAlbumPickerNavigationController alloc] initWithRootViewController:albumViewcontroller];
        _navigationController = navigationController;
        
        UIViewController *dammyViewController = [[UIViewController alloc] init];
        dammyViewController.tabBarItem.enabled = NO;
        
        if (isDownloadMode) {
            self.viewControllers = @[navigationController, dammyViewController];
        }
        else {
            self.viewControllers = @[dammyViewController, navigationController];
        }        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    if (_isDownloadMode) {
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    }
    else {
        self.tabBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    }
    
    _toolbar = [[UIToolbar alloc] init];
    [self.view insertSubview:_toolbar belowSubview:self.tabBar];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonActionWithSelectedAlbum:(PWAlbumObject *)selectedAlbum {
    if (_completion) {
        _completion(nil);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma methods
- (void)setPrompt:(NSString *)prompt {
    _prompt = prompt;
    
    UIViewController *viewController = _albumViewController;
    if (viewController) {
        viewController.navigationItem.prompt = prompt;
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
