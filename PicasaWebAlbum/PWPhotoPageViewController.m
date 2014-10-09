//
//  PWPhotoPageViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import AVFoundation;
@import MapKit;

#import "PWPhotoPageViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PWPicasaAPI.h"
#import "PWPhotoViewController.h"
#import "PATabBarAdsController.h"
#import <Reachability.h>
#import <SDImageCache.h>
#import "PABaseNavigationController.h"
#import "PWPhotoEditViewController.h"
#import "PWMapViewController.h"
#import "PWAlbumPickerController.h"
#import "PDTaskManager.h"
#import "UIView+ScreenCapture.h"

@interface PWPhotoPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSArray *photos;

@property (nonatomic) NSUInteger index;
@property (nonatomic) NSString *id_str;

@property (weak, nonatomic) NSCache *photoViewCache;

@property (weak, nonatomic) NSURLSessionDataTask *sessionDataTask;

@end

@implementation PWPhotoPageViewController

- (id)initWithPhotos:(NSArray *)photos index:(NSUInteger)index placeholder:(id)placeholder cache:(NSCache *)cache {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(40.0f), UIPageViewControllerOptionInterPageSpacingKey, nil];
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    if (self) {
        _photos = photos;
        _index = index;
        
        _photoViewCache = cache;
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        self.delegate = self;
        self.dataSource = self;
        [self setViewControllers:@[[self makePhotoViewController:index placeholder:placeholder]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //ScrollViewDelegate
    [self.view.subviews.firstObject setDelegate:(id)self];
    
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
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction:)];
    UIBarButtonItem *organizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(organizeBarButtonAction:)];
    UIBarButtonItem *trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [tabBarController setToolbarItems:@[actionBarButtonItem, flexibleSpace, organizeBarButtonItem, flexibleSpace, trashBarButtonItem] animated:YES];
    [tabBarController setAdsHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark UIBarButtonItemAction
- (void)actionBarButtonAction:(id)sender {
    PWPhotoObject *photo = _photos[_index];
    if (photo.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
        PWPhotoMediaContentObject *content = photo.media.content.firstObject;
        NSString *urlString = content.url;
        UIImage *cachedImage = [_photoViewCache objectForKey:urlString];
        if (cachedImage) {
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[cachedImage] applicationActivities:nil];
            [self presentViewController:activityViewController animated:YES completion:nil];
        }
        else {
            if (![Reachability reachabilityForInternetConnection].isReachable) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not connected to network", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [alertView show];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [alertView dismissWithClickedButtonIndex:0 animated:YES];
                });
                return;
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading...", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
            alertView.tag = 2001;
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            __weak typeof(self) wself = self;
            [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alertView dismissWithClickedButtonIndex:NSIntegerMax animated:YES];
                    });
                    return;
                };
                
                NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alertView dismissWithClickedButtonIndex:NSIntegerMax animated:YES];
                    });
                    if (error) return;
                    UIImage *image = [UIImage imageWithData:data];
                    if (!image) return;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        typeof(wself) sself = wself;
                        if (!sself) return;
                        
                        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
                        [sself presentViewController:activityViewController animated:YES completion:nil];
                    });
                }];
                [task resume];
                sself.sessionDataTask = task;
            }];
        }
    }
    else if (photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
        UIActionSheet *actionSheet = [UIActionSheet new];
        actionSheet.delegate = self;
        actionSheet.tag = 1001;
        actionSheet.title = NSLocalizedString(@"Choose a video quality to share", nil);
        for (PWPhotoMediaContentObject *content in photo.media.content.reversedOrderedSet) {
            if ([content.type isEqualToString:@"video/mpeg4"]) {
                NSString *title = nil;
                if (content.width.integerValue > content.height.integerValue) {
                    title = [NSString stringWithFormat:@"%@P", content.width];
                }
                else {
                    title = [NSString stringWithFormat:@"%@P", content.height];
                }
                [actionSheet addButtonWithTitle:title];
            }
        }
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }
}

