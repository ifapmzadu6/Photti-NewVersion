//
//  PLAssetsManager.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAssetsManager.h"

#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLDateFormatter.h"
#import "PWSnowFlake.h"
#import "DDlog.h"

@interface PLAssetsManager ()

@property (strong, nonatomic) ALAssetsLibrary *library;
@property (nonatomic) BOOL isLibraryUpDated;

@end

@implementation PLAssetsManager

static dispatch_queue_t assets_manager_queue() {
    static dispatch_queue_t af_url_session_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_processing_queue = dispatch_queue_create("com.photto.picasawebalbum.queue", DISPATCH_QUEUE_SERIAL);
    });
    return af_url_session_manager_processing_queue;
}

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

+ (ALAssetsLibrary *)sharedLibrary {
    return [[PLAssetsManager sharedManager] library];
}

- (id)init {
    self = [super init];
    if (self) {
        _library = [[ALAssetsLibrary alloc] init];
        
        _isLibraryUpDated = NO;
    }
    return self;
}

+ (void)groupForURL:(NSURL *)url resultBlock:(void (^)(ALAssetsGroup *group))resultBlock failureBlock:(void (^)(NSError *error))failureBlock {
    dispatch_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedLibrary] groupForURL:url resultBlock:resultBlock failureBlock:failureBlock];
    });
}

+ (void)assetForURL:(NSURL *)url resultBlock:(void (^)(ALAsset *asset))resultBlock failureBlock:(void (^)(NSError *error))failureBlock {
    dispatch_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:resultBlock failureBlock:failureBlock];
    });
}

+ (void)writeImageDataToSavedPhotosAlbum:(NSData *)data metadata:(NSDictionary *)metadata completionBlock:(void (^)(NSURL *, NSError *))completionBlock {
    dispatch_barrier_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedLibrary] writeImageDataToSavedPhotosAlbum:data metadata:metadata completionBlock:completionBlock];
    });
}

+ (void)getAllPhotosWithCompletion:(void (^)(NSArray *, NSError *))completion {
    dispatch_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedManager] getAllPhotosWithCompletion:completion];
    });
}

- (void)getAllPhotosWithCompletion:(void (^)(NSArray *, NSError *))completion {
    if (!completion) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(assets_manager_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        void (^block)(NSError *) = ^(NSError *error){
            if (error) {
                completion(nil, error);
                return;
            }
            
            [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"tag_albumtype != %@", @(ALAssetsGroupPhotoStream)];
                request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
                NSError *error = nil;
                NSArray *allphotos = [context executeFetchRequest:request error:&error];
                
                completion(allphotos, error);
            }];
        };
        
        if (sself.isLibraryUpDated) {
            block(nil);
        }
        else {
            [sself enumurateAssetsWithCompletion:block];
        }
        
    });
}

+ (void)getiCloudPhotosWithCompletion:(void (^)(NSArray *, NSError *))completion {
    dispatch_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedManager] getiCloudPhotosWithCompletion:completion];
    });
}

- (void)getiCloudPhotosWithCompletion:(void (^)(NSArray *, NSError *))completion {
    if (!completion) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(assets_manager_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        void (^block)(NSError *) = ^(NSError *error){
            if (error) {
                completion(nil, error);
                return;
            }
            
            [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"tag_albumtype = %@", @(ALAssetsGroupPhotoStream)];
                request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
                NSError *error = nil;
                NSArray *allphotos = [context executeFetchRequest:request error:&error];
                
                completion(allphotos, error);
            }];
        };
        
        if (sself.isLibraryUpDated) {
            block(nil);
        }
        else {
            [sself enumurateAssetsWithCompletion:block];
        }
    });
}

+ (void)getAllAlbumsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    dispatch_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedManager] getAllAlbumsWithCompletion:completion];
    });
}

- (void)getAllAlbumsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    if (!completion) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(assets_manager_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        void (^block)(NSError *) = ^(NSError *error){
            if (error) {
                completion(nil, error);
                return;
            }
            
            [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:YES]];
                NSError *error = nil;
                NSArray *allphotos = [context executeFetchRequest:request error:&error];
                
                completion(allphotos, error);
            }];
        };
        
        if (sself.isLibraryUpDated) {
            block(nil);
        }
        else {
            [sself enumurateAssetsWithCompletion:block];
        }
    });
}

