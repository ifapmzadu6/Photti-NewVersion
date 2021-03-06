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
#import "PTAlbumPickerController.h"
#import "PAViewControllerKit.h"
#import "PAAlertControllerKit.h"
#import "PAPhotoKit.h"
#import "PWModelObject.h"

@interface PEPhotoListViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (nonatomic) kPHPhotoListViewControllerType type;
@property (strong, nonatomic) UIBarButtonItem *selectTrashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectUploadBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectActionBarButtonItem;
@property (weak, nonatomic) UIAlertAction *saveAlertAction;

@end

@implementation PEPhotoListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type {
    self = [self initWithAssetCollection:assetCollection type:type title:nil];
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type title:(NSString *)title {
    self = [self initWithAssetCollection:assetCollection type:type title:title startDate:nil endDate:nil];
    return self;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type title:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self = [self init];
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
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
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
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
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
            _photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
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
                    
                    if (sself.type == kPHPhotoListViewControllerType_Moment ||
                        sself.type == kPHPhotoListViewControllerType_Bursts ||
                        sself.type == kPHPhotoListViewControllerType_Dates ||
                        sself.type == kPHPhotoListViewControllerType_Favorite ||
                        sself.type == kPHPhotoListViewControllerType_iCloud ||
                        sself.type == kPHPhotoListViewControllerType_Panorama ||
                        sself.type == kPHPhotoListViewControllerType_SlomoVideo ||
                        sself.type == kPHPhotoListViewControllerType_Timelapse ||
                        sself.type == kPHPhotoListViewControllerType_Video) {
                        [sself.navigationController popViewControllerAnimated:YES];
                    }
                }
            });
        };
        _photoListDataSource.didChangeSelectedItemCountBlock = ^(NSUInteger count){
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.selectActionBarButtonItem.enabled = (count>0 && count<=5) ? YES : NO;
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
    
    NSString *selfClassString = NSStringFromClass([self class]);
    NSString *classString = NSStringFromClass([PEPhotoListViewController class]);
    if ([selfClassString isEqualToString:classString]) {
        if (_photoListDataSource.isSelectMode) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
        }
        else {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        }
        
        [_photoListDataSource selectAssets:nil animated:YES];
        _selectActionBarButtonItem.enabled = NO;
        _selectUploadBarButtonItem.enabled = NO;
        _selectTrashBarButtonItem.enabled = NO;
        
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
    [tabBarController setAdsHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
    [self showAlbumActionSheet:sender albumTitle:self.title];
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
    NSArray *selectedAssets = _photoListDataSource.selectedAssets;
    [self showUploadActionSheet:sender selectedAssets:selectedAssets];
}

- (void)selectTrashBarButtonAction:(id)sender {
    NSArray *deleteAssets = _photoListDataSource.selectedAssets;
    [self showDeleteActionSheet:sender selectedAssets:deleteAssets];
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
    _selectUploadBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(selectUploadBarButtonAction:)];
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
- (void)showAlbumActionSheet:(id)sender albumTitle:(NSString *)albumTitle {
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
            [PAAlertControllerKit showDontRemoveThoseItemsUntilTheTaskIsFinished];
        }];
    }];
    UIAlertAction *deleteAlertAction = nil;
    if (_type == kPHPhotoListViewControllerType_Album) {
        deleteAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [PAPhotoKit deleteAssetCollection:sself.photoListDataSource.assetCollection completion:^(BOOL success, NSError *error) {
                if (success && !error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sself.navigationController popViewControllerAnimated:YES];
                    });
                }
            }];
        }];
    }
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    NSString *title = [NSString stringWithFormat:@"\"%@\"", albumTitle];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
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

- (void)showUploadActionSheet:(id)sender selectedAssets:(NSArray *)selectedAssets {
    __weak typeof(self) wself = self;
    UIAlertAction *uploadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Copy", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself copyToAlbumAssets:selectedAssets];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%ld Items", nil), (long)selectedAssets.count];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alertController.popoverPresentationController.barButtonItem = sender;
    [alertController addAction:uploadAction];
    [alertController addAction:cancelAction];
    [self.tabBarController presentViewController:alertController animated:YES completion:nil];
}

