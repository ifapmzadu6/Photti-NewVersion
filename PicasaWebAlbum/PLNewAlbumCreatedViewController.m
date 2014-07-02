//
//  PLNewAlbumCreatedViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLNewAlbumCreatedViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLAssetsManager.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PLFullAlbumViewCell.h"

@interface PLNewAlbumCreatedViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *createdNewAlbumLabel;
@property (strong, nonatomic) UIButton *uploadButton;
@property (strong, nonatomic) UIButton *skipButton;
@property (strong, nonatomic) UIButton *uploadAllButton;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL isChangingContext;

@end

@implementation PLNewAlbumCreatedViewController

- (id)initWithEnumuratedDate:(NSDate *)date {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"New Albums", nil);
        
        __weak typeof(self) wself = self;
        [PLCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"(import = %@) AND (tag_uploading_type = %@)", date, @(PLAlbumObjectTagUploadingTypeUnknown)];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
            sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
            sself.fetchedResultsController.delegate = sself;
            
            NSError *error = nil;
            [sself.fetchedResultsController performFetch:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (sself.collectionView) {
                    if (sself.collectionView.indexPathsForVisibleItems.count == 0) {
                        [sself.collectionView reloadData];
                    }
                }
            });
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    [self.view addSubview:_collectionView];
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PLFullAlbumViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.alwaysBounceHorizontal = YES;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(10.0f, 10.0f, 0.0f, 10.0f);
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_collectionView];
    
    _createdNewAlbumLabel = [UILabel new];
    _createdNewAlbumLabel.text = NSLocalizedString(@"Created New Albums!", nil);
    _createdNewAlbumLabel.font = [UIFont systemFontOfSize:15.0f];
    _createdNewAlbumLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    _createdNewAlbumLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_createdNewAlbumLabel];
    
    _uploadButton = [UIButton new];
    _uploadButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_uploadButton setTitle:NSLocalizedString(@"Upload", nil) forState:UIControlStateNormal];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PWColors getColor:PWColorsTypeBackgroundLightColor] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateHighlighted];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    [self.view addSubview:_uploadButton];
    
    _uploadAllButton = [UIButton new];
    _uploadAllButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_uploadAllButton setTitle:NSLocalizedString(@"Upload All Albums", nil) forState:UIControlStateNormal];
    [_uploadAllButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_uploadAllButton setTitleColor:[PWColors getColor:PWColorsTypeBackgroundLightColor] forState:UIControlStateNormal];
    [_uploadAllButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateHighlighted];
    [_uploadAllButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_uploadAllButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    [self.view addSubview:_uploadAllButton];
    
    UIBarButtonItem *skipBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip All", nil) style:UIBarButtonItemStylePlain target:self action:@selector(skipBarButtonAction)];
    self.navigationItem.leftBarButtonItem = skipBarButtonItem;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = CGRectMake(0.0f, 50.0f, CGRectGetWidth(rect), 200.0f);
    
    _createdNewAlbumLabel.frame = CGRectMake(60.0f, 300.0f, 200.0f, 20.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)skipBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (_isChangingContext) {
        return 0;
    }
    
    return _fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_isChangingContext) {
        return 0;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLFullAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.album = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(160.0f, 120.0f);
        }
        else {
            return CGSizeMake(160.0f, 120.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(160.0f, 120.0f);
        }
        else {
            return CGSizeMake(160.0f, 120.0f);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 20.0f;
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = NO;
    
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
        
        _createdNewAlbumLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Created New %ld Albums!", nil), _fetchedResultsController.fetchedObjects.count];
    });
}

@end