+ (void)getImportedAlbumsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    dispatch_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedManager] getImportedAlbumsWithCompletion:completion];
    });
}

- (void)getImportedAlbumsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    if (!completion) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(assets_manager_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        void (^block)(NSError *) = ^(NSError *error){
            if (error) {
                completion(nil, error);
                return;
            }
            
            [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"tag_type = %@", @(PLAlbumObjectTagTypeImported)];
                request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
                NSError *error = nil;
                NSArray *allphotos = [context executeFetchRequest:request error:&error];
                
                completion(allphotos, error);
            }];
        };
        
        if (sself.isLibraryUpDated) {
            block(nil);
        }
        else {
            [self enumurateAssetsWithCompletion:block];
        }
    });
}

+ (void)getAutomatticallyCreatedAlbumWithCompletion:(void (^)(NSArray *, NSError *))completion {
    dispatch_async(assets_manager_queue(), ^{
        [[PLAssetsManager sharedManager] getAutomatticallyCreatedAlbumWithCompletion:completion];
    });
}

- (void)getAutomatticallyCreatedAlbumWithCompletion:(void (^)(NSArray *, NSError *))completion {
    if (!completion) {
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(assets_manager_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        void (^block)(NSError *) = ^(NSError *error){
            if (error) {
                completion(nil, error);
                return;
            }
            
            [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"tag_type = %@", @(PLAlbumObjectTagTypeAutomatically)];
                request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:NO]];
                NSError *error = nil;
                NSArray *allphotos = [context executeFetchRequest:request error:&error];
                
                completion(allphotos, error);
            }];
        };
        
        if (sself.isLibraryUpDated) {
            block(nil);
        }
        else {
            [sself enumurateAssetsWithCompletion:block];
        }
    });
}

