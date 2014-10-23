//
//  PRAlbumListDataSource.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PRAlbumListDataSource.h"

#import "PWAlbumViewCell.h"
#import "PLCollectionFooterView.h"
#import "PWPicasaAPI.h"
#import <Reachability.h>

@interface PRAlbumListDataSource () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) NSUInteger requestIndex;
@property (nonatomic) BOOL isRequesting;

@end

@implementation PRAlbumListDataSource

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest {
    self = [self init];
    if (self) {
        NSManagedObjectContext *context = [PWCoreDataAPI readContext];
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        NSError *error = nil;
        if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            abort();
        }
        
        [self loadDataWithStartIndex:0];
    }
    return self;
}

#pragma mark Methods
- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    
    if (collectionView) {
        [collectionView registerClass:[PWAlbumViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PWAlbumViewCell class])];
        [collectionView registerClass:[PLCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class])];
    }
}

- (NSUInteger)numberOfAlbums {
    return _fetchedResultsController.fetchedObjects.count;
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
    [PWPicasaAPI getListOfAlbumsWithIndex:index completion:^(NSUInteger nextIndex, NSError *error) {
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
    PWAlbumViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PWAlbumViewCell class]) forIndexPath:indexPath];
    
    cell.album = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *superReusableView = [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    if (superReusableView) {
        return superReusableView;
    }
    
    PLCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([PLCollectionFooterView class]) forIndexPath:indexPath];
    
    if (_fetchedResultsController.fetchedObjects.count > 0) {
        NSString *albumCountString = [NSString stringWithFormat:NSLocalizedString(@"- %lu Albums -", nil), (unsigned long)_fetchedResultsController.fetchedObjects.count];
        [footerView setText:albumCountString];
    }
    
    return footerView;
}

#pragma mark UICollectionViewFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 50.0f);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PWAlbumObject *album = [_fetchedResultsController objectAtIndexPath:indexPath];
    if (_didSelectAlbumBlock) {
        _didSelectAlbumBlock(album, indexPath.item);
    }
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
                
        if (_didChangeItemCountBlock) {
            _didChangeItemCountBlock(controller.fetchedObjects.count);
        }
    });
}

@end
