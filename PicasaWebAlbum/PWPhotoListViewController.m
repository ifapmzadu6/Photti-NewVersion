//
//  PWPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoListViewController.h"

#import "PAKit.h"
#import "PWPicasaAPI.h"
#import "PAColors.h"
#import "PAIcons.h"
#import "PAString.h"
#import "PASnowFlake.h"
#import "PWRefreshControl.h"
#import "PDTaskManager.h"
#import "PAAlertControllerKit.h"
#import <SDImageCache.h>
#import <Reachability.h>

#import "PRPhotoListDataSource.h"
#import "PLCollectionFooterView.h"
#import "PAPhotoCollectionViewFlowLayout.h"

#import "PAViewControllerKit.h"
#import "PATabBarAdsController.h"
#import "PWNavigationController.h"
#import "PWPhotoPageViewController.h"
#import "PABaseNavigationController.h"
#import "PWAlbumEditViewController.h"
#import "PWNewAlbumEditViewController.h"
#import "PWAlbumShareViewController.h"
#import "PSImagePickerController.h"
#import "PTAlbumPickerController.h"
#import "PAActivityIndicatorView.h"
#import "PAActivityIndicatorView.h"

static NSString * const kPWPhotoListViewControllerName = @"PWPLVCN";

@interface PWPhotoListViewController () <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) PWAlbumObject *album;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PWRefreshControl *refreshControl;
@property (strong, nonatomic) PAActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) PRPhotoListDataSource *photoListDataSource;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *organizeBarButtonItem;

@property (nonatomic) BOOL isRefreshControlAnimating;

@property (nonatomic) BOOL isActionLoadingCancel;
@property (nonatomic) NSUInteger actionLoadingVideoQuality;
@property (strong, nonatomic) id actionSheetItem;

@property (strong, nonatomic) NSCache *photoViewCache;

@end

@implementation PWPhotoListViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [self init];
    if (self) {
        _album = album;
        
        self.title = album.title;
        
        NSManagedObjectContext *context = [PWCoreDataAPI readContext];
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
        if (_album) {
            request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", _album.id_str];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        }
        else {
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO]];
        }
        
        _photoListDataSource = [[PRPhotoListDataSource alloc] initWithFetchRequest:request albumID:_album.id_str];
        __weak typeof(self) wself = self;
        _photoListDataSource.didChangeItemCountBlock = ^(NSUInteger count) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself refreshNoItemWithNumberOfItem:count];
        };
        _photoListDataSource.didRefresh = ^() {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself.refreshControl endRefreshing];
            [sself.activityIndicatorView stopAnimating];
        };
        _photoListDataSource.didChangeSelectedItemCountBlock = ^(NSUInteger count) {
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.selectActionBarButton.enabled = (count > 0) ? YES : NO;
            sself.trashBarButtonItem.enabled = (count > 0) ? YES : NO;
            sself.organizeBarButtonItem.enabled = (count > 0) ? YES : NO;
        };
        _photoListDataSource.didSelectPhotoBlock = ^(PWPhotoObject *photo, id placeholder, NSUInteger index) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PWPhotoPageViewController *viewController = [[PWPhotoPageViewController alloc] initWithPhotos:sself.photoListDataSource.photos index:index placeholder:placeholder cache:sself.photoViewCache];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _photoViewCache = [NSCache new];
        _photoViewCache.countLimit = 10;
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    self.navigationItem.rightBarButtonItem = searchBarButtonItem;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarTintColor:[PAColors getColor:kPAColorsTypeTintWebColor]];
    
    PAPhotoCollectionViewFlowLayout *collectionViewLayout = [PAPhotoCollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _photoListDataSource.collectionView = _collectionView;
    _collectionView.dataSource = _photoListDataSource;
    _collectionView.delegate = _photoListDataSource;
    _collectionView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.allowsMultipleSelection = YES;
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _refreshControl = [PWRefreshControl new];
    [_refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    _refreshControl.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
    _refreshControl.myContentInsetTop = _collectionView.contentInset.top;
    [_collectionView addSubview:_refreshControl];
    
    _activityIndicatorView = [PAActivityIndicatorView new];
    [self.view addSubview:_activityIndicatorView];
    
    if (_photoListDataSource.numberOfPhotos == 0) {
        [_activityIndicatorView startAnimating];
    }
    
    [self refreshNoItemWithNumberOfItem:_photoListDataSource.numberOfPhotos];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _isRefreshControlAnimating = _refreshControl.isRefreshing;
    if (_refreshControl.isRefreshing) {
        [_refreshControl endRefreshing];
    }
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    UIEdgeInsets contentInset = UIEdgeInsetsZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    }
    else {
        contentInset = UIEdgeInsetsMake(viewInsets.top + 20.0f, 20.0f, viewInsets.bottom + 20.0f, 20.0f);
    }
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
    
    _activityIndicatorView.center = self.view.center;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_photoListDataSource.isRequesting && _isRefreshControlAnimating) {
        [_refreshControl beginRefreshing];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_photoListDataSource.isSelectMode) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction:)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    [tabBarController setToolbarTintColor:[PAColors getColor:kPAColorsTypeTintWebColor]];
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        __weak typeof(self) wself = self;
        [tabBarController setToolbarHidden:NO animated:animated completion:^(BOOL finished) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
            [tabBarController setTabBarHidden:YES animated:NO completion:nil];
        }];
    }
    else {
        [tabBarController setToolbarItems:toolbarItems animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    [tabBarController setAdsHidden:NO animated:YES];
    
    [_collectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark UIBarButtonAction
- (void)searchBarButtonAction {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:YES animated:NO];
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

- (void)actionBarButtonAction:(id)sender {
    [self showAlbumActionSheet:_album sender:sender];
}

- (void)addBarButtonAction {
    __weak typeof(self) wself = self;
    PSImagePickerController *viewController = [[PSImagePickerController alloc] initWithAlbumTitle:_album.title completion:^(NSArray *selectedPhotos) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toWebAlbum:sself.album completion:^(NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            });
        }];
    }];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)selectBarButtonAction {
    [self enableSelectMode];
}

