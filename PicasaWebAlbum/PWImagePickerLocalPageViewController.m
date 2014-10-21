//
//  PWImagePickerLocalPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerLocalPageViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLParallelNavigationTitleView.h"
#import "PSImagePickerController.h"

#import "PWImagePickerLocalAllPhotoViewController.h"
#import "PWImagePickerLocalAlbumListViewController.h"
#import "PWImagePickerLocaliCloudViewController.h"

@interface PWImagePickerLocalPageViewController ()

@property (strong, nonatomic) NSArray *myViewControllers;

@property (strong, nonatomic) PLParallelNavigationTitleView *titleView;

@end

@implementation PWImagePickerLocalPageViewController

static CGFloat PageViewControllerOptionInterPageSpacingValue = 40.0f;

- (id)init {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(PageViewControllerOptionInterPageSpacingValue), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
        NSString *title = NSLocalizedString(@"Camera Roll", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:@"Picture"] selectedImage:[UIImage imageNamed:@"PictureSelected"]];
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _myViewControllers = [self makeViewControllers];
    [self setViewControllers:@[_myViewControllers[1]]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *cancelBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonitem;
    UIBarButtonItem *doneBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonitem;
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    //ScrollViewDelegate
    [self.view.subviews.firstObject setDelegate:(id)self];
    
    _titleView = [[PLParallelNavigationTitleView alloc] init];
    _titleView.frame = CGRectMake(0.0f, 0.0f, 200.0f, 44.0f);
    __weak typeof(self) wself = self;
    [_titleView setTitleBeforeCurrentTitle:^NSString *(NSString *presentTitle) {
        typeof(wself) sself = wself;
        if (!sself) return nil;
        
        NSUInteger index = 0;
        for (UIViewController *viewController in sself.myViewControllers) {
            if ([viewController.title isEqualToString:presentTitle]) {
                index = [sself.myViewControllers indexOfObject:viewController];
            }
        }
        if (index == 0) {
            return nil;
        }
        
        UIViewController *beforeViewController = [sself.myViewControllers objectAtIndex:index - 1];
        return beforeViewController.title;
    }];
    [_titleView setTitleAfterCurrentTitle:^NSString *(NSString *presentTitle) {
        typeof(wself) sself = wself;
        if (!sself) return nil;
        
        NSUInteger index = 0;
        for (UIViewController *viewController in sself.myViewControllers) {
            if ([viewController.title isEqualToString:presentTitle]) {
                index = [sself.myViewControllers indexOfObject:viewController];
            }
        }
        if (index == sself.myViewControllers.count - 1) {
            return nil;
        }
        
        UIViewController *afterViewController = [sself.myViewControllers objectAtIndex:index + 1];
        return afterViewController.title;
    }];
    [_titleView setNumberOfPages:_myViewControllers.count];
    NSUInteger defaultIndex = 1;
    [_titleView setCurrentIndex:defaultIndex];
    UIViewController *viewController = _myViewControllers[defaultIndex];
    [_titleView setCurrentTitle:viewController.title];
    [_titleView setTitleTextColor:[UIColor whiteColor]];
    [self.navigationItem setTitleView:_titleView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _titleView.isDisableLayoutSubViews = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _titleView.isDisableLayoutSubViews = NO;
    [_titleView setNeedsLayout];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.tabBarItem.image = [PAIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
            self.tabBarItem.selectedImage = [PAIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        }
        else {
            self.tabBarItem.image = [UIImage imageNamed:@"Picture"];
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"PictureSelected"];
        }
    }
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    [tabBarController doneBarButtonAction];
}

- (void)cancelBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat width = scrollView.bounds.size.width;
    [_titleView setScrollRate:(scrollView.contentOffset.x - width) / width];
}

#pragma mark UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = [_myViewControllers indexOfObject:viewController];
    if (index == 0) {
        return nil;
    }
    
    return [_myViewControllers objectAtIndex:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = [_myViewControllers indexOfObject:viewController];
    if (index == _myViewControllers.count - 1) {
        return nil;
    }
    return [_myViewControllers objectAtIndex:index + 1];
}

#pragma mark UIPageViewControllerDataSourceOption
- (NSArray *)makeViewControllers {
    __weak typeof(self) wself = self;
    
    PWImagePickerLocalAllPhotoViewController *allPhotosViewController = [[PWImagePickerLocalAllPhotoViewController alloc] init];
    NSString *allPhotosViewControllerTitle = allPhotosViewController.title;
    [allPhotosViewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.titleView setCurrentIndex:0];
        [sself.titleView setCurrentTitle:allPhotosViewControllerTitle];
    }];
    PWImagePickerLocalAlbumListViewController *albumListViewController = [[PWImagePickerLocalAlbumListViewController alloc] init];
    NSString *albumListViewControllerTitle = albumListViewController.title;
    [albumListViewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.titleView setCurrentIndex:1];
        [sself.titleView setCurrentTitle:albumListViewControllerTitle];
    }];
    PWImagePickerLocaliCloudViewController *iCloudViewController = [[PWImagePickerLocaliCloudViewController alloc] init];
    NSString *iCloudViewControllerTitle = iCloudViewController.title;
    [iCloudViewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.titleView setCurrentIndex:2];
        [sself.titleView setCurrentTitle:iCloudViewControllerTitle];
    }];
    
    return @[allPhotosViewController, albumListViewController, iCloudViewController];
}

@end
