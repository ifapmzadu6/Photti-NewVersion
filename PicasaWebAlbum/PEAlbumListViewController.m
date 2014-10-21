//
//  PHAlbumViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEAlbumListViewController.h"

@import Photos;

#import "PAColors.h"
#import "PAIcons.h"
#import "PEPhotoViewCell.h"
#import "PEAlbumListDataSource.h"
#import "PAViewControllerKit.h"
#import "PATabBarAdsController.h"
#import "PEPhotoListViewController.h"
#import "PWSearchNavigationController.h"
#import "PAAlbumCollectionViewFlowLayout.h"

@interface PEAlbumListViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) PEAlbumListDataSource *albumListDataSource;

@property (strong, nonatomic) UIBarButtonItem *selectTrashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectUploadBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectActionBarButtonItem;
@property (weak, nonatomic) UIAlertAction *saveAlertAction;

@end

@implementation PEAlbumListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Albums", nil);
        
        _albumListDataSource = [PEAlbumListDataSource new];
        _albumListDataSource.flowLayout = [PAAlbumCollectionViewFlowLayout new];
        _albumListDataSource.cellBackgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
        __weak typeof(self) wself = self;
        _albumListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection){
            typeof(wself) sself = wself;
            if (!sself) return;
            PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album];
            [sself.navigationController pushViewController:viewController animated:YES];
        };
        _albumListDataSource.didChangeSelectedItemCountBlock = ^(NSUInteger count){
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
    _collectionView.dataSource = _albumListDataSource;
    _collectionView.delegate = _albumListDataSource;
    _albumListDataSource.collectionView = _collectionView;
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    _collectionView.allowsMultipleSelection = YES;
    [self.view addSubview:_collectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_albumListDataSource.isSelectMode) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        
        for (NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems) {
            [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
    
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[flexibleSpace, addBarButtonItem, flexibleSpace];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
    if ([tabBarController isToolbarHideen]) {
        [tabBarController setToolbarItems:toolbarItems animated:NO];
        [tabBarController setToolbarTintColor:[PAColors getColor:PAColorsTypeTintLocalColor]];
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
    [tabBarController setAdsHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:YES];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = tabBarController.viewInsets;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(viewInsets.top + 15.0f, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    UIEdgeInsets scrollIndicatorInsets = viewInsets;
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
}

#pragma mark UIBarButtonAction
- (void)searchBarButtonAction {
    [self openSearchBar];
}

- (void)addBarButtonAction:(id)sender {
    NSString *title = NSLocalizedString(@"New Album", nil);
    NSString *message = NSLocalizedString(@"Enter a name for this album.", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    __weak typeof(self) wself = self;
    _saveAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        UITextField *textFields = alertController.textFields.firstObject;
        [sself makeNewAlbumWithTitle:textFields.text];
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
    
    PWSearchNavigationController *navigationController = (PWSearchNavigationController *)self.navigationController;
    navigationController.view.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
    __weak typeof(self) wself = self;
    [navigationController openSearchBarWithCancelBlock:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        [tabBarController setToolbarHidden:NO animated:NO completion:nil];
        [tabBarController setAdsHidden:NO animated:YES];
    }];
}

#pragma mark Photos
- (void)makeNewAlbumWithTitle:(NSString *)title {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
    } completionHandler:^(BOOL success, NSError *error) {
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }
    }];
}

@end
