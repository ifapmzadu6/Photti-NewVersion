//
//  PLNewAlbumCreatedViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLNewAlbumCreatedViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLAssetsManager.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PDTaskManager.h"
#import "PLFullAlbumViewCell.h"

@interface PLNewAlbumCreatedViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UILabel *createdNewAlbumLabel;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *albumTitleLabel;
@property (strong, nonatomic) UIButton *uploadButton;
@property (strong, nonatomic) UIButton *skipButton;
@property (strong, nonatomic) UIButton *applyAllItemsButton;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHideNotification) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    self.navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintUploadColor];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.leftBarButtonItem = doneBarButtonItem;
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
    _collectionView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    _collectionView.clipsToBounds = NO;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 80.0f, 0.0f, 80.0f);
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 256.0f, 0.0f, 256.0f);
        }
        else {
            _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 192.0f, 0.0f, 192.0f);
        }
    }
    _collectionView.exclusiveTouch = YES;
    _collectionView.scrollEnabled = NO;
    [self.view addSubview:_collectionView];
    
    _createdNewAlbumLabel = [UILabel new];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _createdNewAlbumLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    else {
        _createdNewAlbumLabel.font = [UIFont systemFontOfSize:16.0f];
    }
    _createdNewAlbumLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    _createdNewAlbumLabel.textAlignment = NSTextAlignmentCenter;
    _createdNewAlbumLabel.numberOfLines = 0;
    [self.view addSubview:_createdNewAlbumLabel];
    
    _uploadButton = [UIButton new];
    [_uploadButton addTarget:self action:@selector(uploadButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _uploadButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _uploadButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_uploadButton setTitle:NSLocalizedString(@"Upload", nil) forState:UIControlStateNormal];
    [_uploadButton setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:PAColorsTypeTintUploadColor]] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PAColors getColor:PAColorsTypeBackgroundLightColor] forState:UIControlStateNormal];
    [_uploadButton setTitleColor:[PAColors getColor:PAColorsTypeTintUploadColor] forState:UIControlStateHighlighted];
    [_uploadButton setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:PAColorsTypeTintUploadColor]] forState:UIControlStateNormal];
    [_uploadButton setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:PAColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _uploadButton.clipsToBounds = YES;
    _uploadButton.layer.cornerRadius = 5.0f;
    _uploadButton.layer.borderColor = [PAColors getColor:PAColorsTypeTintUploadColor].CGColor;
    _uploadButton.layer.borderWidth = 1.0f;
    _uploadButton.exclusiveTouch = YES;
    [self.view addSubview:_uploadButton];
    
    _skipButton = [UIButton new];
    [_skipButton addTarget:self action:@selector(skipButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _skipButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _skipButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_skipButton setTitle:NSLocalizedString(@"Skip", nil) forState:UIControlStateNormal];
    [_skipButton setTitleColor:[PAColors getColor:PAColorsTypeBackgroundLightColor] forState:UIControlStateHighlighted];
    [_skipButton setTitleColor:[PAColors getColor:PAColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_skipButton setBackgroundImage:[PAIcons imageWithColor:[[PAColors getColor:PAColorsTypeTintUploadColor] colorWithAlphaComponent:0.5f]] forState:UIControlStateHighlighted];
    _skipButton.clipsToBounds = YES;
    _skipButton.layer.cornerRadius = 5.0f;
    _skipButton.exclusiveTouch = YES;
    [self.view addSubview:_skipButton];
    
    _applyAllItemsButton = [UIButton new];
    [_applyAllItemsButton addTarget:self action:@selector(applyAllItemsButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _applyAllItemsButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _applyAllItemsButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_applyAllItemsButton setTitle:NSLocalizedString(@"Apply the same operation to all items", nil) forState:UIControlStateNormal];
    [_applyAllItemsButton setTitleColor:[PAColors getColor:PAColorsTypeBackgroundLightColor] forState:UIControlStateHighlighted];
    [_applyAllItemsButton setTitleColor:[PAColors getColor:PAColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_applyAllItemsButton setBackgroundImage:[PAIcons imageWithColor:[[PAColors getColor:PAColorsTypeTintUploadColor] colorWithAlphaComponent:0.5f]] forState:UIControlStateHighlighted];
    _applyAllItemsButton.clipsToBounds = YES;
    _applyAllItemsButton.layer.cornerRadius = 5.0f;
    _applyAllItemsButton.exclusiveTouch = YES;
    [self.view addSubview:_applyAllItemsButton];
    
    NSManagedObjectContext *context = [PLCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"(import = %@) AND (tag_uploading_type = %@)", _date, @(PLAlbumObjectTagUploadingTypeUnknown)];
//#ifdef DEBUG
//    //下はテスト用
//    request.predicate = [NSPredicate predicateWithFormat:@"tag_uploading_type = %@", @(PLAlbumObjectTagUploadingTypeUnknown)];
//#endif
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
    request.fetchLimit = 7;
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    [self setTitleLabelWithNumberOfAlbums:_fetchedResultsController.fetchedObjects.count];
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)(MAX(CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds))) > 480) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                CGFloat deltaX = (CGRectGetWidth([UIScreen mainScreen].bounds)-568.0f)/2.0f;
                CGFloat deltaY = (CGRectGetHeight([UIScreen mainScreen].bounds)-320.0f)/2.0f;
                _createdNewAlbumLabel.frame = CGRectMake(deltaX, deltaY+86.0f, 320.0f, 40.0f);
                _collectionView.frame = CGRectMake(deltaX+242.0f, deltaY+80.0f, 320.0f, 280.0f);
                _uploadButton.frame = CGRectMake(deltaX+110.0f, deltaY+155.0f, 100.0f, 32.0f);
                _skipButton.frame = CGRectMake(deltaX+110.0f, deltaY+205.0f, 100.0f, 32.0f);
                _applyAllItemsButton.frame = CGRectMake(deltaX+17.0f, deltaY+320.0f-60.0f, 255.0f+30.0f, 30.0f);
            }
            else {
                CGFloat deltaX = (CGRectGetWidth([UIScreen mainScreen].bounds)-320.0f)/2.0f;
                CGFloat deltaY = (CGRectGetHeight([UIScreen mainScreen].bounds)-568.0f)/2.0f;
                _createdNewAlbumLabel.frame = CGRectMake(deltaX, deltaY+86.0f, 320.0f, 40.0f);
                _collectionView.frame = CGRectMake(deltaX, deltaY+150.0f, 320.0f, 280.0f);
                _uploadButton.frame = CGRectMake(deltaX+110.0f, deltaY+400.0f, 100.0f, 32.0f);
                _skipButton.frame = CGRectMake(deltaX+110.0f, deltaY+450.0f, 100.0f, 32.0f);
                _applyAllItemsButton.frame = CGRectMake(deltaX+20.0f, deltaY+568.0f-50.0f, 320.0f-20.0f*2.0f, 30.0f);
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _createdNewAlbumLabel.frame = CGRectMake(10.0f, 86.0f, 260.0f, 40.0f);
                _collectionView.frame = CGRectMake(190.0f, 74.0f, 320.0f, 280.0f);
                _uploadButton.frame = CGRectMake(90.0f, 155.0f, 100.0f, 32.0f);
                _skipButton.frame = CGRectMake(90.0f, 205.0f, 100.0f, 32.0f);
                _applyAllItemsButton.frame = CGRectMake(6.0f, CGRectGetHeight(rect) - 60.0f, 255.0f + 30.0f, 30.0f);
            }
            else {
                _createdNewAlbumLabel.frame = CGRectMake(30.0f, 86.0f, 260.0f, 40.0f);
                _collectionView.frame = CGRectMake(0.0f, 130.0f, 320.0f, 280.0f);
                _uploadButton.frame = CGRectMake(110.0f, 350.0f, 100.0f, 32.0f);
                _skipButton.frame = CGRectMake(110.0f, 390.0f, 100.0f, 32.0f);
                _applyAllItemsButton.frame = CGRectMake(20.0f, CGRectGetHeight(rect) - 50.0f, CGRectGetWidth(rect) - 20.0f*2.0f, 30.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _createdNewAlbumLabel.frame = CGRectMake(312.0f, 100.0f, 400.0f, 40.0f);
            _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 256.0f, 0.0f, 256.0f);
            _collectionView.frame = CGRectMake(0.0f, 120.0f, 1024.0f, 500.0f);
            _uploadButton.frame = CGRectMake(382.0f, 670.0f, 260.0f, 60.0f);
            _skipButton.frame = CGRectMake(70.0f, 670.0f, 260.0f, 60.0f);
            _applyAllItemsButton.frame = CGRectMake(680.0f, 670.0f, 300.0f, 60.0f);
        }
        else {
            _createdNewAlbumLabel.frame = CGRectMake(184.0f, 100.0f, 400.0f, 40.0f);
            _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 192.0f, 0.0f, 192.0f);
            _collectionView.frame = CGRectMake(0.0f, 170.0f, 768.0f, 500.0f);
            _uploadButton.frame = CGRectMake(244.0f, 700.0f, 260.0f, 60.0f);
            _skipButton.frame = CGRectMake(244.0f, 790.0f, 260.0f, 60.0f);
            _applyAllItemsButton.frame = CGRectMake(184.0f, CGRectGetHeight(rect) - 100.0f, 400.0f, 60.0f);
        }
    }
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    [self skipAll];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIButton
- (void)uploadButtonAction {
    _uploadButton.userInteractionEnabled = NO;
    _skipButton.userInteractionEnabled = NO;
    
    CGFloat centerX = _collectionView.center.x;
    CGFloat centerY = _collectionView.center.y - 30.0f;
    
    UIImageView *uploadImageView = [UIImageView new];
    uploadImageView.image = [[UIImage imageNamed:@"UploadOnlyIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    uploadImageView.tintColor = [[PAColors getColor:PAColorsTypeTintUploadColor] colorWithAlphaComponent:0.9f];
    uploadImageView.frame = CGRectMake(centerX - 320.0f/2.0f, centerY - 320.0f/2.0f, 320.0f, 320.0f);
    uploadImageView.alpha = 0.0f;
    [self.view addSubview:uploadImageView];
    
    [UIView animateWithDuration:0.25f animations:^{
        uploadImageView.frame = CGRectMake(centerX - 240.0f/2.0f, centerY - 240.0f/2.0f, 240.0f, 240.0f);
        uploadImageView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25f delay:0.15f options:0 animations:^{
            uploadImageView.frame = CGRectMake(centerX - 160.0f/2.0f, centerY - 160.0f/2.0f, 160.0f, 160.0f);
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
            
            [[PDTaskManager sharedManager] addTaskFromLocalAlbum:albumObject toWebAlbum:nil completion:^(NSError *error) {
#ifdef DEBUG
                NSLog(@"アルバムアップロード設定OK");
#endif
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

- (void)applyAllItemsButtonAction {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Upload all", nil), NSLocalizedString(@"Skip all", nil), nil];
    [actionSheet showInView:self.view];
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
    
    PLAlbumObject *albumObject = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.album = albumObject;
    NSManagedObjectID *albumObjectID = albumObject.objectID;
    cell.textFieldDidEndEditing = ^(NSString *title){
        [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PLAlbumObject *tmpAlbumObject = (PLAlbumObject *)[context objectWithID:albumObjectID];
            tmpAlbumObject.name = title;
        }];
    };
    
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(160.0f, 280.0f);
        }
        else {
            return CGSizeMake(160.0f, 280.0f);
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(512.0f, 400.0f);
        }
        else {
            return CGSizeMake(384.0f, 400.0f);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 50.0f;
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
        if (controller.fetchedObjects.count == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        [_collectionView performBatchUpdates:^{
            [_fetchedResultsReloadOperation start];
        } completion:^(BOOL finished) {
            
        }];
        
        [self setTitleLabelWithNumberOfAlbums:_fetchedResultsController.fetchedObjects.count];
    });
}

#pragma mark Methods
- (void)setTitleLabelWithNumberOfAlbums:(NSUInteger)numberOfAlbums {
    NSString *newAlbumString = [NSString stringWithFormat:NSLocalizedString(@"Created New %ld Albums!", nil), numberOfAlbums];
    NSString *tapToEditString = NSLocalizedString(@"Tap the album title to edit.", nil);
    _createdNewAlbumLabel.text = [NSString stringWithFormat:@"%@\n%@", newAlbumString, tapToEditString];
}

#pragma mark UIKeyBoardNotification
- (void)keyboardWillShowNotification {
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)keyboardDidHideNotification {
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSManagedObjectContext *context = [PLCoreDataAPI writeContext];
        for (PLAlbumObject *albumObject in _fetchedResultsController.fetchedObjects) {
            NSManagedObjectID *albumObjectID = albumObject.objectID;
            [context performBlockAndWait:^{
                PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumObjectID];
                albumObject.tag_uploading_type = @(PLAlbumObjectTagUploadingTypeYES);
            }];
        }
        [context performBlockAndWait:^{
            NSError *error = nil;
            if (![context save:&error]) {
                abort();
            }
        }];
        [self applyAllItems:_fetchedResultsController.fetchedObjects.mutableCopy];
        
        [PLCoreDataAPI writeContextFinish:context];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (buttonIndex == 1) {
        [self skipAll];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (buttonIndex == 2) {
    }
}

#pragma mark Data
- (void)skipAll {
    NSManagedObjectContext *context = [PLCoreDataAPI writeContext];
    for (PLAlbumObject *albumObject in _fetchedResultsController.fetchedObjects) {
        NSManagedObjectID *albumObjectID = albumObject.objectID;
        [context performBlockAndWait:^{
            PLAlbumObject *albumObject = (PLAlbumObject *)[context objectWithID:albumObjectID];
            albumObject.tag_uploading_type = @(PLAlbumObjectTagUploadingTypeNO);
        }];
    }
    [context performBlockAndWait:^{
        NSError *error = nil;
        if (![context save:&error]) {
            abort();
        }
    }];
    [PLCoreDataAPI writeContextFinish:context];
}

- (void)applyAllItems:(NSMutableArray *)albums {
    if (albums.count == 0) {
#ifdef DEBUG
        NSLog(@"アルバムアップロードすべて設定OK");
#endif
        return;
    }
    
    PLAlbumObject *albumObject = albums.firstObject;
    [[PDTaskManager sharedManager] addTaskFromLocalAlbum:albumObject toWebAlbum:nil completion:^(NSError *error) {
        if ([albums containsObject:albumObject]) {
            [albums removeObject:albumObject];
        }
        [self applyAllItems:albums];
    }];
}

@end
