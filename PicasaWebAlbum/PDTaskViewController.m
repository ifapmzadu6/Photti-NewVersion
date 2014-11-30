//
//  PDTaskViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskViewController.h"

#import "PAColors.h"
#import "PADateFormatter.h"
#import "PDModelObject.h"
#import "PWModelObject.h"
#import "PLModelObject.h"
#import "PDModelObject.h"
#import "PWCoreDataAPI.h"
#import "PLCoreDataAPI.h"
#import "PDCoreDataAPI.h"
#import "PDTaskManager.h"
#import "PAPhotoKit.h"
#import "PDWebPhotoViewCell.h"
#import "PDLocalPhotoViewCell.h"
#import "PDNewLocalPhotoViewCell.h"
#import "PAPhotoCollectionViewFlowLayout.h"
#import "PATabBarController.h"
#import "PAViewControllerKit.h"

@interface PDTaskViewController () <UICollectionViewDataSource, UICollectionViewDelegate, PDTaskManagerDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (weak, nonatomic) UICollectionViewCell *firstCell;

@end

@implementation PDTaskViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Uploading", nil);
        
        [[PDTaskManager sharedManager] addTaskManagerObserver:self];
        
        NSManagedObjectContext *context = [PDCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeContext:) name:NSManagedObjectContextDidSaveNotification object:context];
    }
    return self;
}

- (instancetype)initWithTaskObject:(PDTaskObject *)taskObject {
    self = [self init];
    if (self) {
        _taskObject = taskObject;
    }
    return self;
}

- (void)dealloc {
    [[PDTaskManager sharedManager] removeTaskManagerObserver:self];
    
    NSManagedObjectContext *context = [PDCoreDataAPI readContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PAPhotoCollectionViewFlowLayout *collectionViewLayout = [PAPhotoCollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[PDWebPhotoViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PDWebPhotoViewCell class])];
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        [_collectionView registerClass:[PDNewLocalPhotoViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PDNewLocalPhotoViewCell class])];
    }
    else {
        [_collectionView registerClass:[PDLocalPhotoViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PDLocalPhotoViewCell class])];
    }
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _collectionView.exclusiveTouch = YES;
    _collectionView.allowsMultipleSelection = YES;
    [self.view addSubview:_collectionView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    CGFloat navigationBarHeight = self.navigationController.navigationBar.bounds.size.height;
    CGFloat statusBarHeight = [PAViewControllerKit statusBarHeight];
    UIEdgeInsets viewInsets = UIEdgeInsetsMake(navigationBarHeight + statusBarHeight, 0.0f, 0.0f, 0.0f);
    UIEdgeInsets contentInset = UIEdgeInsetsZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    }
    else {
        contentInset = UIEdgeInsetsMake(viewInsets.top + 20.0f, 60.0f, viewInsets.bottom + 20.0f, 60.0f);
    }
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    [PAViewControllerKit rotateCollectionView:_collectionView rect:rect contentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _taskObject.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PDBasePhotoObject *photoObject = _taskObject.photos[indexPath.row];
    if ([photoObject isKindOfClass:[PDWebPhotoObject class]] ||
        [photoObject isKindOfClass:[PDCopyPhotoObject class]]) {
        PDWebPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PDWebPhotoViewCell class]) forIndexPath:indexPath];
        cell.photo = [PWPhotoObject getPhotoObjectWithID:photoObject.photo_object_id_str];
        return cell;
    }
    else if ([photoObject isKindOfClass:[PDLocalPhotoObject class]] ||
             [photoObject isKindOfClass:[PDLocalCopyPhotoObject class]]) {
        if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
            PDNewLocalPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PDNewLocalPhotoViewCell class]) forIndexPath:indexPath];
            __weak typeof(cell) wcell = cell;
            NSUInteger tag = indexPath.row;
            cell.tag = tag;
            cell.backgroundColor = [UIColor whiteColor];
            CGSize targetSize = [PAPhotoCollectionViewFlowLayout itemSize];
            PHAsset *asset = [PAPhotoKit getAssetWithIdentifier:photoObject.photo_object_id_str];
            PHImageRequestOptions *options = [PHImageRequestOptions new];
            options.networkAccessAllowed = YES;
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                typeof(wcell) scell = wcell;
                if (!scell) return;
                if (scell.tag == tag) {
                    scell.imageView.image = result;
                }
            }];
            cell.favoriteIconView.hidden = (asset.favorite) ? NO : YES;
            if (asset.mediaType == PHAssetMediaTypeVideo) {
                cell.videoBackgroundView.hidden = NO;
                cell.videoDurationLabel.hidden = NO;
                cell.videoDurationLabel.text = [PADateFormatter arrangeDuration:asset.duration];
                if (asset.mediaSubtypes == PHAssetMediaSubtypeVideoTimelapse) {
                    cell.videoTimelapseIconView.hidden = NO;
                }
                else if (asset.mediaSubtypes == PHAssetMediaSubtypeVideoHighFrameRate) {
                    cell.videoSlomoIconView.hidden = NO;
                }
                else {
                    cell.videoIconView.hidden = NO;
                }
            }
            return cell;
        }
        else {
            PDLocalPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PDLocalPhotoViewCell class]) forIndexPath:indexPath];
            cell.photo = [PLPhotoObject getPhotoObjectWithID:photoObject.photo_object_id_str];
            return cell;
        }
    }
    
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        ((PDNewLocalPhotoViewCell *)cell).progress = 0.0f;
        _firstCell = cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        ((PDNewLocalPhotoViewCell *)_firstCell).progress = 0.0f;
        _firstCell = nil;
    }
}

#pragma mark CoreData
- (void)didChangeContext:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
        
        if (_taskObject.photos.count == 0) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
}

#pragma mark PDTaskManagerDelegate
- (void)taskManagerProgress:(CGFloat)progress photoObject:(PDBasePhotoObject *)photoObject {
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        id firstCell = sself.firstCell;
        if ([firstCell isKindOfClass:[PDWebPhotoViewCell class]]) {
            ((PDWebPhotoViewCell *)firstCell).progress = progress;
        }
        else if ([firstCell isKindOfClass:[PDLocalPhotoObject class]]) {
            ((PDLocalPhotoViewCell *)firstCell).progress = progress;
        }
        else if ([firstCell isKindOfClass:[PDNewLocalPhotoViewCell class]]) {
            ((PDNewLocalPhotoViewCell *)firstCell).progress = progress;
        }
    });
}

@end
