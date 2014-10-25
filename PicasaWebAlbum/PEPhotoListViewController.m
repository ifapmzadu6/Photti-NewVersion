//
//  PHPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoListViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PATabBarAdsController.h"
#import "PEPhotoDataSourceFactoryMethod.h"
#import "PEPhotoListDataSource.h"
#import "PEPhotoPageViewController.h"
#import "PASearchNavigationController.h"
#import "PDTaskManager.h"
#import "PSImagePickerController.h"
#import "PAViewControllerKit.h"

@interface PEPhotoListViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (nonatomic) kPHPhotoListViewControllerType type;
@property (nonatomic) BOOL isSelectMode;
@property (strong, nonatomic) UIBarButtonItem *selectTrashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectUploadBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectActionBarButtonItem;
@property (weak, nonatomic) UIAlertAction *saveAlertAction;

@end

@implementation PEPhotoListViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type {
    self = [self initWithAssetCollection:assetCollection type:type title:nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type title:(NSString *)title {
    self = [self initWithAssetCollection:assetCollection type:type title:title startDate:nil endDate:nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type title:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self = [super init];
    if (self) {
        _type = type;
        
        if (title) {
            self.title = title;
        }
        else {
            if (type == kPHPhotoListViewControllerType_AllPhotos) {
                self.title = NSLocalizedString(@"All Items", nil);
            }
            else {
                self.title = assetCollection.localizedTitle;
            }
        }
        
        __weak typeof(self) wself = self;
        if (type == kPHPhotoListViewControllerType_AllPhotos) {
            _photoListDataSource = [PEPhotoDataSourceFactoryMethod makeAllPhotoListDataSource];
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (!isSelectMode) {
                    PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithResult:sself.photoListDataSource.fetchResult index:index ascending:sself.photoListDataSource.ascending];
                    [sself.navigationController pushViewController:viewController animated:YES];
                }
            };
        }
        else if (type == kPHPhotoListViewControllerType_Dates) {
            _photoListDataSource = [PEPhotoDataSourceFactoryMethod makePhotoListDataSourceWithStartDate:startDate endDate:endDate];
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (!isSelectMode) {
                    PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithResult:sself.photoListDataSource.fetchResult index:index];
                    [sself.navigationController pushViewController:viewController animated:YES];
                }
            };
        }
        else {
            _photoListDataSource = [PEPhotoDataSourceFactoryMethod makePhotoInAlbumListDataSourceWithCollection:assetCollection];
            BOOL isTypeFavorite = (type==kPHPhotoListViewControllerType_Favorite) ? YES : NO;
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (!isSelectMode) {
                    PEPhotoPageViewController *viewController = [[PEPhotoPageViewController alloc] initWithAssetCollection:sself.photoListDataSource.assetCollection index:index];
                    viewController.needsFavoriteChangedPopBack = isTypeFavorite;
                    [sself.navigationController pushViewController:viewController animated:YES];
                }
            };
        }
        if (type == kPHPhotoListViewControllerType_Panorama) {
            CGRect rect = [UIScreen mainScreen].bounds;
            CGFloat width = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect));
            CGFloat landscapeWidth = MAX(CGRectGetWidth(rect), CGRectGetHeight(rect));
            CGFloat height = (self.isPhone) ? 100.0f : 160.0f;
            _photoListDataSource.cellSize = CGSizeMake(width, height);
            _photoListDataSource.landscapeCellSize = CGSizeMake(landscapeWidth, height);
            _photoListDataSource.minimumLineSpacing = 15.0f;
        }
        else {
            _photoListDataSource.flowLayout = [PAPhotoCollectionViewFlowLayout new];
        }
        _photoListDataSource.cellBackgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
        _photoListDataSource.didChangeItemCountBlock = ^(NSUInteger count){
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (count == 0) {
                    [sself disableSelectMode];
                }
            });
        };
        _photoListDataSource.didChangeSelectedItemCountBlock = ^(NSUInteger count){
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.selectActionBarButtonItem.enabled = (count) ? YES : NO;
            sself.selectUploadBarButtonItem.enabled = (count) ? YES : NO;
            sself.selectTrashBarButtonItem.enabled = (count) ? YES : NO;
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *searchBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonAction)];
    self.navigationItem.rightBarButtonItems = @[searchBarButtonItem];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = _photoListDataSource;
    _collectionView.delegate = _photoListDataSource;
    _photoListDataSource.collectionView = _collectionView;
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    _collectionView.allowsMultipleSelection = YES;
    [self.view addSubview:_collectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_isSelectMode) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction:)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction:)];
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[actionBarButtonItem, flexibleSpace, selectBarButtonItem];
    if (_type == kPHPhotoListViewControllerType_Album) {
        toolbarItems = @[actionBarButtonItem, flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
    }
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        [tabBarController setToolbarTintColor:[PAColors getColor:kPAColorsTypeTintLocalColor]];
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
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = tabBarController.viewInsets;
    UIEdgeInsets contentInset = viewInsets;
    if (!self.isPhone) {
        contentInset = UIEdgeInsetsMake(viewInsets.top + 20.0f, 20.0f, viewInsets.bottom + 20.0f, 20.0f);
    }
    UIEdgeInsets scrollIndicatorInsets = viewInsets;
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
}