- (void)cancelBarButtonAction {
    [self disableSelectMode];
}

- (void)selectActionBarButtonAction {
    NSArray *selectedPhotos = _photoListDataSource.selectedPhotos;
    NSArray *videos = [selectedPhotos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(kPWPhotoObjectTypeVideo)]];
    if (selectedPhotos.count == 0) return;
    BOOL isContainVideo = (videos.count > 0) ? YES : NO;
    
    _isActionLoadingCancel = NO;
    _actionLoadingVideoQuality = 0;
    
    if (isContainVideo) {
        NSString *title = NSLocalizedString(@"Choose a video quality to share (If don't match, choose a highest quality video that is smaller than you have chosen.)", nil);
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"1080", @"720", @"480", @"360", @"240", nil];
        actionSheet.tag = 1001;
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
    else {
        [self loadAndSavePhotos];
    }
}

- (void)loadAndSavePhotos {
    NSArray *selectedPhotos = _photoListDataSource.selectedPhotos;
    if (selectedPhotos.count == 0) return;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading...", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
    PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    alertView.tag = 100;
    [alertView show];
    
    __weak typeof(self) wself = self;
    [self loadAndSaveWithPhotos:selectedPhotos.mutableCopy savedLocations:@[].mutableCopy alertView:alertView completion:^(NSArray *savedLocations) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.isActionLoadingCancel) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:savedLocations applicationActivities:nil];
            [sself.tabBarController presentViewController:viewController animated:YES completion:nil];
            
            [sself disableSelectMode];
        });
    }];
}

- (void)loadAndSaveWithPhotos:(NSMutableArray *)photos  savedLocations:(NSMutableArray *)savedLocations alertView:(UIAlertView *)alertView completion:(void (^)(NSArray *savedLocations))completion {
    if (self.isActionLoadingCancel) {
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"Loading...(%ld/%ld)", (long)savedLocations.count+1, (long)(photos.count + savedLocations.count)];
    dispatch_async(dispatch_get_main_queue(), ^{
        alertView.title = title;
    });
    PWPhotoObject *photo = photos.firstObject;
    NSURL *url = nil;
    if (photo.tag_type.integerValue == kPWPhotoObjectTypePhoto) {
        url = [NSURL URLWithString:photo.tag_originalimage_url];
    }
    else if (photo.tag_type.integerValue == kPWPhotoObjectTypeVideo) {
        for (PWPhotoMediaContentObject *content in photo.media.content.reversedOrderedSet) {
            if ([content.type isEqualToString:@"video/mpeg4"]) {
                NSUInteger quality = content.width.unsignedIntegerValue > content.height.unsignedIntegerValue ? content.width.unsignedIntegerValue : content.height.unsignedIntegerValue;
                if (quality <= _actionLoadingVideoQuality) {
                    url = [NSURL URLWithString:content.url];
                    break;
                }
            }
        }
    }
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        [[[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (!error) {
                NSString *filePath = nil;
                if (photo.tag_type.integerValue == kPWPhotoObjectTypePhoto) {
                    filePath = [[PAKit makeUniquePathInTmpDir] stringByAppendingPathExtension:@"jpg"];
                }
                else {
                    filePath = [[PAKit makeUniquePathInTmpDir] stringByAppendingPathExtension:@"mp4"];
                }
                NSURL *filePathURL = [NSURL fileURLWithPath:filePath];
                NSError *fileManagerError = nil;
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:filePathURL error:&fileManagerError];
                
                [savedLocations addObject:filePathURL];
            }
            
            [photos removeObject:photo];
            if (photos.count > 0) {
                [sself loadAndSaveWithPhotos:photos savedLocations:savedLocations alertView:alertView completion:completion];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alertView dismissWithClickedButtonIndex:0 animated:YES];
                });
                
                if (completion) {
                    completion(savedLocations.copy);
                }
            }
        }] resume];
    }];
}

