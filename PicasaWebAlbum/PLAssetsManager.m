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
@property (strong, nonatomic) NSDate *lastEnumuratedDate;

@end

@implementation PLAssetsManager

static NSString * const kPLAssetsManagerAutoCreateAlbumTypeKey = @"PLAMACATK";
static NSString * const kPLAssetsManagerErrorDomain = @"com.photti.PLAssetsManager.domain";

+ (PLAssetsManager *)sharedManager {
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
                
        _autoCreateAlbumType = (PLAssetsManagerAutoCreateAlbumType)[[NSUserDefaults standardUserDefaults] integerForKey:kPLAssetsManagerAutoCreateAlbumTypeKey];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryChangedNotification) name:ALAssetsLibraryChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}


#pragma mark NSNotification
- (void)assetsLibraryChangedNotification {
    _isLibraryUpDated = NO;
    [self enumurateAssetsWithCompletion:nil];
}

#pragma mark NSUserDefaults
- (void)setAutoCreateAlbumType:(PLAssetsManagerAutoCreateAlbumType)autoCreateAlbumType {
    _autoCreateAlbumType = autoCreateAlbumType;
    
    [[NSUserDefaults standardUserDefaults] setObject:@(autoCreateAlbumType) forKey:kPLAssetsManagerAutoCreateAlbumTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark testAccess
- (void)testAccessPhotoLibraryWithCompletion:(void (^)(NSError *))completion {
    [_library assetForURL:[NSURL URLWithString:@""] resultBlock:^(ALAsset *asset) {
        if (completion) {
            completion(nil);
        }
    } failureBlock:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)getPhotosWithPredicate:(NSPredicate *)predicate completion:(void (^)(NSArray *, NSError *))completion {
    if (!completion) return;
    
    void (^block)(NSError *) = ^(NSError *error){
        if (error) {
            completion(nil, error);
            return;
        }
        
        [PLCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
            request.predicate = predicate;
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
            NSError *error = nil;
            NSArray *allphotos = [context executeFetchRequest:request error:&error];
            
            completion(allphotos, error);
        }];
    };
    
    if (_isLibraryUpDated) {
        block(nil);
    }
    else {
        [self enumurateAssetsWithCompletion:block];
    }
}

- (void)getAllPhotosWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self getPhotosWithPredicate:[NSPredicate predicateWithFormat:@"tag_albumtype != %@", @(ALAssetsGroupPhotoStream)] completion:completion];
}

- (void)getiCloudPhotosWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self getPhotosWithPredicate:[NSPredicate predicateWithFormat:@"tag_albumtype = %@", @(ALAssetsGroupPhotoStream)] completion:completion];
}

- (void)getAlbumWithPredicate:(NSPredicate *)predicate completion:(void (^)(NSArray *, NSError *))completion {
    if (!completion) return;
    
    void (^block)(NSError *) = ^(NSError *error){
        if (error) {
            completion(nil, error);
            return;
        }
        
        [PLCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
            request.predicate = predicate;
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_date" ascending:YES]];
            NSError *error = nil;
            NSArray *allphotos = [context executeFetchRequest:request error:&error];
            
            completion(allphotos, error);
        }];
    };
    
    if (_isLibraryUpDated) {
        block(nil);
    }
    else {
        [self enumurateAssetsWithCompletion:block];
    }
}

- (void)getAllAlbumsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self getAlbumWithPredicate:nil completion:completion];
}

- (void)getImportedAlbumsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self getAlbumWithPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(PLAlbumObjectTagTypeImported)] completion:completion];
}

- (void)getAutomatticallyCreatedAlbumWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self getAlbumWithPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(PLAlbumObjectTagTypeAutomatically)] completion:completion];
}