#pragma mark UIBarButtonAction
- (void)searchBarButtonAction {
    [self openSearchBar];
}

- (void)actionBarButtonAction:(id)sender {
    [self showSlbumActionSheet:sender albumTitle:self.title];
}

- (void)addBarButtonAction:(id)sender {
    [self showImagePicker:sender];
}

- (void)selectBarButtonAction:(id)sender {
    [self enableSelectMode];
}

- (void)selectActionBarButtonAction:(id)sender {
    NSArray *selectedAssets = _photoListDataSource.selectedAssets;
    [self actionAssets:selectedAssets];
}

- (void)selectUploadBarButtonAction:(id)sender {
}

- (void)selectTrashBarButtonAction:(id)sender {
    NSArray *deleteAssets = _photoListDataSource.selectedAssets;
    __weak typeof(self) wself = self;
    [self deleteAssets:deleteAssets completion:^(BOOL success, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (success && !error) {
            sself.selectActionBarButtonItem.enabled = NO;
            sself.selectUploadBarButtonItem.enabled = NO;
            sself.selectTrashBarButtonItem.enabled = NO;
        }
    }];
}

- (void)cancelBarButtonAction:(id)sender {
    [self disableSelectMode];
}

#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    _saveAlertAction.enabled = (text.length > 0) ? YES : NO;
    
    return YES;
}