- (void)showDeleteActionSheet:(id)sender selectedAssets:(NSArray *)selectedAssets {
    __weak typeof(self) wself = self;
    UIAlertAction *removeFromAlbumAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove From This Album", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself showDeleteSureActionSheet:sender selectedAssets:selectedAssets];
    }];
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove From Photo Library", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [PAPhotoKit deleteAssets:selectedAssets completion:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%ld Items", nil), (long)selectedAssets.count];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alertController.popoverPresentationController.barButtonItem = sender;
    PHAssetCollection *assetCollection = _photoListDataSource.assetCollection;
    if (assetCollection.assetCollectionType == PHAssetCollectionTypeAlbum) {
        [alertController addAction:removeFromAlbumAction];
    }
    [alertController addAction:removeAction];
    [alertController addAction:cancelAction];
    [self.tabBarController presentViewController:alertController animated:YES completion:nil];
}

- (void)showDeleteSureActionSheet:(id)sender selectedAssets:(NSArray *)selectedAssets {
    __weak typeof(self) wself = self;
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PHAssetCollection *assetCollection = sself.photoListDataSource.assetCollection;
        [PAPhotoKit deleteAssets:selectedAssets fromAssetCollection:assetCollection completion:^(BOOL success, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (success && !error) {
                sself.selectActionBarButtonItem.enabled = NO;
                sself.selectUploadBarButtonItem.enabled = NO;
                sself.selectTrashBarButtonItem.enabled = NO;
            }
        }];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    NSString *title = NSLocalizedString(@"Are you sure you want to remove these items? These items will be removed from this album, but will remain in your Photo Library.", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alertController.popoverPresentationController.barButtonItem = sender;
    [alertController addAction:deleteAction];
    [alertController addAction:cancelAction];
    [self.tabBarController presentViewController:alertController animated:YES completion:nil];
}

- (void)showImagePicker:(id)sender {
    __weak typeof(self) wself = self;
    PSImagePickerController *imagePickerController = [[PSImagePickerController alloc] initWithAlbumTitle:_photoListDataSource.assetCollection.localizedTitle completion:^(NSArray *selectedPhotos) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        BOOL isOnlyLocal = YES;
        for (id photo in selectedPhotos) {
            if ([photo isKindOfClass:[PWPhotoObject class]]) {
                isOnlyLocal = NO;
            }
        }
        
        [[PDTaskManager sharedManager] addTaskPhotos:selectedPhotos toAssetCollection:sself.photoListDataSource.assetCollection completion:^(NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
            }
            
            if (!isOnlyLocal) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A new task has been added.", nil) message:NSLocalizedString(@"Don't remove those items until the task is finished.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                });
            }
        }];
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
        [PEPhotoListViewController changeNameAssetCollection:assetCollection newName:newName completion:^(BOOL success, NSError *error) {
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
+ (void)changeNameAssetCollection:(PHAssetCollection *)assetCollection newName:(NSString *)newName completion:(void (^)(BOOL, NSError *))completion {
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

- (void)actionAssets:(NSArray *)assets {
    NSMutableArray *images = @[].mutableCopy;
    for (PHAsset *asset in assets) {
        if (asset.mediaType == PHAssetMediaTypeImage) {
            PHImageRequestOptions *options = [PHImageRequestOptions new];
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            options.synchronous = YES;
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                [images addObject:result];
            }];
        }
        else if (asset.mediaType == PHAssetMediaTypeVideo) {
            PHVideoRequestOptions *options = [PHVideoRequestOptions new];
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
                [images addObject:asset];
            }];
        }
    }
    
    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:images applicationActivities:nil];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

- (void)actionAssetCollection:(PHAssetCollection *)assetCollection {
    NSMutableArray *images = @[].mutableCopy;
    PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
    imageOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    imageOptions.networkAccessAllowed = YES;
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

- (void)copyToAlbumAssets:(NSArray *)assets {
    PTAlbumPickerController *viewController = [[PTAlbumPickerController alloc] initWithCompletion:^(id album, BOOL isWebAlbum) {
        if (isWebAlbum) {
            [[PDTaskManager sharedManager] addTaskPhotos:assets toWebAlbum:album completion:^(NSError *error) {
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
            PHAssetCollection *assetColection = (PHAssetCollection *)album;
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetColection];
                [changeRequest addAssets:assets];
            } completionHandler:nil];
        }
    }];
    viewController.prompt = NSLocalizedString(@"Choose an album to copy to.", nil);
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

@end
