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
#import "PATabBarAdsController.h"
#import "PEPhotoListViewController.h"

@interface PEAlbumListViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) PEAlbumListDataSource *albumListDataSource;

@property (strong, nonatomic) UIBarButtonItem *selectTrashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *selectActionBarButtonItem;
@property (weak, nonatomic) UIAlertAction *saveAlertAction;

@end

@implementation PEAlbumListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Albums", nil);
        
        _albumListDataSource = [PEAlbumListDataSource new];
        _albumListDataSource.cellSize = CGSizeMake(90.0f, 120.0f);
        _albumListDataSource.cellBackgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
        _albumListDataSource.minimumLineSpacing = 15.0f;
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
            sself.selectTrashBarButtonItem.enabled = (count) ? YES : NO;
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = _albumListDataSource;
    _collectionView.delegate = _albumListDataSource;
    [_albumListDataSource prepareForUse:_collectionView];
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
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems =  @[flexibleSpace, addBarButtonItem, flexibleSpace, selectBarButtonItem];
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
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 15.0f, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    _collectionView.scrollIndicatorInsets = viewInsets;
    _collectionView.frame = rect;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)addBarButtonAction:(id)sender {
    NSString *title = NSLocalizedString(@"New Album", nil);
    NSString *message = NSLocalizedString(@"Enter a name for this album.", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Title", nil);
        textField.delegate = self;
    }];
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAlertAction];
    __weak typeof(self) wself = self;
    _saveAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(wself) sself = wself;
        if (!sself) return;
        UITextField *textFields = alertController.textFields.firstObject;
        [sself makeNewAlbumWithTitle:textFields.text];
    }];
    _saveAlertAction.enabled = NO;
    [alertController addAction:_saveAlertAction];
    
    [self.tabBarController presentViewController:alertController animated:YES completion:nil];
}

- (void)selectBarButtonAction:(id)sender {
    [self enableSelectMode];
}

- (void)selectActionBarButtonAction:(id)sender {
    
}

- (void)selectTrashBarButtonAction:(id)sender {
    NSArray *selectAssetCollections = _albumListDataSource.selectedCollections;
    [self deleteAssetCollections:selectAssetCollections];
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

#pragma mark SelectMode
- (void)enableSelectMode {
    if (_albumListDataSource.isSelectMode) {
        return;
    }
    _albumListDataSource.isSelectMode = YES;
    
    _selectActionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectActionBarButtonAction:)];
    _selectActionBarButtonItem.enabled = NO;
    _selectTrashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(selectTrashBarButtonAction:)];
    _selectTrashBarButtonItem.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *toolbarItems = @[_selectActionBarButtonItem, flexibleSpace, _selectTrashBarButtonItem];
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setActionToolbarItems:toolbarItems animated:NO];
    [tabBarController setActionToolbarTintColor:[PAColors getColor:PAColorsTypeTintWebColor]];
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
    [tabBarController setActionNavigationTintColor:[PAColors getColor:PAColorsTypeTintWebColor]];
    [tabBarController setActionNavigationBarHidden:NO animated:YES completion:^(BOOL finished) {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.navigationController.navigationBar.alpha = 0.0f;
    }];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)disableSelectMode {
    if (!_albumListDataSource.isSelectMode) {
        return;
    }
    _albumListDataSource.isSelectMode = NO;
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:NO animated:NO completion:nil];
    [tabBarController setActionToolbarHidden:YES animated:YES completion:nil];
    [tabBarController setActionNavigationBarHidden:YES animated:YES completion:nil];
    self.navigationController.navigationBar.alpha = 1.0f;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark Photos
- (void)makeNewAlbumWithTitle:(NSString *)title {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
    } completionHandler:^(BOOL success, NSError *error) {
        
    }];
}

- (void)deleteAssetCollections:(NSArray *)assetCollections {
    if (assetCollections.count == 0) {
        return;
    }
    
    UIAlertAction *deleteAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    NSString *title = nil;
    if (assetCollections.count == 1) {
        PHAssetCollection *assetCollection = assetCollections.firstObject;
        title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the album \"%@\"?", nil), assetCollection.localizedTitle];
    }
    else {
        title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete %ld albums?", nil), (long)assetCollections.count];
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:deleteAlertAction];
    [alertController addAction:cancelAlertAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