- (void)organizeBarButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Copy", nil), nil];
    actionSheet.tag = 1002;
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)trashBarButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    actionSheet.tag = 1003;
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)tagBarButtonAction {
    UIImage *screenshot = [self.view screenCapture];
    PWPhotoEditViewController *viewController = [[PWPhotoEditViewController alloc] initWithPhoto:_photos[_index] backgroundScreenshot:screenshot];
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)pinBarButtonAction {
    PWPhotoObject *photo = _photos[_index];
    NSArray *strings = [photo.pos componentsSeparatedByString:@" "];
    NSString *latitude = strings.firstObject;
    NSString *longitude = strings.lastObject;
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:photo.tag_thumbnail_url];
    PWMapViewController *viewController = [[PWMapViewController alloc] initWithImage:image latitude:latitude.doubleValue longitude:longitude.doubleValue];
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark Methods
- (void)changePhotos:(NSArray *)photos {
    _photos = photos;
    
    NSArray *filteredPhotos = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", _id_str]];
    if (filteredPhotos.count) {
        PWPhotoObject *newPhoto = filteredPhotos.firstObject;
        NSUInteger newIndex = [photos indexOfObject:newPhoto];
        [self setViewControllers:@[[self makePhotoViewController:newIndex placeholder:nil]]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:nil];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)copyPhoto {
    PWPhotoObject *photo = _photos[_index];
    __weak typeof(self) wself = self;
    PWAlbumPickerController *albumPickerController = [[PWAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            }];
        }
        else {
            [[PDTaskManager sharedManager] addTaskPhotos:@[photo] toLocalAlbum:album completion:^(NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            }];
        }
    }];
    albumPickerController.prompt = NSLocalizedString(@"Choose an album to copy to.", nil);
    [self.tabBarController presentViewController:albumPickerController animated:YES completion:nil];
}

- (void)deletePhoto {
    PWPhotoObject *photo = _photos[_index];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    [alertView show];
    __weak typeof(self) wself = self;
    [PWPicasaAPI deletePhoto:photo completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
                [alertView dismissWithClickedButtonIndex:0 animated:YES];
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                return;
            }
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
            
            [sself.navigationController popViewControllerAnimated:YES];
        });
    }];
}

#pragma mark UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    PWPhotoViewController *photoViewController = (PWPhotoViewController *)viewController;
    NSInteger index = [_photos indexOfObject:photoViewController.photo];
    return [self makePhotoViewController:index - 1 placeholder:nil];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    PWPhotoViewController *photoViewController = (PWPhotoViewController *)viewController;
    NSInteger index = [_photos indexOfObject:photoViewController.photo];
    return [self makePhotoViewController:index + 1 placeholder:nil];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark PWPhotoViewController
- (UIViewController *)makePhotoViewController:(NSInteger)index placeholder:(id)placeholder {
    if (index < 0 || index == _photos.count) {
        return nil;
    }
    
    PWPhotoObject *photo = _photos[index];
    PWPhotoViewController *viewController = [[PWPhotoViewController alloc] initWithPhoto:photo placeholder:placeholder cache:_photoViewCache];
    NSString *title = [NSString stringWithFormat:@"%ld/%ld", (long)index + 1, (long)_photos.count];
    viewController.title = title;
    NSString *id_str = photo.id_str;
    BOOL isGPSEnable = (photo.pos != nil);
    __weak typeof(self) wself = self;
    viewController.viewDidAppearBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.title = title;
        sself.index = index;
        sself.id_str = id_str;
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
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            [sself.navigationController setNavigationBarHidden:NO animated:YES];
            [tabBarController setToolbarFadeout:NO animated:YES completion:nil];
            [UIView animateWithDuration:0.25f animations:^{
                sself.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
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

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == 1001) {
        if (![buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
            PWPhotoObject *photo = _photos[_index];
            for (PWPhotoMediaContentObject *content in photo.media.content.reversedOrderedSet) {
                if ([content.type isEqualToString:@"video/mpeg4"]) {
                    NSString *title = nil;
                    if (content.width.integerValue < content.height.integerValue) {
                        title = [NSString stringWithFormat:@"%@P", content.width];
                    }
                    else {
                        title = [NSString stringWithFormat:@"%@P", content.height];
                    }
                    
                    if ([buttonTitle isEqualToString:title]) {
                        NSString *urlString = content.url;
                        
                        [self actionWithURLString:urlString];
                    }
                }
            }
        }
        else {
        }
    }
    else if (actionSheet.tag == 1002) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Copy", nil)]) {
            [self copyPhoto];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1003) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            [self deletePhoto];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
}

- (void)actionWithURLString:(NSString *)urlString {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading...", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
    alertView.tag = 2002;
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    [alertView show];
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView dismissWithClickedButtonIndex:NSIntegerMax animated:YES];
            });
            return;
        };
        
        NSURLSessionDataTask *task = (NSURLSessionDataTask *)[[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView dismissWithClickedButtonIndex:NSIntegerMax animated:YES];
            });
            if (error) return;
            
            AVAsset *asset = [AVAsset assetWithURL:location];
            if (!asset) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[asset] applicationActivities:nil];
                [sself presentViewController:activityViewController animated:YES completion:nil];
            });
        }];
        [task resume];
        sself.sessionDataTask = task;
    }];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView.tag == 2001) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
            NSURLSessionDataTask *task = _sessionDataTask;
            if (task) {
                [task cancel];
            }
        }
    }
    else if (alertView.tag == 2002) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
            NSURLSessionDataTask *task = _sessionDataTask;
            if (task) {
                [task cancel];
            }
        }
    }
}

@end
