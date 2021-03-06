//
//  PWAlbumPickerLocalAlbumListViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PTLocalAlbumListViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLAlbumViewCell.h"
#import "PAAlbumCollectionViewFlowLayout.h"
#import "PASnowFlake.h"
#import "PADateFormatter.h"
#import "PADateTimestamp.h"
#import "PLCollectionFooterView.h"
#import "PLModelObject.h"
#import "PAViewControllerKit.h"
#import "PTAlbumPickerController.h"
#import "PABaseNavigationController.h"
#import "PLNewAlbumEditViewController.h"
#import "PAActivityIndicatorView.h"

@interface PTLocalAlbumListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PAActivityIndicatorView *indicatorView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PTLocalAlbumListViewController

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
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    self.navigationController.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintLocalColor];
    
    UIBarButtonItem *cancelBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonitem;
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonAction)];
    self.navigationItem.rightBarButtonItem = addBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    PAAlbumCollectionViewFlowLayout *collectionViewLayout = [[PAAlbumCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    _indicatorView = [PAActivityIndicatorView new];
    [self.view addSubview:_indicatorView];
    [_indicatorView startAnimating];
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        abort();
        return;
    }
    
    [self refreshNoItemWithNumberOfItem:_fetchedResultsController.fetchedObjects.count];
    
    [_indicatorView stopAnimating];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = tabBarController.viewInsets;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(viewInsets.top + 15.0f, 15.0f, viewInsets.bottom + 15.0f, 15.0f);
    UIEdgeInsets scrollIndicatorInsets = viewInsets;
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
    
    _indicatorView.center = self.view.center;
}

#pragma mark UIBarButtonAction
- (void)cancelBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addBarButtonAction {
    PLNewAlbumEditViewController *viewController = [[PLNewAlbumEditViewController alloc] initWithTitle:nil timestamp:@([PADateTimestamp timestampForDate:[NSDate date]].longLongValue) uploading_type:nil];
    viewController.saveButtonBlock = ^(NSString *name, NSNumber *timestamp, NSNumber *uploading_type){
        [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
            album.id_str = [PASnowFlake generateUniqueIDString];
            album.name = name;
            album.tag_date = [PADateTimestamp dateForTimestamp:timestamp.stringValue];
            album.timestamp = timestamp;
            album.import = [NSDate date];
            album.update = [NSDate date];
            album.tag_type = @(kPLAlbumObjectTagTypeMyself);
        }];
    };
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
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
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    if (indexPath.section == 0) {
        PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        
        if (_fetchedResultsController.fetchedObjects.count > 0) {
            NSString *localizedString = NSLocalizedString(@"- %lu Albums -", nil);
            NSString *albumCountString = [NSString stringWithFormat:localizedString, (unsigned long)_fetchedResultsController.fetchedObjects.count];
            [footerView setText:albumCountString];
        }
        
        return footerView;
    }
    
    return nil;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UIcollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PLAlbumObject *album = [_fetchedResultsController objectAtIndexPath:indexPath];
    PTAlbumPickerController *tabBarController = (PTAlbumPickerController *)self.tabBarController;
    [tabBarController doneBarButtonActionWithSelectedAlbum:album isWebAlbum:NO];
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
        
        [self refreshNoItemWithNumberOfItem:controller.fetchedObjects.count];
    });
}

@end
