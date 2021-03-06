//
//  PLPhotoPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import ImageIO;

#import "PLPhotoPageViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PATabBarAdsController.h"
#import "PLPhotoViewController.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PABaseNavigationController.h"
#import "PAMapViewController.h"
#import "PLPhotoEditViewController.h"
#import "PTAlbumPickerController.h"
#import "PLCoreDataAPI.h"
#import "PDTaskManager.h"
#import "PAAlertControllerKit.h"
#import "UIView+ScreenCapture.h"

@interface PLPhotoPageViewController () <UIActionSheetDelegate>

@property (strong, nonatomic) NSArray *photos;
@property (nonatomic) NSUInteger index;

@property (strong, nonatomic) UIPopoverController *tagPopoverController;
@property (strong, nonatomic) UIPopoverController *mapPopoverController;

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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    
    UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Tag"] style:UIBarButtonItemStylePlain target:self action:@selector(tagBarButtonAction:)];
    tagBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Tag"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    UIBarButtonItem *pinBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PinIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(pinBarButtonAction:)];
    pinBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"PinIcon"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    self.navigationItem.rightBarButtonItems = @[pinBarButtonItem, tagBarButtonItem];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    UIBarButtonItem *organizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(organizeBarButtonAction:)];
    UIBarButtonItem *trashButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[actionBarButtonItem, flexibleSpace, organizeBarButtonItem, flexibleSpace];
    if (_isEnableDeletePhotoButton) {
        toolbarItems = [toolbarItems arrayByAddingObject:trashButtonItem];
    }
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setToolbarTintColor:[PAColors getColor:kPAColorsTypeTintLocalColor]];
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
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
    }];
}

- (void)organizeBarButtonAction:(id)sender {
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%ld Items", nil), 1];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Copy", nil), nil];
    actionSheet.tag = 1001;
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)copyPhoto {
    PLPhotoObject *photo = _photos[_index];
    __weak typeof(self) wself = self;
    PTAlbumPickerController *albumPickerController = [[PTAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (isWebAlbum) {
            [[PDTaskManager sharedManager] addTaskPhotos:@[photo] toWebAlbum:album completion:^(NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                    return;
                }
                [PAAlertControllerKit showDontRemoveThoseItemsUntilTheTaskIsFinished];
            }];
        }
        else {
            [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                PLAlbumObject *albumObject = (PLAlbumObject *)album;
                [albumObject addPhotosObject:photo];
            }];
        }
    }];
    
    albumPickerController.prompt = NSLocalizedString(@"Choose an album to copy to.", nil);
    [self.tabBarController presentViewController:albumPickerController animated:YES completion:nil];
}

- (void)tagBarButtonAction:(id)sender {
    PLPhotoObject *photo = _photos[_index];
    UIImage *screenshot = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        screenshot = [self.view screenCapture];
    }
    __weak typeof(self) wself = self;
    [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:photo.url] resultBlock:^(ALAsset *asset) {
        typeof(wself) sself = wself;
        if (!sself) return;
        NSDictionary *metadata = nil;
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            ALAssetRepresentation *representation = asset.defaultRepresentation;
            NSUInteger size = (NSUInteger)representation.size;
            uint8_t *buff = (uint8_t *)malloc(sizeof(uint8_t)*size);
            if(buff == nil){
                return ;
            }
            NSError *error = nil;
            NSUInteger bytesRead = [representation getBytes:buff fromOffset:0 length:size error:&error];
            if (bytesRead && !error) {
                NSData *photoData = [NSData dataWithBytesNoCopy:buff length:bytesRead freeWhenDone:YES];
                
                CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)photoData, nil);
                metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            PLPhotoEditViewController *viewController = [[PLPhotoEditViewController alloc] initWithPhoto:photo metadata:metadata backgroundScreenshot:screenshot];
            PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
            navigationController.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [sself presentViewController:navigationController animated:YES completion:nil];
            }
            else {
                navigationController.preferredContentSize = CGSizeMake(500.0f, 600.0f);
                sself.tagPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
                [sself.tagPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        });
    } failureBlock:^(NSError *error) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
    }];
}

- (void)pinBarButtonAction:(id)sender {
    PLPhotoObject *photo = _photos[_index];
    
    __weak typeof(self) wself = self;
    [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:photo.url] resultBlock:^(ALAsset *asset) {
        typeof(wself) sself = wself;
        if (!sself) return;
        UIImage *image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
        dispatch_async(dispatch_get_main_queue(), ^{
            PAMapViewController *viewController = [[PAMapViewController alloc] initWithImage:image latitude:photo.latitude.doubleValue longitude:photo.longitude.doubleValue];
            PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
            navigationController.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [sself presentViewController:navigationController animated:YES completion:nil];
            }
            else {
                navigationController.preferredContentSize = CGSizeMake(600.0f, 600.0f);
                sself.mapPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
                [sself.mapPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        });
    } failureBlock:^(NSError *error) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
    }];
}

- (void)trashBarButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Remove", nil) otherButtonTitles:nil];
    actionSheet.tag = 1002;
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

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
    
    PLPhotoObject *photo = _photos[index];
    PLPhotoViewController *viewController = [[PLPhotoViewController alloc] initWithPhoto:photo];
    NSString *title = [NSString stringWithFormat:@"%ld/%ld", (long)index + 1, (long)_photos.count];
    viewController.title = title;
    BOOL isGPSEnable = (photo.latitude.integerValue | photo.longitude.integerValue) != 0;
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
                sself.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
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

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == 1001) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Copy", nil)]) {
            [self copyPhoto];
        }
        else if (NSLocalizedString(@"Cancel", nil)) {
        }
    }
    else if (actionSheet.tag == 1002) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Remove", nil)]) {
            if (_deletePhotoButtonBlock) {
                _deletePhotoButtonBlock(_index);
            }
        }
        else if (NSLocalizedString(@"Cancel", nil)) {
        }
    }
}

@end
