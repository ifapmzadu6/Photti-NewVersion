//
//  PWPhotoPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoPageViewController.h"

#import "PWColors.h"
#import "PWModelObject.h"
#import "PWPhotoViewController.h"

#import "PWTabBarController.h"

@interface PWPhotoPageViewController ()

@property (strong, nonatomic) NSArray *photos;

@end

@implementation PWPhotoPageViewController

- (id)initWithPhotos:(NSArray *)photos index:(NSUInteger)index {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(40.0f), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
        _photos = photos;
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        self.delegate = self;
        self.dataSource = self;
        [self setViewControllers:@[[self makePhotoViewController:index]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
        self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
//    [tabBarController setTabBarHidden:YES animated:YES];
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction)];
    [tabBarController setToolbarItems:@[actionBarButtonItem, flexibleSpace, trashBarButtonItem] animated:YES];
//    [tabBarController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItemAction
- (void)actionBarButtonAction {
    
}

- (void)trashBarButtonAction {
    
}

#pragma mark UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    PWPhotoViewController *photoViewController = (PWPhotoViewController *)viewController;
    NSInteger index = [_photos indexOfObject:photoViewController.photo];
    return [self makePhotoViewController:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    PWPhotoViewController *photoViewController = (PWPhotoViewController *)viewController;
    NSInteger index = [_photos indexOfObject:photoViewController.photo];
    return [self makePhotoViewController:index + 1];
}

#pragma mark PWPhotoViewController
- (UIViewController *)makePhotoViewController:(NSInteger)index {
    if (index < 0 || index == _photos.count) {
        return nil;
    }
    
    PWPhotoViewController *viewController = [[PWPhotoViewController alloc] initWithPhoto:_photos[index]];
    NSString *title = [NSString stringWithFormat:@"%ld/%ld", (long)index + 1, (long)_photos.count];
    viewController.title = title;
    __weak typeof(self) wself = self;
    [viewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.title = title;
    }];
    return viewController;
}

@end
