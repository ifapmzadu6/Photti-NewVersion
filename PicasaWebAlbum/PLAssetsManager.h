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

@interface PLAssetsManager : NSObject

@property (nonatomic, readonly) BOOL isLibraryUpDated;

+ (PLAssetsManager *)sharedManager;

+ (ALAuthorizationStatus)getAuthorizationStatus;
+ (void)testAccessPhotoLibraryWithCompletion:(void (^)(NSError *))completion;
+ (void)enumurateAssetsWithCompletion:(void (^)(NSError *error))completion;

+ (void)groupForURL:(NSURL *)url resultBlock:(void (^)(ALAssetsGroup *group))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
+ (void)syncGroupForURL:(NSURL *)url resultBlock:(void (^)(ALAssetsGroup *group))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
+ (void)assetForURL:(NSURL *)url resultBlock:(void (^)(ALAsset *asset))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
+ (void)syncAssetForURL:(NSURL *)url resultBlock:(void (^)(ALAsset *asset))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
+ (void)writeImageDataToSavedPhotosAlbum:(NSData *)data metadata:(NSDictionary *)metadata completionBlock:(void (^)(NSURL *assetURL, NSError *error))completionBlock;

+ (void)getAllPhotosWithCompletion:(void (^)(NSArray *allPhotos, NSError *error))completion;
+ (void)getiCloudPhotosWithCompletion:(void (^)(NSArray *allPhotos, NSError *error))completion;
+ (void)getAllAlbumsWithCompletion:(void (^)(NSArray *allAlbums, NSError *error))completion;
+ (void)getImportedAlbumsWithCompletion:(void (^)(NSArray *importedAlbums, NSError *error))completion;
+ (void)getAutomatticallyCreatedAlbumWithCompletion:(void (^)(NSArray *importedAlbums, NSError *error))completion;

@end