- (void)trashBarButtonAction:(id)sender {
    [self showTrashPhotosActionSheet:sender];
}

- (void)organizeBarButtonAction:(id)sender {
    __weak typeof(self) wself = self;
    NSArray *selectedPhotos = _photoListDataSource.selectedPhotos;
    [PWPhotoObject getCountFromPhotoObjects:selectedPhotos completion:^(NSUInteger countOfPhoto, NSUInteger countOfVideo) {
        typeof(wself) sself = wself;
        if (!sself) return;
        NSString *title = [PAString photoAndVideoStringWithPhotoCount:countOfPhoto videoCount:countOfVideo];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Copy", nil), nil];
        actionSheet.tag = 1002;
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }];
}

- (void)copyPhoto {
    __weak typeof(self) wself = self;
    PTAlbumPickerController *albumPickerController = [[PTAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSMutableArray *selectedPhotos = @[].mutableCopy;
        NSArray *photos = sself.photoListDataSource.photos;
        for (NSString *id_str in sself.photoListDataSource.selectedPhotoIDs) {
            NSArray *searched = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
            if (searched.count > 0) {
                [selectedPhotos addObject:searched.firstObject];
            }
        }
        if (selectedPhotos.count == 0) return;
        
        if (isWebAlbum) {
            PWAlbumObject *webAlbum = (PWAlbumObject *)album;
            
            [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toWebAlbum:webAlbum completion:^(NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            }];
        }
        else {
            PLAlbumObject *localAlbum = (PLAlbumObject *)album;
            [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toLocalAlbum:localAlbum completion:^(NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            }];
        }
        
        [sself disableSelectMode];
    }];
    albumPickerController.prompt = NSLocalizedString(@"Choose an album to copy to.", nil);
    [self.tabBarController presentViewController:albumPickerController animated:YES completion:nil];
}

#pragma mark UIRefreshControl
- (void)refreshControlAction {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [PAAlertControllerKit showNotCollectedToNetwork];
        return;
    }
    
    [_photoListDataSource loadDataWithStartIndex:0];
}

#pragma mark SelectMode
- (void)enableSelectMode {
    if (_photoListDataSource.isSelectMode) {
        return;
    }
    _photoListDataSource.isSelectMode = YES;
    
    _selectActionBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction)];
    _selectActionBarButton.enabled = NO;
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonAction:)];
    _trashBarButtonItem.enabled = NO;
    _organizeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(organizeBarButtonAction:)];
    _organizeBarButtonItem.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButton, flexibleSpace, _organizeBarButtonItem, flexibleSpace, _trashBarButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PAColors getColor:kPAColorsTypeTintWebColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Select items", nil)];
    [navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:NO];
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationTintColor:[PAColors getColor:kPAColorsTypeTintWebColor]];
    [tabBarController setActionNavigationBarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.navigationController.navigationBar.alpha = 0.0f;
    }];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)disableSelectMode {
    if (!_photoListDataSource.isSelectMode) {
        return;
    }
    _photoListDataSource.isSelectMode = NO;
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:NO animated:NO completion:nil];
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    self.navigationController.navigationBar.alpha = 1.0f;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark UIActionSheet
- (void)showAlbumActionSheet:(PWAlbumObject *)album sender:(id)sender {
    _actionSheetItem = album;
    
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        __weak typeof(self) wself = self;
        UIAlertAction *editAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself editActionSheetAction:album];
        }];
        UIAlertAction *shareAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Share", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself shareActionSheetAction:album];
        }];
        UIAlertAction *downloadAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Download", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself downloadActionSheetAction:album];
        }];
        UIAlertAction *deleteAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself deleteActionSheetAction:album];
        }];
        UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:album.title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        alertController.popoverPresentationController.barButtonItem = sender;
        [alertController addAction:editAlertAction];
        [alertController addAction:shareAlertAction];
        [alertController addAction:downloadAlertAction];
        [alertController addAction:deleteAlertAction];
        [alertController addAction:cancelAlertAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:album.title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:NSLocalizedString(@"Edit", nil), NSLocalizedString(@"Share", nil), NSLocalizedString(@"Download", nil), nil];
        actionSheet.tag = 1003;
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }
}