#pragma mark SearchBar
- (void)openSearchBar {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setAdsHidden:YES animated:NO];
    
    PASearchNavigationController *navigationController = (PASearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

#pragma mark SelectMode
- (void)enableSelectMode {
    if (_photoListDataSource.isSelectMode) return;
    _photoListDataSource.isSelectMode = YES;
    
    _selectActionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction:)];
    _selectActionBarButtonItem.enabled = NO;
    _selectUploadBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"Upload"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStylePlain target:self action:@selector(selectUploadBarButtonAction:)];
    _selectUploadBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Upload"] insets:UIEdgeInsetsMake(3.0f, 3.0f, 3.0f, 3.0f)];
    _selectUploadBarButtonItem.enabled = NO;
    _selectTrashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(selectTrashBarButtonAction:)];
    _selectTrashBarButtonItem.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButtonItem, flexibleSpace, _selectUploadBarButtonItem, flexibleSpace, _selectTrashBarButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PAColors getColor:kPAColorsTypeTintLocalColor]];
    __weak typeof(self) wself = self;
    [tabBarController setActionToolbarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:YES animated:NO completion:nil];
    }];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction:)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Select items", nil)];
    [navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:NO];
    [tabBarController setActionNavigationItem:navigationItem animated:NO];
    [tabBarController setActionNavigationTintColor:[PAColors getColor:kPAColorsTypeTintLocalColor]];
    [tabBarController setActionNavigationBarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.navigationController.navigationBar.alpha = 0.0f;
    }];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)disableSelectMode {
    if (!_photoListDataSource.isSelectMode) return;
    _photoListDataSource.isSelectMode = NO;
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:NO animated:NO completion:nil];
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    self.navigationController.navigationBar.alpha = 1.0f;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark Album
- (void)showSlbumActionSheet:(id)sender albumTitle:(NSString *)albumTitle {
    __weak typeof(self) wself = self;
    UIAlertAction *editAlertAction = nil;
    if (_type == kPHPhotoListViewControllerType_Album) {
        editAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself editWithAssetCollection:sself.photoListDataSource.assetCollection];
        }];
    }
    UIAlertAction *shareAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Share", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *uploadAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Upload", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [[PDTaskManager sharedManager] addTaskFromAssetCollection:sself.photoListDataSource.assetCollection toWebAlbum:nil completion:^(NSError *error) {
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
    UIAlertAction *deleteAlertAction = nil;
    if (_type == kPHPhotoListViewControllerType_Album) {
        deleteAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself deleteAssetCollection:sself.photoListDataSource.assetCollection completion:^(BOOL success, NSError *error) {
                if (success && !error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sself.navigationController popViewControllerAnimated:YES];
                    });
                }
            }];
        }];
    }
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alertController.popoverPresentationController.barButtonItem = sender;
    if (editAlertAction) {
        [alertController addAction:editAlertAction];
    }
    [alertController addAction:shareAlertAction];
    [alertController addAction:uploadAlertAction];
    if (deleteAlertAction) {
        [alertController addAction:deleteAlertAction];
    }
    [alertController addAction:cancelAlertAction];
    [self.tabBarController presentViewController:alertController animated:YES completion:nil];
}

- (void)showImagePicker:(id)sender {
    __weak typeof(self) wself = self;
    PSImagePickerController *imagePickerController = [[PSImagePickerController alloc] initWithAlbumTitle:_photoListDataSource.assetCollection.localizedTitle completion:^(NSArray *selectedPhotos) {
        typeof(wself) sself = wself;
        if (!sself) return;
    }];
    [self.tabBarController presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)editWithAssetCollection:(PHAssetCollection *)assetCollection {
    NSString *title = NSLocalizedString(@"Album Title", nil);
    NSString *message = NSLocalizedString(@"Enter a name for this album.", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    __weak typeof(self) wself = self;
    _saveAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        UITextField *textFields = alertController.textFields.firstObject;
        NSString *newName = textFields.text;
        [sself changeNameAssetCollection:assetCollection newName:newName completion:^(BOOL success, NSError *error) {
            if (success && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    sself.title = newName;
                });
            }
        }];
    }];
    _saveAlertAction.enabled = NO;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        typeof(wself) sself = wself;
        if (!sself) return;
        textField.placeholder = NSLocalizedString(@"Title", nil);
        textField.delegate = sself;
    }];
    [alertController addAction:cancelAlertAction];
    [alertController addAction:_saveAlertAction];
    [self.tabBarController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark Photos
- (void)changeNameAssetCollection:(PHAssetCollection *)assetCollection newName:(NSString *)newName completion:(void (^)(BOOL, NSError *))completion {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        changeRequest.title = newName;
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    }];
}

- (void)deleteAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(BOOL, NSError *))completion {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest deleteAssetCollections:@[assetCollection]];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    }];
}

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

- (void)actionAssets:(NSArray *)assets {
    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:assets applicationActivities:nil];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

- (void)actionAssetCollection:(PHAssetCollection *)assetCollection {
    NSMutableArray *images = @[].mutableCopy;
    PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
    imageOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    imageOptions.synchronous = YES;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    for (PHAsset *asset in fetchResult) {
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeDefault options:imageOptions resultHandler:^(UIImage *result, NSDictionary *info) {
            [images addObject:result];
        }];
    }
    
    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:images applicationActivities:nil];
    viewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
    };
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

@end
