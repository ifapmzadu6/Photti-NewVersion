//
//  PWImagePickerLocalPhotoListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/27.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerLocalPhotoListViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PWString.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PLPhotoViewCell.h"
#import "PLCollectionFooterView.h"
#import "PWImagePickerController.h"

@interface PWImagePickerLocalPhotoListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) UIBarButtonItem *selectActionBarButton;
@property (strong, nonatomic) UIBarButtonItem *trashBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *moveBarButtonItem;

@property (strong, nonatomic) PLAlbumObject *album;

@end

@implementation PWImagePickerLocalPhotoListViewController

- (id)initWithAlbum:(PLAlbumObject *)album {
    self = [super init];
    if (self) {
        self.title = album.name;
        
        _album = album;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLPhotoViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.allowsMultipleSelection = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _collectionView.contentInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
    }
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
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
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {return [obj1 compare:obj2];}];
    NSIndexPath *indexPath = nil;
    if (indexPaths.count > 0) {
        indexPath = indexPaths[indexPaths.count / 2];
    }
    
    _collectionView.frame = rect;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem
- (void)setRightNavigationItemSelectButton {
    UIBarButtonItem *selectBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PWIcons imageWithText:NSLocalizedString(@"Select", nil) fontSize:17.0f] style:UIBarButtonItemStylePlain target:self action:@selector(selectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = selectBarButtonItem;
}

- (void)setRightNavigationItemDeselectButton {
    UIBarButtonItem *deselectBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Deselect All", nil) style:UIBarButtonItemStylePlain target:self action:@selector(deselectBarButtonAction)];
    self.navigationItem.rightBarButtonItem = deselectBarButtonItem;
}

#pragma mark UIBarButtonAction
- (void)selectBarButtonAction {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    for (size_t i=0; i<_album.photos.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [_collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
        [tabBarController addSelectedPhoto:_album.photos[i]];
    }
    
    [self setRightNavigationItemDeselectButton];
}

- (void)deselectBarButtonAction {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
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
        
        NSString *albumCountString = [PWString photoAndVideoStringWithPhotoCount:photos.count videoCount:videos.count isInitialUpperCase:YES];
        [footerView setText:albumCountString];
    }
    else {
        [footerView setText:nil];
    }
    
    return footerView;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(112.0f, 112.0f);
        }
        else {
            return CGSizeMake(106.0f, 106.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(172.0f, 187.0f);
        }
        else {
            return CGSizeMake(172.0f, 187.0f);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return 2.0f;
        }
        else {
            return 1.0f;
        }
    }
    else {
        return 10.0f;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    [tabBarController addSelectedPhoto:_album.photos[indexPath.row]];
    
    if (_album.photos.count == _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemDeselectButton];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    [tabBarController removeSelectedPhoto:_album.photos[indexPath.row]];
    
    if (_album.photos.count != _collectionView.indexPathsForSelectedItems.count) {
        [self setRightNavigationItemSelectButton];
    }
}

@end
