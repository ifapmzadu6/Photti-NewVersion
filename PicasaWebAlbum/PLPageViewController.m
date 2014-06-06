//
//  PWPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPageViewController.h"

#import "PLParallelNavigationTitleView.h"
#import "PLAllPhotosViewController.h"
#import "PLAlbumListViewController.h"
#import "PLiCloudViewController.h"
#import "PWTabBarController.h"
#import "PWSearchNavigationController.h"
#import "BlocksKit+UIKit.h"

#import "PWColors.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PWSnowFlake.h"
#import "PLDateFormatter.h"

@interface PLPageViewController ()

@property (strong, nonatomic) NSArray *myViewControllers;

@property (strong, nonatomic) PLParallelNavigationTitleView *titleView;

@property (nonatomic) BOOL isAllPhotoSelectMode;

@end

@implementation PLPageViewController

static CGFloat PageViewControllerOptionInterPageSpacingValue = 40.0f;

- (id)init {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(PageViewControllerOptionInterPageSpacingValue), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
        NSString *title = NSLocalizedString(@"カメラロール", nil);
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
    
    self.navigationController.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    
    _myViewControllers = [self makeViewControllers];
    [self setViewControllers:@[_myViewControllers[1]]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //ScrollViewDelegate
    [self.view.subviews.firstObject setDelegate:self];
    
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
    [self.navigationItem setTitleView:_titleView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [tabBarController setToolbarHidden:YES animated:animated completion:nil];
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
    
    [_titleView setNeedsLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)searchBarButtonAction {
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setTabBarHidden:YES animated:YES completion:nil];
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    }];
}

- (void)addBarButtonAction {
    UIAlertView *alertView = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"新規アルバム", nil) message:NSLocalizedString(@"アルバム名を入力してください。", nil)];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{
        
    }];
    __weak UIAlertView *wAlertView = alertView;
    [alertView bk_addButtonWithTitle:NSLocalizedString(@"Save", nil) handler:^{
        UIAlertView *sAlertView = wAlertView;
        if (!sAlertView) return;
        
        UITextField *textField = [sAlertView textFieldAtIndex:0];
        NSString *title = textField.text;
        if (!title || [title isEqualToString:@""]) {
            title = NSLocalizedString(@"新規アルバム", nil);
        }
        
        __weak typeof(self) wself = self;
        [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
            album.id_str = [PWSnowFlake generateUniqueIDString];
            album.name = NSLocalizedString(@"新規アルバム", nil);
            NSDate *date = [NSDate date];
            NSDate *adjustedDate = [PLDateFormatter adjustZeroClock:date];
            album.tag_date = adjustedDate;
            album.timestamp = @((unsigned long)([adjustedDate timeIntervalSince1970]) * 1000);
            album.import = date;
            album.update = date;
            album.tag_type = @(PLAlbumObjectTagTypeMyself);
            
            NSError *error = nil;
            [context save:&error];
            
            for (UIViewController *viewController in sself.viewControllers) {
                if ([viewController isKindOfClass:[PLAlbumListViewController class]]) {
                    PLAlbumListViewController *albumListViewController = (PLAlbumListViewController *)viewController;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [albumListViewController reloadData];
                    });
                }
            }
        }];
    }];
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = NSLocalizedString(@"新規アルバム", nil);
    [alertView show];
}

- (void)actionBarButtonAction {
}

- (void)allPhotoSelectBarButtonAction {
    PLAllPhotosViewController *allPhotoViewController = (PLAllPhotosViewController *)_myViewControllers[0];
    [allPhotoViewController setIsSelectMode:YES withSelectIndexPaths:nil];
    [self enableAllPhotoViewControllerSelectMode];
}

