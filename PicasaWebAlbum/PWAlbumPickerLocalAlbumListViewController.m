//
//  PWAlbumPickerLocalAlbumListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumPickerLocalAlbumListViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLAlbumViewCell.h"
#import "PWSnowFlake.h"
#import "PLDateFormatter.h"
#import "PLCollectionFooterView.h"
#import "PLModelObject.h"
#import "BlocksKit+UIKit.h"
#import "PWAlbumPickerController.h"

@interface PWAlbumPickerLocalAlbumListViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PWAlbumPickerLocalAlbumListViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Albums", nil);
        
        NSString *title = NSLocalizedString(@"Camera Roll", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:@"Picture"] selectedImage:[UIImage imageNamed:@"PictureSelected"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.contentInset = UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 0.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -10.0f);
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    UIBarButtonItem *cancelBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonitem;
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    addBarButtonItem.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    self.navigationItem.rightBarButtonItem = addBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_indicatorView];
    [_indicatorView startAnimating];
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    [_fetchedResultsController performFetch:nil];
    
    [_indicatorView stopAnimating];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = CGRectMake(10.0f, 0.0f, rect.size.width - 20.0f, rect.size.height);
    
    NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
        return obj1.row > obj2.row;
    }];
    NSIndexPath *indexPath = nil;
    if (indexPaths.count) {
        indexPath = indexPaths[indexPaths.count / 2];
    }
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    
    if (_indicatorView) {
        _indicatorView.center = self.view.center;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        self.tabBarItem.image = [PWIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem.selectedImage = [PWIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        self.tabBarItem.image = [UIImage imageNamed:@"Picture"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"PictureSelected"];
    }
}

#pragma mark UIBarButtonAction
- (void)cancelBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addBarButtonAction {
    UIAlertView *alertView = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"New Album", nil) message:NSLocalizedString(@"Enter album title.", nil)];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
    __weak UIAlertView *wAlertView = alertView;
    __weak typeof(self) wself = self;
    [alertView bk_addButtonWithTitle:NSLocalizedString(@"Save", nil) handler:^{
        UIAlertView *sAlertView = wAlertView;
        if (!sAlertView) return;
        
        UITextField *textField = [sAlertView textFieldAtIndex:0];
        NSString *title = textField.text;
        if (!title || [title isEqualToString:@""]) {
            title = NSLocalizedString(@"New Album", nil);
        }
        
        [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
            album.id_str = [PWSnowFlake generateUniqueIDString];
            album.name = NSLocalizedString(@"New Album", nil);
            NSDate *date = [NSDate date];
            NSDate *adjustedDate = [PLDateFormatter adjustZeroClock:date];
            album.tag_date = adjustedDate;
            album.timestamp = @((long long)([adjustedDate timeIntervalSince1970]) * 1000);
            album.import = date;
            album.update = date;
            album.tag_type = @(PLAlbumObjectTagTypeMyself);
        }];
    }];
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = NSLocalizedString(@"New Album", nil);
    [alertView show];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.album = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.isDisableActionButton = YES;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    if (indexPath.section == 0) {
        PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        
        if (_fetchedResultsController.fetchedObjects.count > 0) {
            NSString *localizedString = NSLocalizedString(@"%lu Albums", nil);
            NSString *albumCountString = [NSString stringWithFormat:localizedString, (unsigned long)_fetchedResultsController.fetchedObjects.count];
            [footerView setText:albumCountString];
        }
        
        return footerView;
    }
    
    return nil;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(177.0f, ceilf(177.0f * 3.0f / 4.0f) + 40.0f);
        }
        else {
            return CGSizeMake(146.0f, ceilf(146.0f * 3.0f / 4.0f) + 40.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(192.0f, ceilf(192.0f * 3.0f / 4.0f) + 40.0f);
        }
        else {
            return CGSizeMake(181.0f, ceilf(181.0f * 3.0f / 4.0f) + 40.0f);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 8.0f;
    }
    return 20.0f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return CGSizeMake(0.0f, 50.0f);
    }
    return CGSizeZero;
}

#pragma mark UIcollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PLAlbumObject *album = [_fetchedResultsController objectAtIndexPath:indexPath];
    PWAlbumPickerController *tabBarController = (PWAlbumPickerController *)self.tabBarController;
    [tabBarController doneBarButtonActionWithSelectedAlbum:album isWebAlbum:NO];
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {        
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

@end
