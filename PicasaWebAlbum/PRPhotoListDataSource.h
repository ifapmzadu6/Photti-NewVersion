//
//  PRPhotoListDataSource.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

#import "PACollectionViewDaisyChain.h"
#import "PWModelObject.h"

@interface PRPhotoListDataSource : PACollectionViewDaisyChain

@property (copy, nonatomic) void (^didSelectPhotoBlock)(PWPhotoObject *photo, id placeholder, NSUInteger index);
@property (copy, nonatomic) void (^didChangeItemCountBlock)(NSUInteger count);
@property (copy, nonatomic) void (^didChangeSelectedItemCountBlock)(NSUInteger count);

@property (copy, nonatomic) void (^didRefresh)();
@property (copy, nonatomic) void (^openLoginViewController)();
@property (nonatomic, readonly) NSUInteger requestIndex;
@property (nonatomic, readonly) BOOL isRequesting;

@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UIColor *cellBackgroundColor;

@property (nonatomic, readonly) NSUInteger numberOfPhotos;
@property (nonatomic, readonly) NSArray *photos;

@property (nonatomic) BOOL isSelectMode;
@property (nonatomic, readonly) NSMutableArray *selectedPhotoIDs;
@property (nonatomic, readonly) NSArray *selectedPhotos;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest albumID:(NSString *)albumID;

- (void)loadDataWithStartIndex:(NSUInteger)startIndex;
- (void)loadRecentlyUploadedPhotos;

@end
