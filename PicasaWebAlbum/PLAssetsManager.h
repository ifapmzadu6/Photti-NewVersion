//
//  PLAssetsManager.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import AssetsLibrary;
@import MapKit;


typedef enum _PLAssetsManagerAutoCreateAlbumType {
    PLAssetsManagerAutoCreateAlbumTypeUnknown = 0,
    PLAssetsManagerAutoCreateAlbumTypeEnable,
    PLAssetsManagerAutoCreateAlbumTypeDisable
} PLAssetsManagerAutoCreateAlbumType;

static NSString * const kPLAssetsManagerAssetCountKey = @"kPLAMACK";


@interface PLAssetsManager : NSObject

@property (nonatomic) PLAssetsManagerAutoCreateAlbumType autoCreateAlbumType;
@property (nonatomic, readonly) BOOL isLibraryUpDated;

+ (PLAssetsManager *)sharedManager;
+ (ALAssetsLibrary *)sharedLibrary;

- (void)testAccessPhotoLibraryWithCompletion:(void (^)(NSError *error))completion;
- (void)checkNewAlbumBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void (^)(NSArray *newAlbumDates, NSError *error))completion;
- (void)enumurateAssetsWithCompletion:(void (^)(NSError *error))completion;
- (void)getAllPhotosWithCompletion:(void (^)(NSArray *allPhotos, NSError *error))completion;
- (void)getiCloudPhotosWithCompletion:(void (^)(NSArray *allPhotos, NSError *error))completion;
- (void)getAllAlbumsWithCompletion:(void (^)(NSArray *allAlbums, NSError *error))completion;
- (void)getImportedAlbumsWithCompletion:(void (^)(NSArray *importedAlbums, NSError *error))completion;
- (void)getAutomatticallyCreatedAlbumWithCompletion:(void (^)(NSArray *importedAlbums, NSError *error))completion;

@end
