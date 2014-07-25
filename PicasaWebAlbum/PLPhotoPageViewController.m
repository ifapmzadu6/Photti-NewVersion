//
//  PLPhotoPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import ImageIO;

#import "PLPhotoPageViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PWTabBarController.h"
#import "PLPhotoViewController.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PWBaseNavigationController.h"
#import "PWMapViewController.h"
#import "PLPhotoEditViewController.h"
#import "PWAlbumPickerController.h"
#import "PLCoreDataAPI.h"
#import "PDTaskManager.h"

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
    
    UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Tag"] style:UIBarButtonItemStylePlain target:self action:@selector(tagBarButtonAction)];
    tagBarButtonItem.landscapeImagePhone = [PWIcons imageWithImage:[UIImage imageNamed:@"Tag"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    UIBarButtonItem *pinBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PinIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(pinBarButtonAction)];
    pinBarButtonItem.landscapeImagePhone = [PWIcons imageWithImage:[UIImage imageNamed:@"PinIcon"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    self.navigationItem.rightBarButtonItems = @[pinBarButtonItem, tagBarButtonItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction)];
    UIBarButtonItem *copyBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PWIcons imageWithText:NSLocalizedString(@"Copy", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(copyBarButtonAction)];
//    UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[actionBarButtonItem, flexibleSpace, copyBarButtonItem, flexibleSpace];
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

- (void)copyBarButtonAction {
    PLPhotoObject *photo = _photos[_index];
    
    __weak typeof(self) wself = self;
    PWAlbumPickerController *albumPickerController = [[PWAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (isWebAlbum) {
            [[PDTaskManager sharedManager] addTaskPhotos:@[photo] toWebAlbum:album completion:^(NSError *error) {
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A New task has been added.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
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

- (void)tagBarButtonAction {
    PLPhotoObject *photo = _photos[_index];
    
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
            PLPhotoEditViewController *viewController = [[PLPhotoEditViewController alloc] initWithPhoto:photo metadata:metadata];
            PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
            navigationController.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
            navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [sself presentViewController:navigationController animated:YES completion:nil];
        });
    } failureBlock:^(NSError *error) {
        
    }];
}

- (void)pinBarButtonAction {
    PLPhotoObject *photo = _photos[_index];
    
    __weak typeof(self) wself = self;
    [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:photo.url] resultBlock:^(ALAsset *asset) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        UIImage *image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            PWMapViewController *viewController = [[PWMapViewController alloc] initWithImage:image latitude:photo.latitude.doubleValue longitude:photo.longitude.doubleValue];
            PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
            navigationController.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
            navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [sself presentViewController:navigationController animated:YES completion:nil];
        });
    } failureBlock:^(NSError *error) {
        
    }];
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