- (void)editActionSheetAction:(PWAlbumObject *)album {
    PWAlbumEditViewController *viewController = [[PWAlbumEditViewController alloc] initWithAlbum:album];
    __weak typeof(self) wself = self;
    viewController.successBlock = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself.photoListDataSource loadDataWithStartIndex:0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.navigationItem.title = album.title;
        });
    };
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    if (self.isPhone) {
        navigationController.transitioningDelegate = (id)navigationController;
    }
    else {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)shareActionSheetAction:(PWAlbumObject *)album {
    PWAlbumShareViewController *viewController = [[PWAlbumShareViewController alloc] initWithAlbum:album];
    __weak typeof(self) wself = self;
    viewController.changedAlbumBlock = ^() {
        typeof(wself) sself = wself;
        if (!sself) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_collectionView reloadItemsAtIndexPaths:_collectionView.indexPathsForVisibleItems];
        });
    };
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    if (self.isPhone) {
        navigationController.transitioningDelegate = (id)navigationController;
    }
    else {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)downloadActionSheetAction:(PWAlbumObject *)album {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [PAAlertControllerKit showNotCollectedToNetwork];
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading...", nil) message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
    PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView show];
    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:album.id_str index:0 completion:^(NSUInteger nextIndex, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        
        [[PDTaskManager sharedManager] addTaskFromWebAlbum:album toLocalAlbum:nil completion:^(NSError *error) {
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
    }];
}

- (void)deleteActionSheetAction:(PWAlbumObject *)album {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [PAAlertControllerKit showNotCollectedToNetwork];
        return;
    }
    
    _actionSheetItem = album;
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), album.title];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    actionSheet.tag = 1004;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark Trash
- (void)showTrashPhotosActionSheet:(id)sender {
    __weak typeof(self) wself = self;
    NSArray *selectedPhotos = _photoListDataSource.selectedPhotos;
    [PWPhotoObject getCountFromPhotoObjects:selectedPhotos completion:^(NSUInteger countOfPhoto, NSUInteger countOfVideo) {
        typeof(wself) sself = wself;
        if (!sself) return;
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete %@?", nil), [PAString photoAndVideoStringWithPhotoCount:countOfPhoto videoCount:countOfVideo]];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:sself cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
        actionSheet.tag = 1005;
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }];
}

#pragma mark Download
- (void)downloadOriginalFile:(NSString *)url completion:(void (^)(NSString *filepath, NSError *error))completion {
    if (!completion) return;
    
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:url] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            return;
        }
        
        [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                return;
            }
            
            NSString *filePath = [PAKit makeUniquePathInTmpDir];
            [data writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error];
            
            completion(filePath, error);
        }];
    }];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == 1001) {
        if (![buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
            _actionLoadingVideoQuality = buttonTitle.integerValue;
            [self loadAndSavePhotos];
        }
        else  {
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
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Edit", nil)]) {
            [self editActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Share", nil)]) {
            [self shareActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Download", nil)]) {
            [self downloadActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            [self deleteActionSheetAction:_actionSheetItem];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1004) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
            indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            
            PWAlbumObject *album = _actionSheetItem;
            NSManagedObjectID *albumObjectID = album.objectID;
            __weak typeof(self) wself = self;
            [PWPicasaAPI deleteAlbum:album completion:^(NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
                [PWCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                    PWAlbumObject *albumObject = (PWAlbumObject *)[context objectWithID:albumObjectID];
                    [context deleteObject:albumObject];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alertView dismissWithClickedButtonIndex:0 animated:YES];
                        [sself.navigationController popViewControllerAnimated:YES];
                    });
                }];
            }];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1005) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Deleting...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
            indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
            [indicator startAnimating];
            [alertView setValue:indicator forKey:@"accessoryView"];
            [alertView show];
            
            NSArray *selectedPhotos = _photoListDataSource.selectedPhotos;
            __block NSUInteger maxCount = selectedPhotos.count;
            __block NSUInteger count = 0;
            for (PWPhotoObject *photo in selectedPhotos) {
                __weak typeof(self) wself = self;
                [PWPicasaAPI deletePhoto:photo completion:^(NSError *error) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (error) {
#ifdef DEBUG
                        NSLog(@"%@", error);
#endif
                        maxCount--;
                        return;
                    }
                    
                    count++;
                    if (count == maxCount) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [alertView dismissWithClickedButtonIndex:0 animated:YES];
                            [sself.photoListDataSource loadDataWithStartIndex:0];
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            alertView.title = [NSString stringWithFormat:@"%@(%ld/%ld)", NSLocalizedString(@"Deleting...", nil), (long)count + 1, (long)maxCount];
                        });
                    }
                }];
            }
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) {
        if (alertView.cancelButtonIndex == buttonIndex) {
            _isActionLoadingCancel = YES;
        }
    }
}

@end
