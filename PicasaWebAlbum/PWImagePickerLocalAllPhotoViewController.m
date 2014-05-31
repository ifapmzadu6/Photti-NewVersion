//
//  PWImagePickerLocalAllPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImagePickerLocalAllPhotoViewController.h"

#import "PWColors.h"
#import "PLPhotoViewCell.h"
#import "PLPhotoViewHeaderView.h"
#import "PLCollectionFooterView.h"
#import "PWImagePickerController.h"
#import "PWString.h"
#import "PLDateFormatter.h"
#import "PLAssetsManager.h"
#import "PLModelObject.h"


@interface PLImagePickerSection : NSObject

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSDate *date;
@property (nonatomic) NSUInteger photoCount;
@property (nonatomic) NSUInteger videoCount;

@end

@implementation PLImagePickerSection

- (id)init {
    self = [super init];
    if (self) {
        _photos = [[NSMutableArray alloc] init];
    }
    return self;
}

@end


@interface PWImagePickerLocalAllPhotoViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSArray *sections;
@property (nonatomic) NSUInteger photosCount;
@property (nonatomic) NSUInteger videosCount;

@property (strong, nonatomic) NSMutableDictionary *headerViews;

@end

@implementation PWImagePickerLocalAllPhotoViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"すべての写真", nil);
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
    _collectionView.allowsMultipleSelection = YES;
    [self.view addSubview:_collectionView];
    
    _headerViews = [NSMutableDictionary dictionary];
    
    __weak typeof(self) wself = self;
    [self getDataWithCompletion:^(NSArray *allPhotos, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.sections = [sself devidedPhotosByDate:allPhotos];
        dispatch_async(dispatch_get_main_queue(), ^{
            [sself.collectionView reloadData];
            PLImagePickerSection *section = sself.sections.lastObject;
            NSArray *photos = section.photos;
            if (sself.sections.count > 0 && photos.count > 0) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:section.photos.count-1 inSection:sself.sections.count-1];
                [sself.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            }
        });
    }];
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
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    [collectionViewLayout invalidateLayout];
    
    PWImagePickerController *tabBarViewController = (PWImagePickerController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _collectionView.contentInset = UIEdgeInsetsMake(viewInsets.top + 30.0f, 0.0f, viewInsets.bottom, 0.0f);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top + 30.0f, 0.0f, viewInsets.bottom, 0.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PLImagePickerSection *photosection = _sections[section];
    return photosection.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    PLImagePickerSection *section = _sections[indexPath.section];
    cell.photo = section.photos[indexPath.row];
    cell.isSelectWithCheckMark = YES;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        PLPhotoViewHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
        
        PLImagePickerSection *section = _sections[indexPath.section];
        NSString *string = [[PLDateFormatter formatter] stringFromDate:section.date];
        [headerView setText:string];
        [headerView setDetail:[PWString photoAndVideoStringWithPhotoCount:section.photoCount videoCount:section.videoCount]];
        __weak typeof(self) wself = self;
        [headerView setSelectButtonActionBlock:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PWImagePickerController *tabBarController = (PWImagePickerController *)sself.tabBarController;
            PLImagePickerSection *section = sself.sections[indexPath.section];
            for (size_t i=0; i<section.photos.count; i++) {
                NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [sself.collectionView selectItemAtIndexPath:selectIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                
                [tabBarController addSelectedPhoto:section.photos[selectIndexPath.row]];
            }
        }];
        [headerView setDeselectButtonActionBlock:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            PWImagePickerController *tabBarController = (PWImagePickerController *)sself.tabBarController;
            PLImagePickerSection *section = sself.sections[indexPath.section];
            for (size_t i=0; i<section.photos.count; i++) {
                NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                [sself.collectionView deselectItemAtIndexPath:selectIndexPath animated:NO];
                
                [tabBarController removeSelectedPhoto:section.photos[selectIndexPath.row]];
            }
        }];
        NSUInteger count = 0;
        for (NSIndexPath *selectedIndexPath in _collectionView.indexPathsForSelectedItems) {
            if (indexPath.section == selectedIndexPath.section) {
                count++;
            }
        }
        if (count == section.photos.count) {
            [headerView setSelectButtonIsDeselect:YES];
        }
        else {
            [headerView setSelectButtonIsDeselect:NO];
        }
        
        [_headerViews setObject:headerView forKey:@(indexPath.section)];
        
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

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        [_headerViews removeObjectForKey:@(indexPath.section)];
    }
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
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    PLImagePickerSection *section = _sections[indexPath.section];
    [tabBarController addSelectedPhoto:section.photos[indexPath.row]];
    
    NSUInteger count = 0;
    for (NSIndexPath *selectedIndexPath in _collectionView.indexPathsForSelectedItems) {
        if (indexPath.section == selectedIndexPath.section) {
            count++;
        }
    }
    for (NSNumber *sectionIndex in _headerViews.allKeys) {
        if (sectionIndex.integerValue == indexPath.section) {
            PLPhotoViewHeaderView *headerView = [_headerViews objectForKey:@(indexPath.section)];
            if (count == section.photos.count) {
                [headerView setSelectButtonIsDeselect:YES];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWImagePickerController *tabBarController = (PWImagePickerController *)self.tabBarController;
    PLImagePickerSection *section = _sections[indexPath.section];
    [tabBarController removeSelectedPhoto:section.photos[indexPath.row]];
    
    NSUInteger count = 0;
    for (NSIndexPath *selectedIndexPath in _collectionView.indexPathsForSelectedItems) {
        if (indexPath.section == selectedIndexPath.section) {
            count++;
        }
    }
    for (NSNumber *sectionIndex in _headerViews.allKeys) {
        if (sectionIndex.integerValue == indexPath.section) {
            PLPhotoViewHeaderView *headerView = [_headerViews objectForKey:@(indexPath.section)];
            if (count != section.photos.count) {
                [headerView setSelectButtonIsDeselect:NO];
            }
        }
    }
}

#pragma mark Data
- (void)getDataWithCompletion:(void (^)(NSArray *allPhotos, NSError *error))completion {
    [PLAssetsManager getAllPhotosWithCompletion:completion];
}

- (NSArray *)devidedPhotosByDate:(NSArray *)photos {
    _photosCount = 0;
    _videosCount = 0;
    
    NSMutableArray *sections = [NSMutableArray array];
    
    for (PLPhotoObject *photo in photos) {
        NSDate *photoDate = [PLDateFormatter adjustZeroClock:photo.date];
        BOOL isDone = NO;
        for (PLImagePickerSection *section in sections.reverseObjectEnumerator) {
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
            PLImagePickerSection *newSection = [[PLImagePickerSection alloc] init];
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