- (void)checkNewAlbumBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void (^)(NSArray *, NSError *))completion {
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized || [PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeUnknown) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:kPLAssetsManagerErrorDomain code:500 userInfo:nil]);
        }
        return;
    }
    
    NSMutableArray *newAlbumDates = @[].mutableCopy;
    
    ALAssetsGroupType assetsGroupType = ALAssetsGroupSavedPhotos;
    [_library enumerateGroupsWithTypes:assetsGroupType usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (!result) return;
                
                NSDate *date = [result valueForProperty:ALAssetPropertyDate];
                if ([date compare:startDate] == NSOrderedAscending) {
                    *stop = YES;
                }
                else if ([date compare:endDate] == NSOrderedAscending) {
                    NSDate *adjustedDate = [PLDateFormatter adjustZeroClock:date];
                    if (![newAlbumDates containsObject:adjustedDate]) {
                        [newAlbumDates addObject:adjustedDate];
                    }
                }
            }];
        }
        else {
            if(completion) {
                completion(newAlbumDates, nil);
            }
        }
    } failureBlock:^(NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)enumurateAssetsWithCompletion:(void (^)(NSError *error))completion {
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized || [PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeUnknown) {
        if (completion) {
            completion([NSError errorWithDomain:kPLAssetsManagerErrorDomain code:500 userInfo:nil]);
        }
        return;
    }
    
    __weak typeof(self) wself = self;
    if (_isLibraryUpDated) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    _isLibraryUpDated = YES;
    
    NSDate *date = [NSDate date];
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate:date];
    NSDate *enumurateDate = [NSDate dateWithTimeInterval:seconds sinceDate:date];
    _lastEnumuratedDate = enumurateDate;
    
    NSManagedObjectContext *context = [PLCoreDataAPI writeContext];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // PhotoStreamはiCloud
        ALAssetsGroupType assetsGroupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupSavedPhotos;
        [_library enumerateGroupsWithTypes:assetsGroupType usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (![sself.lastEnumuratedDate isEqualToDate:enumurateDate]) return;
            if (group) {
                NSString *id_str = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
                NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
                NSNumber *albumType = [group valueForProperty:ALAssetsGroupPropertyType];
                NSURL *albumUrl = [group valueForProperty:ALAssetsGroupPropertyURL];
                NSNumber *tag_type = @(PLAlbumObjectTagTypeImported);
                
                __block PLAlbumObject *album = nil;
                [context performBlockAndWait:^{
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:@"PLAlbumObject" inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
                    request.fetchLimit = 1;
                    NSError *error = nil;
                    NSArray *tmpalbums = [context executeFetchRequest:request error:&error];
                    if (tmpalbums.count > 0) {
                        album = tmpalbums.firstObject;
                    }
                    else {
                        album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
                        album.name = name;
                        album.type = albumType;
                        album.id_str = id_str;
                        album.url = albumUrl.absoluteString;
                        album.import = enumurateDate;
                        album.tag_type = tag_type;
                    }
                    album.update = enumurateDate;
                }];
                
                NSMutableArray *allPhotos = @[].mutableCopy;
                [context performBlockAndWait:^{
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                    NSError *error = nil;
                    NSArray *objects = [context executeFetchRequest:request error:&error];
                    [allPhotos addObjectsFromArray:objects];
                }];
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    typeof(wself) sself = wself;
                    if (!sself || ![sself.lastEnumuratedDate isEqualToDate:enumurateDate] || !result) {
                        [PLCoreDataAPI writeContextFinish:context];
                        return;
                    }
                    
                    ALAssetRepresentation *representation = result.defaultRepresentation;
                    NSURL *url = representation.url;
                    CGSize dimensions = representation.dimensions;
                    NSString *filename = representation.filename;
                    NSString *type = [result valueForProperty:ALAssetPropertyType];
                    NSNumber *duration = nil;
                    if ([type isEqualToString:ALAssetTypeVideo]) {
                        duration = [result valueForProperty:ALAssetPropertyDuration];
                    }
                    NSDate *date = [result valueForProperty:ALAssetPropertyDate];
                    CLLocation *location = [result valueForProperty:ALAssetPropertyLocation];
                    [context performBlockAndWait:^{
                        NSArray *tmpphotos = [allPhotos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"url = %@", url.absoluteString]];
                        if (tmpphotos.count > 0) {
                            PLPhotoObject *photo = tmpphotos.firstObject;
                            photo.update = enumurateDate;
                        }
                        else {
                            PLPhotoObject *photo = [PLAssetsManager makeNewPhotoWithURL:url dimensions:dimensions filename:filename type:type date:date duration:duration location:location enumurateDate:enumurateDate albumType:albumType context:context];
                            
                            photo.tag_sort_index = @(album.photos.count);
                            [album addPhotosObject:photo];
                            
                            [allPhotos addObject:photo];
                        }
                        [PLCoreDataAPI writeContextFinish:context];
                    }];
                }];
            }
            else {
                //写真を全て読み込んだ後の処理だと思うわけよ
                [context performBlockAndWait:^{
                    typeof(wself) sself = wself;
                    if (!sself || !sself.isLibraryUpDated) {
                        [PLCoreDataAPI writeContextFinish:context];
                        return;
                    }
                    
                    //前回の読み込みから消えた写真
                    NSFetchRequest *outdatedPhotoRequest = [[NSFetchRequest alloc] init];
                    outdatedPhotoRequest.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                    outdatedPhotoRequest.predicate = [NSPredicate predicateWithFormat:@"update != %@", enumurateDate];
                    NSError *error = nil;
                    NSArray *outdatedPhotos = [context executeFetchRequest:outdatedPhotoRequest error:&error];
                    for (PLPhotoObject *photo in outdatedPhotos) {
                        [context deleteObject:photo];
                    }
                    
                    //NSLog(@"removed = %lu", (unsigned long)outdatedPhotos.count);
                    
                    NSInteger newAutoCreatAlbumCount = 0;
                    if (sself.autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeEnable) {
                        //今回の読み込みで追加された新規写真
                        NSFetchRequest *newPhotoRequest = [[NSFetchRequest alloc] init];
                        newPhotoRequest.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
                        newPhotoRequest.predicate = [NSPredicate predicateWithFormat:@"(tag_albumtype != %@) AND (import = %@)", @(ALAssetsGroupPhotoStream), enumurateDate];
                        newPhotoRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
                        error = nil;
                        NSArray *newPhotos = [context executeFetchRequest:newPhotoRequest error:&error];
                        //NSLog(@"new = %lu", (unsigned long)newPhotos.count);
                        
                        if (newPhotos.count > 0) {
                            //新規写真は振り分けをしなければならない
                            NSFetchRequest *request = [NSFetchRequest new];
                            request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                            request.predicate = [NSPredicate predicateWithFormat:@"(tag_type = %@) AND (edited = NO)", @(PLAlbumObjectTagTypeAutomatically)];
                            error = nil;
                            NSArray *tmpalbums = [context executeFetchRequest:request error:&error];
                            NSMutableArray *autoCreatedAlbums = tmpalbums.mutableCopy;
                            for (PLPhotoObject *newPhoto in newPhotos) {
                                NSDate *adjustedDate = [PLDateFormatter adjustZeroClock:newPhoto.date];
                                BOOL isDetected = NO;
                                for (PLAlbumObject *album in autoCreatedAlbums.reverseObjectEnumerator) {
                                    if ([album.tag_date isEqualToDate:adjustedDate]) {
                                        newPhoto.tag_sort_index = @(album.photos.count);
                                        [album addPhotosObject:newPhoto];
                                        isDetected = YES;
                                        break;
                                    }
                                }
                                if (!isDetected) {
                                    //自動作成版アルバムを作る
                                    PLAlbumObject *album = [PLAssetsManager makeNewAutoCreateAlbumWithEnumurateDate:enumurateDate adjustedDate:adjustedDate context:context];
                                    
                                    newPhoto.tag_sort_index = @(0);
                                    [album addPhotosObject:newPhoto];
                                    
                                    [autoCreatedAlbums addObject:album];
                                    newAutoCreatAlbumCount++;
                                }
                            }
                        }
                    }
                    
                    [context save:&error];
                    [PLCoreDataAPI writeContextFinish:context];
                    
                    if (completion) {
                        completion(error);
                    }
                    if (sself.libraryUpDateBlock) {
                        sself.libraryUpDateBlock(enumurateDate, newAutoCreatAlbumCount);
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

#pragma mark CoreDataMethods
+ (PLPhotoObject *)makeNewPhotoWithURL:(NSURL *)url dimensions:(CGSize)dimensions filename:(NSString *)filename type:(NSString *)type date:(NSDate *)date duration:(NSNumber *)duration location:(CLLocation *)location enumurateDate:(NSDate *)enumurateDate albumType:(NSNumber *)albumType context:(NSManagedObjectContext *)context {
    PLPhotoObject *photo = [NSEntityDescription insertNewObjectForEntityForName:kPLPhotoObjectName inManagedObjectContext:context];
    photo.url = url.absoluteString;
    photo.width = @(dimensions.width);
    photo.height = @(dimensions.height);
    photo.filename = filename;
    photo.type = type;
    photo.timestamp = @((long long)([date timeIntervalSince1970]) * 1000);
    photo.date = date;
    photo.duration = duration;
    photo.latitude = @(location.coordinate.latitude);
    photo.longitude = @(location.coordinate.longitude);
    photo.update = enumurateDate;
    photo.import = enumurateDate;
    photo.tag_albumtype = albumType;
    photo.id_str = url.query;
    
    return photo;
}

+ (PLAlbumObject *)makeNewAutoCreateAlbumWithEnumurateDate:(NSDate *)enumurateDate adjustedDate:(NSDate *)adjustedDate context:(NSManagedObjectContext *)context {
    PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
    album.id_str = [PWSnowFlake generateUniqueIDString];
    album.name = [[PLDateFormatter formatter] stringFromDate:adjustedDate];
    album.tag_date = adjustedDate;
    album.timestamp = @((long long)([adjustedDate timeIntervalSince1970]) * 1000);
    album.import = enumurateDate;
    album.update = enumurateDate;
    album.tag_type = @(PLAlbumObjectTagTypeAutomatically);
    
    return album;
}

@end
