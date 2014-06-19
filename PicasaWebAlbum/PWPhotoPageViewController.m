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

@property (nonatomic) NSUInteger index;
@property (nonatomic) NSString *id_str;

@property (strong, nonatomic) NSCache *photoViewCache;

@end

@implementation PWPhotoPageViewController

- (id)initWithPhotos:(NSArray *)photos index:(NSUInteger)index {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(40.0f), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
        _photos = photos;
        _index = index;
        
        _photoViewCache = [[NSCache alloc] init];
        _photoViewCache.countLimit = 10;
        
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
    [tabBarController setUserInteractionEnabled:NO];
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction)];
    [tabBarController setToolbarItems:@[actionBarButtonItem, flexibleSpace, trashBarButtonItem] animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_photoViewCache removeAllObjects];
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

#pragma mark Methods
- (void)changePhotos:(NSArray *)photos {
    _photos = photos;
    
    NSArray *filteredPhotos = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", _id_str]];
    if (filteredPhotos.count) {
        PWPhotoObject *newPhoto = filteredPhotos.firstObject;
        NSUInteger newIndex = [photos indexOfObject:newPhoto];
        [self setViewControllers:@[[self makePhotoViewController:newIndex]]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:nil];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
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
    
    PWPhotoObject *photo = _photos[index];
    PWPhotoViewController *viewController = [[PWPhotoViewController alloc] initWithPhoto:photo];
    NSString *title = [NSString stringWithFormat:@"%ld/%ld", (long)index + 1, (long)_photos.count];
    viewController.title = title;
    NSString *id_str = photo.id_str;
    __weak typeof(self) wself = self;
    [viewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.title = title;
        sself.index = index;
        sself.id_str = id_str;
    }];
    
    [viewController setHandleSingleTapBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
        if ([tabBarController isToolbarHideen]) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            [sself.navigationController setNavigationBarHidden:NO animated:YES];
            [tabBarController setToolbarFadeout:NO animated:YES completion:nil];
            [UIView animateWithDuration:0.25f animations:^{
                sself.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
            }];
        }
        else {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            [sself.navigationController setNavigationBarHidden:YES animated:YES];
            [tabBarController setToolbarFadeout:YES animated:YES completion:nil];
            [UIView animateWithDuration:0.25f animations:^{
                sself.view.backgroundColor = [UIColor blackColor];
            }];
        }
    }];
    
    viewController.photoViewCache = _photoViewCache;
    
    return viewController;
}

@end
