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

@interface PLNewAlbumCreatedViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UILabel *createdNewAlbumLabel;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *albumTitleLabel;
@property (strong, nonatomic) UIButton *uploadButton;
@property (strong, nonatomic) UIButton *skipButton;

@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSBlockOperation *fetchedResultsReloadOperation;

@end

@implementation PLNewAlbumCreatedViewController

- (id)initWithEnumuratedDate:(NSDate *)date {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"New Albums", nil);
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        _date = date;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.leftBarButtonItem = doneBarButtonItem;
//    UIBarButtonItem *uploadAllButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload All", nil) style:UIBarButtonItemStylePlain target:self action:@selector(uploadAllButtonAction)];
//    [uploadAllButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]} forState:UIControlStateNormal];
//    self.navigationItem.rightBarButtonItem = uploadAllButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
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
    _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 80.0f, 0.0f, 80.0f);
    _collectionView.exclusiveTouch = YES;
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
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintUploadColor]] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PWColors getColor:PWColorsTypeBackgroundLightColor] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PWColors getColor:PWColorsTypeTintUploadColor] forState:UIControlStateHighlighted];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintUploadColor]] forState:UIControlStateNormal];
    [_uploadButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _uploadButton.clipsToBounds = YES;
    _uploadButton.layer.cornerRadius = 5.0f;
    _uploadButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintUploadColor].CGColor;
    _uploadButton.layer.borderWidth = 1.0f;
    _uploadButton.exclusiveTouch = YES;
    [self.view addSubview:_uploadButton];
    
    _skipButton = [UIButton new];
    [_skipButton addTarget:self action:@selector(skipButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _skipButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_skipButton setTitle:NSLocalizedString(@"Skip", nil) forState:UIControlStateNormal];
    [_skipButton setTitleColor:[PWColors getColor:PWColorsTypeBackgroundLightColor] forState:UIControlStateHighlighted];
    [_skipButton setTitleColor:[PWColors getColor:PWColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_skipButton setBackgroundImage:[PWIcons imageWithColor:[[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.5f]] forState:UIControlStateHighlighted];
    _skipButton.clipsToBounds = YES;
    _skipButton.layer.cornerRadius = 5.0f;
    _skipButton.exclusiveTouch = YES;
    [self.view addSubview:_skipButton];
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"(import = %@) AND (tag_uploading_type = %@)", _date, @(PLAlbumObjectTagUploadingTypeUnknown)];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _createdNewAlbumLabel.frame = CGRectMake(60.0f, 90.0f, 200.0f, 20.0f);
    _collectionView.frame = CGRectMake(0.0f, 110.0f, CGRectGetWidth(rect), 280.0f);
    _uploadButton.frame = CGRectMake(110.0f, 420.0f, 100.0f, 32.0f);
    _skipButton.frame = CGRectMake(110.0f, 470.0f, 100.0f, 32.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)uploadAllButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIButton
- (void)uploadButtonAction {
    _uploadButton.userInteractionEnabled = NO;
    _skipButton.userInteractionEnabled = NO;
    
    UIImageView *uploadImageView = [UIImageView new];
    uploadImageView.image = [[UIImage imageNamed:@"UploadOnlyIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    uploadImageView.tintColor = [[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.9f];
    uploadImageView.frame = CGRectMake(_collectionView.center.x - 320.0f/2.0f, _collectionView.center.y - 320.0f/2.0f, 320.0f, 320.0f);
    uploadImageView.alpha = 0.0f;
    [self.view addSubview:uploadImageView];
    
    [UIView animateWithDuration:0.25f animations:^{
        uploadImageView.frame = CGRectMake(_collectionView.center.x - 240.0f/2.0f, _collectionView.center.y - 240.0f/2.0f, 240.0f, 240.0f);
        uploadImageView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25f delay:0.15f options:0 animations:^{
            uploadImageView.frame = CGRectMake(_collectionView.center.x - 160.0f/2.0f, _collectionView.center.y - 160.0f/2.0f, 160.0f, 160.0f);
            uploadImageView.center = _collectionView.center;
            uploadImageView.alpha = 0.0f;
            
        } completion:^(BOOL finished) {
            _uploadButton.userInteractionEnabled = YES;
            _skipButton.userInteractionEnabled = YES;
            
            PLAlbumObject *albumObject = _fetchedResultsController.fetchedObjects.firstObject;
            if (!albumObject) return;
            NSManagedObjectID *albumObjectID = albumObject.objectID;
            [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumObjectID];
                albumObject.tag_uploading_type = @(PLAlbumObjectTagUploadingTypeYES);
            }];
        }];
    }];
}

- (void)skipButtonAction {
    PLAlbumObject *albumObject = _fetchedResultsController.fetchedObjects.firstObject;
    if (!albumObject) return;
    NSManagedObjectID *albumObjectID = albumObject.objectID;
    [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
        PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumObjectID];
        albumObject.tag_uploading_type = @(PLAlbumObjectTagUploadingTypeNO);
    }];
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
    return 20.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 20.0f;
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _fetchedResultsReloadOperation = [NSBlockOperation new];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    __weak UICollectionView *collectionView = self.collectionView;
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [_fetchedResultsReloadOperation addExecutionBlock:^{
                [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            }];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [_fetchedResultsReloadOperation addExecutionBlock:^{
                [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            }];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [_fetchedResultsReloadOperation addExecutionBlock:^{
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [_fetchedResultsReloadOperation addExecutionBlock:^{
                [collectionView deleteItemsAtIndexPaths:@[indexPath]];
                [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            }];
            break;
        }
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView performBatchUpdates:^{
            [_fetchedResultsReloadOperation start];
        } completion:^(BOOL finished) {
            
        }];
        
        _createdNewAlbumLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Created New %ld Albums!", nil), _fetchedResultsController.fetchedObjects.count];
    });
}

@end
