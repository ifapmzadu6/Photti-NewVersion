//
//  PLPhotoPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPhotoPageViewController.h"

#import "PWColors.h"
#import "PWTabBarController.h"
#import "PLPhotoViewController.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"

@interface PLPhotoPageViewController ()

@property (strong, nonatomic) NSArray *photos;
@property (nonatomic) NSUInteger index;

@end

@implementation PLPhotoPageViewController

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
        self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    UIBarButtonItem *uploadBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Copy", nil) style:UIBarButtonItemStylePlain target:self action:@selector(uploadBarButtonAction)];
//    UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[actionBarButtonItem, flexibleSpace, uploadBarButtonItem, flexibleSpace];
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    if ([tabBarController isTabBarHidden]) {
        [tabBarController setToolbarItems:toolbarItems animated:YES];
        if ([tabBarController isToolbarHideen]) {
            [tabBarController setToolbarHidden:NO animated:YES completion:nil];
        }
    }
    else {
        [tabBarController setToolbarItems:toolbarItems animated:YES];
        __weak typeof(self) wself = self;
        [tabBarController setToolbarHidden:NO animated:YES completion:^(BOOL finished) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
            [tabBarController setTabBarHidden:YES animated:YES completion:nil];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)actionBarButtonAction {
    PLPhotoObject *photo = _photos[_index];
    NSURL *url = [NSURL URLWithString:photo.url];
    __weak typeof(self) wself = self;
    [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[asset] applicationActivities:nil];
            [sself.tabBarController presentViewController:activityViewController animated:YES completion:nil];
        });
    } failureBlock:^(NSError *error) {
        
    }];
}

- (void)uploadBarButtonAction {
    
}

//- (void)trashBarButtonAction {
//}

#pragma mark UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    PLPhotoViewController *photoViewController = (PLPhotoViewController *)viewController;
    NSInteger index = [_photos indexOfObject:photoViewController.photo];
    return [self makePhotoViewController:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    PLPhotoViewController *photoViewController = (PLPhotoViewController *)viewController;
    NSInteger index = [_photos indexOfObject:photoViewController.photo];
    return [self makePhotoViewController:index + 1];
}

#pragma mark PWPhotoViewController
- (UIViewController *)makePhotoViewController:(NSInteger)index {
    if (index < 0 || index == _photos.count) {
        return nil;
    }
    
    PLPhotoViewController *viewController = [[PLPhotoViewController alloc] initWithPhoto:_photos[index]];
    NSString *title = [NSString stringWithFormat:@"%ld/%ld", (long)index + 1, (long)_photos.count];
    viewController.title = title;
    __weak typeof(self) wself = self;
    viewController.viewDidAppearBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.title = title;
        sself.index = index;
    };
    viewController.handleSingleTapBlock = ^{
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
            sself.navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
        else {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            [sself.navigationController setNavigationBarHidden:YES animated:YES];
            [tabBarController setToolbarFadeout:YES animated:YES completion:nil];
            [UIView animateWithDuration:0.25f animations:^{
                sself.view.backgroundColor = [UIColor blackColor];
            }];
            sself.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }
    };
    
    return viewController;
}

@end
