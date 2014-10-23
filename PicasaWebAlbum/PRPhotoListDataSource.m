//
//  PRPhotoListDataSource.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PRPhotoListDataSource.h"

#import <Reachability.h>
#import "PAString.h"
#import "PWCoreDataAPI.h"
#import "PWPhotoViewCell.h"
#import "PWPicasaAPI.h"
#import "PLCollectionFooterView.h"

static NSUInteger const kPRPhotoListMaxNumberOfRecentlyUploaded = 50;

@interface PRPhotoListDataSource () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isRequesting;

@property (strong, nonatomic) NSString *albumID;

@end

@implementation PRPhotoListDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedPhotoIDs = @[].mutableCopy;
    }
    return self;
}

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest albumID:(NSString *)albumID {
    self = [self init];
    if (self) {
        _albumID = albumID;
        
        NSManagedObjectContext *context = [PWCoreDataAPI readContext];
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        NSError *error = nil;
        if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            abort();
        }
        
        if (_albumID) {
            [self loadDataWithStartIndex:0];
        }
        else {
            [self loadRecentlyUploadedPhotos];
        }
    }
    return self;
}

#pragma mark Methods
- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    
    if (collectionView) {
        [collectionView registerClass:[PWPhotoViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PWPhotoViewCell class])];
        [collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class])];
    }
}

- (NSUInteger)numberOfPhotos {
    return _fetchedResultsController.fetchedObjects.count;
}

- (NSArray *)photos {
    return _fetchedResultsController.fetchedObjects;
}

- (NSArray *)selectedPhotos {
    NSMutableArray *selectedPhotos = @[].mutableCopy;
    for (NSString *id_str in _selectedPhotoIDs) {
        NSArray *results = [self.photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
        if (results.count > 0) {
            PWPhotoObject *photo = results.firstObject;
            [selectedPhotos addObject:photo];
        }
    }
    return selectedPhotos;
}

- (void)setIsSelectMode:(BOOL)isSelectMode {
    _isSelectMode = isSelectMode;
    
    _selectedPhotoIDs = @[].mutableCopy;
    
    for (PWPhotoViewCell *cell in _collectionView.visibleCells) {
        cell.isSelectWithCheckMark = isSelectMode;
    }
    UICollectionView *collectionView = _collectionView;
    if (collectionView) {
        for (NSIndexPath *indexPath in collectionView.indexPathsForSelectedItems) {
            [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark LoadData
- (void)loadDataWithStartIndex:(NSUInteger)index {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _didRefresh ? _didRefresh() : 0;
        });
        return;
    };
    
    if (_isRequesting) {
        return;
    }
    _isRequesting = YES;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:_albumID index:index completion:^(NSUInteger nextIndex, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.isRequesting = NO;
            
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                if (error.code == 401) {
                    if ([PWOAuthManager shouldOpenLoginViewController]) {
                        sself.openLoginViewController ? sself.openLoginViewController() : 0;
                    }
                    else {
                        [PWOAuthManager incrementCountOfLoginError];
                        sself.openLoginViewController ? sself.openLoginViewController() : 0;
                    }
                }
            }
            else {
                sself.requestIndex = nextIndex;
            }
            [PWOAuthManager resetCountOfLoginError];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                sself.didRefresh ? sself.didRefresh() : 0;
            });
        }];
    });
}

- (void)loadRecentlyUploadedPhotos {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _didRefresh ? _didRefresh() : 0;
        });
        return;
    };
    
    if (_isRequesting) {
        return;
    }
    _isRequesting = YES;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [PWPicasaAPI getListOfRecentlyUploadedPhotosWithCompletion:^(NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.isRequesting = NO;
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                if (error.code == 401) {
                    if ([PWOAuthManager shouldOpenLoginViewController]) {
                        sself.openLoginViewController ? sself.openLoginViewController() : 0;
                    }
                    else {
                        [PWOAuthManager incrementCountOfLoginError];
                        sself.openLoginViewController ? sself.openLoginViewController() : 0;
                    }
                }
            }
            [PWOAuthManager resetCountOfLoginError];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                sself.didRefresh ? sself.didRefresh() : 0;
            });
        }];
    });
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    if (_albumID) {
        return [sectionInfo numberOfObjects];
    }
    else {
        return MIN([sectionInfo numberOfObjects], kPRPhotoListMaxNumberOfRecentlyUploaded);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PWPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PWPhotoViewCell class]) forIndexPath:indexPath];
    
    cell.isSelectWithCheckMark = _isSelectMode;
    [cell setPhoto:[_fetchedResultsController objectAtIndexPath:indexPath]];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class]) forIndexPath:indexPath];
    
    if (self.numberOfPhotos > 0) {
        NSArray *photos = [self.photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(kPWPhotoObjectTypePhoto)]];
        NSArray *videos = [self.photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(kPWPhotoObjectTypeVideo)]];
        NSString *albumCountString = [PAString photoAndVideoStringWithPhotoCount:photos.count videoCount:videos.count isInitialUpperCase:YES];
        NSString *footerString =[NSString stringWithFormat:@"- %@ -", albumCountString];
        [footerView setText:footerString];
    }
    
    return footerView;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    
    if (_isSelectMode) {
        PWPhotoObject *photo = [_fetchedResultsController objectAtIndexPath:indexPath];
        if (![_selectedPhotoIDs containsObject:photo.id_str]) {
            [_selectedPhotoIDs addObject:photo.id_str];
        }
        
        if (_didChangeSelectedItemCountBlock) {
            _didChangeSelectedItemCountBlock(collectionView.indexPathsForSelectedItems.count);
        }
    }
    else {
        PWPhotoViewCell *cell = (PWPhotoViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        id placeholder = (cell.animatedImage) ? (id)cell.animatedImage : (id)cell.image;
        PWPhotoObject *photo = cell.photo;
        if (_didSelectPhotoBlock) {
            _didSelectPhotoBlock(photo, placeholder, indexPath.item);
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [super collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
    
    if (_isSelectMode) {
        PWPhotoObject *photo = [_fetchedResultsController objectAtIndexPath:indexPath];
        if ([_selectedPhotoIDs containsObject:photo.id_str]) {
            [_selectedPhotoIDs removeObject:photo.id_str];
        }
        
        if (_didChangeSelectedItemCountBlock) {
            _didChangeSelectedItemCountBlock(collectionView.indexPathsForSelectedItems.count);
        }
    }
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        UICollectionView *collectionView = _collectionView;
        if (collectionView) {
            [collectionView reloadData];
            
            for (NSString *id_str in _selectedPhotoIDs) {
                NSArray *tmpPhotos = [self.photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
                PWPhotoObject *photo = tmpPhotos.firstObject;
                if (photo) {
                    NSUInteger index = [self.photos indexOfObject:photo];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                }
            }
        }
        
        if (_didChangeItemCountBlock) {
            _didChangeItemCountBlock(controller.fetchedObjects.count);
        }
    });
}

@end