- (void)enumurateAssetsWithCompletion:(void (^)(NSError *error))completion {
    __weak typeof(self) wself = self;
    dispatch_async(assets_manager_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (sself.isLibraryUpDated) {
            if (completion) {
                completion(nil);
            }
            return;
        }
        sself.isLibraryUpDated = YES;
        
        NSDate *enumurateDate = [NSDate date];
        
        void (^groupEnumurateBlock)(PLAlbumObject *, ALAsset *, NSUInteger , BOOL *) = ^(PLAlbumObject *album, ALAsset *result, NSUInteger index, BOOL *stop) {
            if (!result) {
                return;
            }
            
            [PLCoreDataAPI performBlockAndWait:^(NSManagedObjectContext *context) {
                ALAssetRepresentation *representation = result.defaultRepresentation;
                NSString *url = representation.url.absoluteString;
                
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
                NSError *error = nil;
                NSArray *tmpphotos = [context executeFetchRequest:request error:&error];
                if (tmpphotos.count) {
                    PLPhotoObject *photo = tmpphotos.firstObject;
                    photo.update = enumurateDate;
                    return;
                }
                
                PLPhotoObject *photo = [NSEntityDescription insertNewObjectForEntityForName:kPLPhotoObjectName inManagedObjectContext:context];
                photo.url = url;
                CGSize dimensions = representation.dimensions;
                photo.width = @(dimensions.width);
                photo.height = @(dimensions.height);
                photo.filename = representation.filename;
                photo.type = [result valueForProperty:ALAssetPropertyType];
                NSDate *date = [result valueForProperty:ALAssetPropertyDate];
                photo.timestamp = @((unsigned long)([date timeIntervalSince1970]) * 1000);
                CLLocation *location = [result valueForProperty:ALAssetPropertyLocation];
                photo.date = date;
                photo.latitude = @(location.coordinate.latitude);
                photo.longitude = @(location.coordinate.longitude);
                photo.update = enumurateDate;
                photo.import = enumurateDate;
                
                photo.tag_albumtype = album.type;
                NSURL *urlWithString = [NSURL URLWithString:url];
                photo.id_str = urlWithString.query;
                [album addPhotosObject:photo];
            }];
        };
        groupEnumurateBlock = [groupEnumurateBlock copy];
        
        // PhotoStreamはiCloud
        ALAssetsGroupType assetsGroupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupLibrary | ALAssetsGroupSavedPhotos;
        
        [sself.library enumerateGroupsWithTypes:assetsGroupType usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                NSString *id_str = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
                
                [PLCoreDataAPI performBlockAndWait:^(NSManagedObjectContext *context) {
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
                    NSError *error = nil;
                    NSArray *tmpalbums = [context executeFetchRequest:request error:&error];
                    
                    PLAlbumObject *album = nil;
                    if (tmpalbums.count) {
                        album = tmpalbums.firstObject;
                    }
                    else {
                        album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
                        album.name = [group valueForProperty:ALAssetsGroupPropertyName];
                        album.type = [group valueForProperty:ALAssetsGroupPropertyType];
                        album.id_str = id_str;
                        NSURL *url = [group valueForProperty:ALAssetsGroupPropertyURL];
                        album.url = [url absoluteString];
                        album.import = enumurateDate;
                        album.tag_type = @(PLAlbumObjectTagTypeImported);
                    }
                    album.update = enumurateDate;
                    
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        groupEnumurateBlock(album, result, index, stop);
                    }];
                }];
            }
            else {
                //写真を全て読み込んだ後の処理だと思うわけよ
                
                [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                    //前回の読み込みから消えた写真
                    NSFetchRequest *outdatedPhotoRequest = [[NSFetchRequest alloc] init];
                    outdatedPhotoRequest.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                    outdatedPhotoRequest.predicate = [NSPredicate predicateWithFormat:@"update != %@", enumurateDate];
                    NSError *error = nil;
                    NSArray *outdatedPhotos = [context executeFetchRequest:outdatedPhotoRequest error:&error];
                    for (PLPhotoObject *photo in outdatedPhotos) {
                        [context deleteObject:photo];
                    }
//                    NSLog(@"removed = %lu", (unsigned long)outdatedPhotos.count);
                    
                    //今回の読み込みで追加された新規写真
                    NSFetchRequest *newPhotoRequest = [[NSFetchRequest alloc] init];
                    newPhotoRequest.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                    newPhotoRequest.predicate = [NSPredicate predicateWithFormat:@"(tag_albumtype != %@) AND (import = %@)", @(ALAssetsGroupPhotoStream), enumurateDate];
                    error = nil;
                    NSArray *newPhotos = [context executeFetchRequest:newPhotoRequest error:&error];
//                    NSLog(@"new = %lu", (unsigned long)newPhotos.count);
                    
                    if (newPhotos.count) {
                        //新規写真は振り分けをしなければならない
                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
                        request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                        request.predicate = [NSPredicate predicateWithFormat:@"(tag_type = %@) AND (edited = NO)", @(PLAlbumObjectTagTypeAutomatically)];
                        error = nil;
                        NSArray *tmpalbums = [context executeFetchRequest:request error:&error];
                        NSMutableArray *albums = tmpalbums.mutableCopy;
                        for (PLPhotoObject *newPhoto in newPhotos) {
                            NSDate *adjustedDate = [PLDateFormatter adjustZeroClock:newPhoto.date];
                            BOOL isDetected = NO;
                            for (PLAlbumObject *album in albums.reverseObjectEnumerator) {
                                if ([album.tag_date isEqualToDate:adjustedDate]) {
                                    [album addPhotosObject:newPhoto];
                                    isDetected = YES;
                                    break;
                                }
                            }
                            if (!isDetected) {
                                //自動作成版アルバムを作る
                                PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
                                album.id_str = [PWSnowFlake generateUniqueIDString];
                                album.name = NSLocalizedString(@"新規アルバム", nil);
                                album.tag_date = adjustedDate;
                                album.timestamp = @((unsigned long)([adjustedDate timeIntervalSince1970]) * 1000);
                                album.import = enumurateDate;
                                album.update = enumurateDate;
                                album.tag_type = @(PLAlbumObjectTagTypeAutomatically);
                                
                                [album addPhotosObject:newPhoto];
                                
                                [albums addObject:album];
                            }
                        }
                    }
                    
                    [context save:&error];
                    
                    if (completion) {
                        completion(error);
                    }
                }];
            }
        } failureBlock:^(NSError *error) {
            if (completion) {
                completion(error);
            }
        }];
    });
}

@end
