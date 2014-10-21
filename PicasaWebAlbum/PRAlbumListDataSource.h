//
//  PRAlbumListDataSource.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

#import "PACollectionViewDaisyChain.h"
#import "PWModelObject.h"

@interface PRAlbumListDataSource : PACollectionViewDaisyChain

@property (copy, nonatomic) void (^didSelectAlbumBlock)(PWAlbumObject *album, NSUInteger index);
@property (copy, nonatomic) void (^didChangeItemCountBlock)(NSUInteger count);
@property (copy, nonatomic) void (^didChangeSelectedItemCountBlock)(NSUInteger count);

@property (copy, nonatomic) void (^didRefresh)();
@property (copy, nonatomic) void (^openLoginViewController)();

@property (nonatomic, readonly) NSUInteger requestIndex;
@property (nonatomic, readonly) BOOL isRequesting;

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, readonly) NSUInteger numberOfAlbums;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest;

- (void)loadDataWithStartIndex:(NSUInteger)startIndex;

@end
