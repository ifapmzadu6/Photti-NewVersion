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
#import "PWBaseNavigationController.h"
#import "PLNewAlbumEditViewController.h"
#import "PWTabBarController.h"
#import "PWSearchNavigationController.h"
#import "PWSettingsViewController.h"
#import "PWAlbumPickerController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLCoreDataAPI.h"
#import "PLAssetsManager.h"
#import "PLModelObject.h"
#import "PWSnowFlake.h"
#import "PLDateFormatter.h"
#import "PDTaskManager.h"
#import "BlocksKit+UIKit.h"

@interface PLPageViewController ()

@property (strong, nonatomic) NSArray *myViewControllers;
@property (strong, nonatomic) PLParallelNavigationTitleView *titleView;
@property (nonatomic) BOOL isAllPhotoSelectMode;
@property (nonatomic) NSUInteger index;

@end

@implementation PLPageViewController

static CGFloat PageViewControllerOptionInterPageSpacingValue = 40.0f;

- (id)init {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(PageViewControllerOptionInterPageSpacingValue), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
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
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setTabBarHidden:NO animated:NO completion:nil];
    [tabBarController setToolbarHidden:YES animated:animated completion:nil];
    [tabBarController setAdsHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _titleView.isDisableLayoutSubViews = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    
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
    [tabBarController setAdsHidden:YES animated:NO];
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [tabBarController setTabBarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

- (void)addBarButtonAction {
    PLNewAlbumEditViewController *viewController = [[PLNewAlbumEditViewController alloc] initWithTitle:nil timestamp:@((long long)[[NSDate date] timeIntervalSince1970]*1000) uploading_type:nil];
    viewController.saveButtonBlock = ^(NSString *name, NSNumber *timestamp, NSNumber *uploading_type){
        [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
            album.id_str = [PWSnowFlake generateUniqueIDString];
            if (!name || [name isEqualToString:@""]) {
                album.name = NSLocalizedString(@"New Album", nil);
            }
            else {
                album.name = name;
            }
            album.tag_date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue/1000.0];
            album.timestamp = timestamp;
            album.import = [NSDate date];
            album.update = [NSDate date];
            album.tag_type = @(PLAlbumObjectTagTypeMyself);
        }];
    };
    PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

- (void)allPhotoSelectBarButtonAction {
    UIViewController *viewController = _myViewControllers[_index];
    
    if ([viewController isKindOfClass:[PLAllPhotosViewController class]]) {
        [(PLAllPhotosViewController *)viewController setSelectedPhotos:@[].mutableCopy];
        [(PLAllPhotosViewController *)viewController setIsSelectMode:YES];
    }
    else if ([viewController isKindOfClass:[PLiCloudViewController class]]) {
        [(PLiCloudViewController *)viewController setSelectedPhotos:@[].mutableCopy];
        [(PLiCloudViewController *)viewController setIsSelectMode:YES];
    }
    
    [self enableSelectMode:viewController];
}

- (void)selectCancelBarButtonAction {
    [self disableSelectMode:_myViewControllers[_index]];
}

- (void)selectActionBarButtonAction {
    UIViewController *viewController = _myViewControllers[_index];
    
    NSArray *selectedPhotos = nil;
    if ([viewController isKindOfClass:[PLAllPhotosViewController class]]) {
        selectedPhotos = [(PLAllPhotosViewController *)viewController selectedPhotos];
    }
    else if ([viewController isKindOfClass:[PLiCloudViewController class]]) {
        selectedPhotos = [(PLiCloudViewController *)viewController selectedPhotos];
    }
    if (!selectedPhotos) {
        return;
    }
    
    __block NSUInteger count = 0;
    __block NSUInteger maxCount = selectedPhotos.count;
    NSMutableArray *assets = @[].mutableCopy;
    __weak typeof(self) wself = self;
    for (PLPhotoObject *photoObject in selectedPhotos) {
        [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:photoObject.url] resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (!asset) {
                maxCount--;
            }
            else {
                [assets addObject:asset];
                count++;
            }
            if (maxCount == count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:assets applicationActivities:nil];
                    [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
                });
            }
        } failureBlock:^(NSError *error) {
            maxCount--;
        }];
    }
}

