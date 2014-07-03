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

@property (strong, nonatomic) UILabel *createdNewAlbumLabel;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *albumTitleLabel;
@property (strong, nonatomic) UIButton *uploadButton;
@property (strong, nonatomic) UIButton *skipButton;

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
//            request.predicate = [NSPredicate predicateWithFormat:@"(import = %@) AND (tag_uploading_type = %@)", date, @(PLAlbumObjectTagUploadingTypeUnknown)];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
            sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
            sself.fetchedResultsController.delegate = sself;
            
            NSError *error = nil;
            [sself.fetchedResultsController performFetch:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (sself.collectionView) {
                    if (sself.collectionView.indexPathsForVisibleItems.count == 0) {
                        [sself.collectionView reloadData];
                        [sself.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
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
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.clipsToBounds = NO;
    _collectionView.userInteractionEnabled = NO;
//    _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 300.0f, 0.0f, 300.0f);
    [self.view addSubview:_collectionView];
    
    _createdNewAlbumLabel = [UILabel new];
    _createdNewAlbumLabel.text = NSLocalizedString(@"Created New Albums!", nil);
    _createdNewAlbumLabel.font = [UIFont systemFontOfSize:15.0f];
    _createdNewAlbumLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    _createdNewAlbumLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_createdNewAlbumLabel];
    
    _uploadButton = [UIButton new];
    [_uploadButton addTarget:self action:@selector(uploadButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _uploadButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_uploadButton setTitle:NSLocalizedString(@"Upload", nil) forState:UIControlStateNormal];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PWColors getColor:PWColorsTypeBackgroundLightColor] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateHighlighted];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _uploadButton.clipsToBounds = YES;
    _uploadButton.layer.cornerRadius = 5.0f;
    _uploadButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintLocalColor].CGColor;
    _uploadButton.layer.borderWidth = 1.0f;
    [self.view addSubview:_uploadButton];
    
    _skipButton = [UIButton new];
    _skipButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_skipButton setTitle:NSLocalizedString(@"Skip", nil) forState:UIControlStateNormal];
    [_skipButton setTitleColor:[PWColors getColor:PWColorsTypeBackgroundLightColor] forState:UIControlStateHighlighted];
    [_skipButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateNormal];
    [_skipButton setBackgroundImage:[PWIcons imageWithColor:[[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.5f]] forState:UIControlStateHighlighted];
    _skipButton.clipsToBounds = YES;
    _skipButton.layer.cornerRadius = 5.0f;
    [self.view addSubview:_skipButton];
    
    UIBarButtonItem *skipBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip All", nil) style:UIBarButtonItemStylePlain target:self action:@selector(skipBarButtonAction)];
    self.navigationItem.leftBarButtonItem = skipBarButtonItem;
    
    UIBarButtonItem *uploadAllButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload All", nil) style:UIBarButtonItemStylePlain target:self action:@selector(uploadAllButtonAction)];
    self.navigationItem.rightBarButtonItem = uploadAllButtonItem;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _createdNewAlbumLabel.frame = CGRectMake(60.0f, 100.0f, 200.0f, 20.0f);
    _collectionView.frame = CGRectMake(0.0f, 120.0f, CGRectGetWidth(rect), 280.0f);
    _uploadButton.frame = CGRectMake(110.0f, 410.0f, 100.0f, 32.0f);
    _skipButton.frame = CGRectMake(110.0f, 460.0f, 100.0f, 32.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)uploadAllButtonAction {
//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)skipBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIButton
- (void)uploadButtonAction {
    NSArray *indexPaths = [_collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
        return obj1.row > obj2.row;
    }];
    [_collectionView scrollToItemAtIndexPath:indexPaths.lastObject atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
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
            return CGSizeMake(160.0f, 220.0f);
        }
        else {
            return CGSizeMake(160.0f, 220.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(160.0f, 220.0f);
        }
        else {
            return CGSizeMake(160.0f, 220.0f);
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