- (void)selectCancelBarButtonAction {
    if (_isAllPhotoSelectMode) {
        _isAllPhotoSelectMode = NO;
        
        PLAllPhotosViewController *allPhotoViewController = (PLAllPhotosViewController *)_myViewControllers[0];
        [allPhotoViewController setIsSelectMode:NO withSelectIndexPaths:nil];
        [self setViewControllers:@[allPhotoViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    
    self.navigationController.navigationBar.alpha = 1.0f;
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)selectActionBarButtonAction {
    
}

- (void)selectAddBarButtonAction {
    
}

- (void)selectTrashBarButtonAction {
    
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat width = scrollView.bounds.size.width;
    [_titleView setScrollRate:(scrollView.contentOffset.x - width) / width];
}

#pragma mark UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if (_isAllPhotoSelectMode) {
        return nil;
    }
    
    NSInteger index = [_myViewControllers indexOfObject:viewController];
    if (index == 0) {
        return nil;
    }
    
    return [_myViewControllers objectAtIndex:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if (_isAllPhotoSelectMode) {
        return nil;
    }
    
    NSInteger index = [_myViewControllers indexOfObject:viewController];
    if (index == _myViewControllers.count - 1) {
        return nil;
    }
    return [_myViewControllers objectAtIndex:index + 1];
}

#pragma mark UIPageViewControllerDataSourceOption
- (NSArray *)makeViewControllers {
    __weak typeof(self) wself = self;
    
    PLAllPhotosViewController *allPhotosViewController = [[PLAllPhotosViewController alloc] init];
    NSString *allPhotosViewControllerTitle = allPhotosViewController.title;
    [allPhotosViewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.titleView setCurrentIndex:0];
        [sself.titleView setCurrentTitle:allPhotosViewControllerTitle];
        
        UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
        [sself.navigationItem setRightBarButtonItems:@[searchBarButtonItem] animated:YES];
        
        UIBarButtonItem *allPhotoSelectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"選択", nil) style:UIBarButtonItemStylePlain target:sself action:@selector(allPhotoSelectBarButtonAction)];
        [sself.navigationItem setLeftBarButtonItem:allPhotoSelectBarButtonItem animated:YES];
    }];
    [allPhotosViewController setHeaderViewDidTapBlock:^(BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself enableAllPhotoViewControllerSelectMode];
    }];
    [allPhotosViewController setPhotoDidSelectedInSelectModeBlock:^(NSArray *indexPaths) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
    }];
    
    PLAlbumListViewController *albumListViewController = [[PLAlbumListViewController alloc] init];
    NSString *albumListViewControllerTitle = albumListViewController.title;
    [albumListViewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.titleView setCurrentIndex:1];
        [sself.titleView setCurrentTitle:albumListViewControllerTitle];
        
        UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
        UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
        [sself.navigationItem setRightBarButtonItems:@[addBarButtonItem, searchBarButtonItem] animated:YES];
        
        UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(actionBarButtonAction)];
        [sself.navigationItem setLeftBarButtonItem:actionBarButtonItem animated:YES];
    }];
    
    PLiCloudViewController *iCloudViewController = [[PLiCloudViewController alloc] init];
    NSString *iCloudViewControllerTitle = iCloudViewController.title;
    [iCloudViewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.titleView setCurrentIndex:2];
        [sself.titleView setCurrentTitle:iCloudViewControllerTitle];
        
        UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
        [sself.navigationItem setRightBarButtonItems:@[searchBarButtonItem] animated:YES];
        
//        UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"選択", nil) style:UIBarButtonItemStylePlain target:sself action:@selector(selectBarButtonAction)];
//        [sself.navigationItem setLeftBarButtonItem:selectBarButtonItem animated:YES];
    }];
    
    return @[allPhotosViewController, albumListViewController, iCloudViewController];
}

#pragma mark EnableAllPhohoViewSelectMode
- (void)enableAllPhotoViewControllerSelectMode {
    _isAllPhotoSelectMode = YES;
    
    PLAllPhotosViewController *allPhotoViewController = (PLAllPhotosViewController *)_myViewControllers[0];
    [self setViewControllers:@[allPhotoViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    UIBarButtonItem *selectActionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction)];
    UIBarButtonItem *selectAddBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"移動", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAddBarButtonAction)];
    UIBarButtonItem *selectTrashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(selectTrashBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [tabBarController setActionToolbarItems:@[selectActionBarButtonItem, flexibleSpace, selectAddBarButtonItem, flexibleSpace, selectTrashBarButtonItem] animated:YES];
    [tabBarController setActionToolbarTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    UIBarButtonItem *selectCancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(selectCancelBarButtonAction)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@"項目を選択"];
    navigationItem.leftBarButtonItem = selectCancelBarButtonItem;
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
    [tabBarController setActionNavigationBarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.navigationController.navigationBar.alpha = 0.0f;
    }];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

@end