- (void)selectOrganizeBarButtonAction:(id)sender {
    __weak typeof(self) wself = self;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:nil];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Copy", nil) handler:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PLAllPhotosViewController *viewController = (PLAllPhotosViewController *)sself.viewControllers.firstObject;
        NSArray *selectedPhotos = viewController.selectedPhotos;
        
        PWAlbumPickerController *albumPickerController = [[PWAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            void (^completion)() = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    
                    [sself disableSelectMode:sself.myViewControllers[sself.index]];
                    
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            };
            
            if (isWebAlbum) {
                [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toWebAlbum:album completion:^(NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                    completion();
                }];
            }
            else {
                [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                    PLAlbumObject *albumObject = (PLAlbumObject *)album;
                    
                    for (PLPhotoObject *photoObject in selectedPhotos) {
                        [albumObject addPhotosObject:photoObject];
                    }
                    
                    completion();
                }];
            }
        }];
        albumPickerController.prompt = NSLocalizedString(@"Choose an album to copy to.", nil);
        [sself.tabBarController presentViewController:albumPickerController animated:YES completion:nil];
    }];
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    [actionSheet showFromBarButtonItem:sender animated:YES];
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
        
        sself.index = 0;
        [sself.titleView setCurrentIndex:0];
        [sself.titleView setCurrentTitle:allPhotosViewControllerTitle];
        
        UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
        [sself.navigationItem setRightBarButtonItems:@[searchBarButtonItem] animated:YES];
        UIBarButtonItem *allPhotoSelectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", nil) style:UIBarButtonItemStylePlain target:self action:@selector(allPhotoSelectBarButtonAction)];
        [sself.navigationItem setLeftBarButtonItem:allPhotoSelectBarButtonItem animated:YES];
        for (UIView *view in sself.navigationController.navigationBar.subviews) {
            view.exclusiveTouch = YES;
        }
    }];
    [allPhotosViewController setHeaderViewDidTapBlock:^(BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself enableSelectMode:sself.myViewControllers[0]];
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
        
        sself.index = 1;
        [sself.titleView setCurrentIndex:1];
        [sself.titleView setCurrentTitle:albumListViewControllerTitle];
        
        UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
        UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
        [sself.navigationItem setRightBarButtonItems:@[addBarButtonItem, searchBarButtonItem] animated:YES];
        UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
        settingsBarButtonItem.landscapeImagePhone = [PWIcons imageWithImage:[UIImage imageNamed:@"Settings"] insets:UIEdgeInsetsMake(2.0f, 2.0f, 2.0f, 2.0f)];
        self.navigationItem.leftBarButtonItem = settingsBarButtonItem;
        [sself.navigationItem setLeftBarButtonItem:settingsBarButtonItem animated:YES];
        for (UIView *view in sself.navigationController.navigationBar.subviews) {
            view.exclusiveTouch = YES;
        }
    }];
    
    PLiCloudViewController *iCloudViewController = [[PLiCloudViewController alloc] init];
    NSString *iCloudViewControllerTitle = iCloudViewController.title;
    [iCloudViewController setViewDidAppearBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.index = 2;
        [sself.titleView setCurrentIndex:2];
        [sself.titleView setCurrentTitle:iCloudViewControllerTitle];
        
        UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
        [sself.navigationItem setRightBarButtonItems:@[searchBarButtonItem] animated:YES];
        UIBarButtonItem *allPhotoSelectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", nil) style:UIBarButtonItemStylePlain target:self action:@selector(allPhotoSelectBarButtonAction)];
        [sself.navigationItem setLeftBarButtonItem:allPhotoSelectBarButtonItem animated:YES];
        for (UIView *view in sself.navigationController.navigationBar.subviews) {
            view.exclusiveTouch = YES;
        }
        for (UIView *view in sself.navigationController.navigationBar.subviews) {
            view.exclusiveTouch = YES;
        }
    }];
    [iCloudViewController setHeaderViewDidTapBlock:^(BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (isSelectMode) {
            [sself enableSelectMode:sself.myViewControllers[2]];
        }
    }];
    [iCloudViewController setPhotoDidSelectedInSelectModeBlock:^(NSArray *indexPaths) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
    }];
    
    return @[allPhotosViewController, albumListViewController, iCloudViewController];
}

#pragma mark EnableAllPhohoViewSelectMode
- (void)enableSelectMode:(UIViewController *)viewController {
    _isAllPhotoSelectMode = YES;
    
    [self setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    UIBarButtonItem *selectActionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction)];
    UIBarButtonItem *selectOrganizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(selectOrganizeBarButtonAction:)];
//    UIBarButtonItem *selectTrashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(selectTrashBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [tabBarController setActionToolbarItems:@[selectActionBarButtonItem, flexibleSpace, selectOrganizeBarButtonItem, flexibleSpace] animated:YES];
    [tabBarController setActionToolbarTintColor:[PWColors getColor:PWColorsTypeTintLocalColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    UIBarButtonItem *selectCancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(selectCancelBarButtonAction)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Select items", nil)];
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

- (void)disableSelectMode:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[PLAllPhotosViewController class]]) {
        [(PLAllPhotosViewController *)viewController setSelectedPhotos:@[].mutableCopy];
        [(PLAllPhotosViewController *)viewController setIsSelectMode:NO];
    }
    else if ([viewController isKindOfClass:[PLiCloudViewController class]]) {
        [(PLiCloudViewController *)viewController setSelectedPhotos:@[].mutableCopy];
        [(PLiCloudViewController *)viewController setIsSelectMode:NO];
    }
    
    if (_isAllPhotoSelectMode) {
        _isAllPhotoSelectMode = NO;
        
        [self setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
    
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    
    self.navigationController.navigationBar.alpha = 1.0f;
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

@end
