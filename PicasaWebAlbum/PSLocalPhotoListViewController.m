//
//  PWImagePickerLocalPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/27.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSLocalPhotoListViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PAString.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLPhotoViewCell.h"
#import "PLCollectionFooterView.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PSImagePickerController.h"
#import "PAViewControllerKit.h"

@interface PSLocalPhotoListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIImageView *noItemImageView;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *moveBarButtonItem;

@property (strong, nonatomic) PLAlbumObject *album;

@end

@implementation PSLocalPhotoListViewController

- (id)initWithAlbum:(PLAlbumObject *)album {
    self = [super init];
    if (self) {
        self.title = album.name;
        
        _album = album;
        
        NSManagedObjectContext *context = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification) name:NSManagedObjectContextDidSaveNotification object:context];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PAPhotoCollectionViewFlowLayout *collectionViewLayout = [[PAPhotoCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    _collectionView.allowsMultipleSelection = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _collectionView.contentInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
    }
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    for (NSString *id_str in tabBarController.selectedPhotoIDs) {
        NSArray *filteredPhotos = [_album.photos.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
        if (filteredPhotos.count) {
            PLPhotoObject *photo = filteredPhotos.firstObject;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_album.photos.array indexOfObject:photo] inSection:0];
            [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
    
    if (_album.photos.count == _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemDeselectButton];
    }
    else {
        [self setRightNavigationItemSelectButton];
    }
    
    [self refreshNoItemWithNumberOfItem:_album.photos.count];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = tabBarController.viewInsets;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        contentInset = UIEdgeInsetsMake(viewInsets.top + 20.0f, 20.0f, viewInsets.bottom + 20.0f, 20.0f);
    }
    UIEdgeInsets scrollIndicatorInsets = viewInsets;
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
}

- (void)dealloc {
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
}

#pragma mark UIBarButtonItem
- (void)setRightNavigationItemSelectButton {
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PAIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = selectBarButtonItem;
}

- (void)setRightNavigationItemDeselectButton {
    UIBarButtonItem *deselectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Deselect all", nil) style:UIBarButtonItemStylePlain target:self action:@selector(deselectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = deselectBarButtonItem;
}

#pragma mark UIBarButtonAction
- (void)selectBarButtonAction {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    for (size_t i=0; i<_album.photos.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
        [tabBarController addSelectedPhoto:_album.photos[i]];
    }
    
    [self setRightNavigationItemDeselectButton];
}

- (void)deselectBarButtonAction {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    for (size_t i=0; i<_album.photos.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [_collectionView deselectItemAtIndexPath:indexPath animated:NO];
        
        [tabBarController removeSelectedPhoto:_album.photos[i]];
    }
    
    [self setRightNavigationItemSelectButton];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _album.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.photo = _album.photos[indexPath.row];
    cell.isSelectWithCheckMark = YES;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    if (_album.photos.count > 0) {
        NSArray *photos = [_album.photos.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypePhoto]];
        NSArray *videos = [_album.photos.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypeVideo]];
        
        NSString *albumCountString = [PAString photoAndVideoStringWithPhotoCount:photos.count videoCount:videos.count isInitialUpperCase:YES];
        [footerView setText:albumCountString];
    }
    
    return footerView;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    [tabBarController addSelectedPhoto:_album.photos[indexPath.row]];
    
    if (_album.photos.count == _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemDeselectButton];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    [tabBarController removeSelectedPhoto:_album.photos[indexPath.row]];
    
    if (_album.photos.count != _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemSelectButton];
    }
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)contextDidSaveNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
        
        [self refreshNoItemWithNumberOfItem:_album.photos.count];
    });
}

@end
