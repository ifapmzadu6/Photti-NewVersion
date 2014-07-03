//
//  PLiCloudViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLiCloudViewController.h"

#import "PWColors.h"
#import "PLPhotoViewCell.h"
#import "PLPhotoViewHeaderView.h"
#import "PLCollectionFooterView.h"
#import "PWTabBarController.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PLDateFormatter.h"
#import "PWString.h"


@interface PLiCloudSection : NSObject

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSDate *date;
@property (nonatomic) NSUInteger photoCount;
@property (nonatomic) NSUInteger videoCount;

@end

@implementation PLiCloudSection

- (id)init {
    self = [super init];
    if (self) {
        _photos = [[NSMutableArray alloc] init];
    }
    return self;
}

@end


@interface PLiCloudViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSArray *sections;
@property (nonatomic) NSUInteger photosCount;
@property (nonatomic) NSUInteger videosCount;

@end

@implementation PLiCloudViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"iCloud", nil);
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
    [_collectionView registerClass:[PLPhotoViewHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    [_collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.clipsToBounds = NO;
    _collectionView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _collectionView.exclusiveTouch = YES;
    [self.view addSubview:_collectionView];
    
    __weak typeof(self) wself = self;
    [self getDataWithCompletion:^(NSArray *allPhotos, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.sections = [sself devidedPhotosByDate:allPhotos];
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.collectionView reloadData];
            PLiCloudSection *section = sself.sections.lastObject;
            NSArray *photos = section.photos;
            if (sself.sections.count > 0 && photos.count > 0) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:section.photos.count-1 inSection:sself.sections.count-1];
                [sself.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            }
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
    
    _collectionView.scrollsToTop = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _collectionView.scrollsToTop = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _collectionView.frame = rect;
    
    NSArray *indexPaths = _collectionView.indexPathsForVisibleItems;
    NSIndexPath *indexPath = nil;
    if (indexPaths.count) {
        indexPath = indexPaths[indexPaths.count / 2];
    }
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    if (indexPath) {
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    
    PWTabBarController *tabBarViewController = (PWTabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PLiCloudSection *photosection = _sections[section];
    return photosection.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    PLiCloudSection *section = _sections[indexPath.section];
    cell.photo = section.photos[indexPath.row];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        PLPhotoViewHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
        
        PLiCloudSection *section = _sections[indexPath.section];
        NSString *string = [[PLDateFormatter formatter] stringFromDate:section.date];
        [headerView setText:string];
        [headerView setDetail:[PWString photoAndVideoStringWithPhotoCount:section.photoCount videoCount:section.videoCount]];
        
        reusableView = headerView;
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (indexPath.section == _sections.count - 1) {
            PLCollectionFooterView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
            
            NSString *localizedString = NSLocalizedString(@"すべての写真: %lu枚、すべてのビデオ: %lu本", nil);
            [footer setText:[NSString stringWithFormat:localizedString, _photosCount, _videosCount]];
            
            reusableView = footer;
        }
    }
    
    return reusableView;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(78.5f, 78.5f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 60.0f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section < _sections.count - 1) {
        return CGSizeZero;
    }
    
    return CGSizeMake(0.0f, 60.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark Data
- (void)getDataWithCompletion:(void (^)(NSArray *allPhotos, NSError *error))completion {
    [[PLAssetsManager sharedManager] getiCloudPhotosWithCompletion:completion];
}

- (NSArray *)devidedPhotosByDate:(NSArray *)photos {
    _photosCount = 0;
    _videosCount = 0;
    
    NSMutableArray *sections = [NSMutableArray array];
    
    for (PLPhotoObject *photo in photos) {
        NSDate *photoDate = [PLDateFormatter adjustZeroClock:photo.date];
        BOOL isDone = NO;
        for (PLiCloudSection *section in sections.reverseObjectEnumerator) {
            if ([photoDate isEqualToDate:section.date]) {
                [section.photos addObject:photo];
                if ([photo.type isEqualToString:ALAssetTypePhoto]) {
                    section.photoCount++;
                    _photosCount++;
                }
                else if ([photo.type isEqualToString:ALAssetTypeVideo]) {
                    section.videoCount++;
                    _videosCount++;
                }
                isDone = YES;
                break;
            }
        }
        if (!isDone) {
            PLiCloudSection *newSection = [[PLiCloudSection alloc] init];
            [newSection.photos addObject:photo];
            newSection.date = photoDate;
            
            [sections addObject:newSection];
            if ([photo.type isEqualToString:ALAssetTypePhoto]) {
                newSection.photoCount++;
                _photosCount++;
            }
            else if ([photo.type isEqualToString:ALAssetTypeVideo]) {
                newSection.videoCount++;
                _videosCount++;
            }
        }
    }
    
    return sections;
}

@end
