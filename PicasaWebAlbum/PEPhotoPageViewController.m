//
//  PHPhotoPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoPageViewController.h"

@import MapKit;

#import "PAColors.h"
#import "PAIcons.h"
#import "PEPhotoViewController.h"
#import "PEPhotoEditViewController.h"
#import "PABaseNavigationController.h"
#import "PWMapViewController.h"
#import "PATabBarAdsController.h"
#import "UIView+ScreenCapture.h"

@interface PEPhotoPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) PHAssetCollection *assetCollection;
@property (strong, nonatomic) PHFetchResult *fetchedResult;
@property (nonatomic) NSUInteger index;

@end

@implementation PEPhotoPageViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection index:(NSUInteger)index {
    self = [self initWithAssetCollection:assetCollection index:index ascending:NO];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection index:(NSUInteger)index ascending:(BOOL)ascending {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(40.0f), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
        _assetCollection = assetCollection;
        _fetchedResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
        _ascending = ascending;
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        self.delegate = self;
        self.dataSource = self;
        [self setViewControllers:@[[self makePhotoViewController:index]]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:nil];
        self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    }
    return self;
}

- (instancetype)initWithResult:(PHFetchResult *)result index:(NSUInteger)index {
    self = [self initWithResult:result index:index ascending:NO];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithResult:(PHFetchResult *)result index:(NSUInteger)index ascending:(BOOL)ascending {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(40.0f), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
        _fetchedResult = result;
        _ascending = ascending;
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        self.delegate = self;
        self.dataSource = self;
        [self setViewControllers:@[[self makePhotoViewController:index]]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:nil];
        self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Tag"] style:UIBarButtonItemStylePlain target:self action:@selector(tagBarButtonAction)];
    tagBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Tag"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    UIBarButtonItem *pinBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PinIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(pinBarButtonAction)];
    pinBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"PinIcon"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    self.navigationItem.rightBarButtonItems = @[pinBarButtonItem, tagBarButtonItem];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction:)];
    UIBarButtonItem *organizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(organizeBarButtonAction:)];
    UIBarButtonItem *trashButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[actionBarButtonItem, flexibleSpace, organizeBarButtonItem, flexibleSpace, trashButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setToolbarTintColor:[PAColors getColor:PAColorsTypeTintLocalColor]];
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
            PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
            [tabBarController setTabBarHidden:YES animated:YES completion:nil];
        }];
    }
    [tabBarController setAdsHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

#pragma mark UIBarButtonAction
- (void)tagBarButtonAction {
    PHAsset *asset = _fetchedResult[_index];
    UIImage *screenshot = [self.view screenCapture];
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    __weak typeof(self) wself = self;
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        typeof(wself) sself = wself;
        if (!sself) return;
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil);
        NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
        CFRelease(imageSource);
        dispatch_async(dispatch_get_main_queue(), ^{
            PEPhotoEditViewController *viewController = [[PEPhotoEditViewController alloc] initWithAsset:asset metadata:metadata backgroundScreenShot:screenshot];
            PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
            navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
            navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [sself presentViewController:navigationController animated:YES completion:nil];
        });
    }];
}

- (void)pinBarButtonAction {
    PHAsset *asset = _fetchedResult[_index];
    CLLocation *location = asset.location;
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    __weak typeof(self) wself = self;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(200.0f, 200.0f) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PWMapViewController *viewController = [[PWMapViewController alloc] initWithImage:result latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
        PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
        navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [sself presentViewController:navigationController animated:YES completion:nil];
    }];
}

- (void)actionBarButtonAction:(id)sender {
    PHAsset *asset = _fetchedResult[_index];
    __weak typeof(self) wself = self;
    if (asset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            typeof(wself) sself = wself;
            if (!sself) return;
            UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[result] applicationActivities:nil];
            [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
        }];
    }
    else if (asset.mediaType == PHAssetMediaTypeVideo) {
        
    }
}

- (void)organizeBarButtonAction:(id)sender {
    
}

- (void)trashBarButtonAction:(id)sender {
    PHAsset *asset = _fetchedResult[_index];
    __weak typeof(self) wself = self;
    [self deleteAssets:@[asset] completion:^(BOOL success, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (success && !error) {
            [sself.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mark UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    PEPhotoViewController *photoViewController = (PEPhotoViewController *)viewController;
    NSInteger index = [_fetchedResult indexOfObject:photoViewController.asset];
    NSUInteger beforeIndex = (_ascending) ? index+1 : index-1;
    return [self makePhotoViewController:beforeIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    PEPhotoViewController *photoViewController = (PEPhotoViewController *)viewController;
    NSInteger index = [_fetchedResult indexOfObject:photoViewController.asset];
    NSUInteger afterIndex = (_ascending) ? index-1 : index+1;
    return [self makePhotoViewController:afterIndex];
}

#pragma mark PHPhotoViewController
- (UIViewController *)makePhotoViewController:(NSInteger)index {
    if (index < 0 || index == _fetchedResult.count) {
        return nil;
    }
    
    PHAsset *asset = _fetchedResult[index];
    PEPhotoViewController *viewController = [[PEPhotoViewController alloc] initWithAsset:asset];
    NSString *title = [NSString stringWithFormat:@"%ld/%ld", (long)index + 1, (long)_fetchedResult.count];
    viewController.title = title;
    BOOL isGPSEnable = asset.location ? YES : NO;
    __weak typeof(self) wself = self;
    viewController.viewDidAppearBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.title = title;
        sself.index = index;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIBarButtonItem *item = sself.navigationItem.rightBarButtonItems.firstObject;
            item.enabled = isGPSEnable;
        });
    };
    viewController.didSingleTapBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        if ([tabBarController isToolbarHideen]) {
            [tabBarController setIsStatusBarHidden:NO animated:YES];
            [sself.navigationController setNavigationBarHidden:NO animated:YES];
            [tabBarController setToolbarFadeout:NO animated:YES completion:nil];
            [UIView animateWithDuration:0.25f animations:^{
                sself.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
            }];
            sself.navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
        else {
            [tabBarController setIsStatusBarHidden:YES animated:YES];
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

#pragma mark Photo
- (void)deleteAssets:(NSArray *)assets completion:(void (^)(BOOL, NSError *))completion {
    if (assets.count == 0) return;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assets];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    }];
}



@end
