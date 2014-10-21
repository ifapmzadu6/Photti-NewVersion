//
//  PWAlbumPickerHomeAlbumListViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PTNewLocalAlbumListViewController.h"

#import "PAColors.h"
#import "PEAlbumListDataSource.h"
#import "PAAlbumCollectionViewFlowLayout.h"
#import "PATabBarController.h"

@interface PTNewLocalAlbumListViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (weak, nonatomic) UIAlertAction *saveAlertAction;

@property (strong, nonatomic) PEAlbumListDataSource *albumListDataSource;

@end

@implementation PTNewLocalAlbumListViewController

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
            
        };
        _albumListDataSource.didChangeSelectedItemCountBlock = ^(NSUInteger count){
            typeof(wself) sself = wself;
            if (!sself) return;
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction:)];
    self.navigationItem.rightBarButtonItem = addBarButtonItem;
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = tabBarController.viewInsets;
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 15.0f, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    _collectionView.scrollIndicatorInsets = viewInsets;
    _collectionView.frame = rect;
}

#pragma mark UIBarButtonItem
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
