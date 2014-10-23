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
#import "PADateFormatter.h"
#import "PADateTimestamp.h"
#import "PASnowFlake.h"

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
    return [[self sharedManager] library];
}

- (id)init {
    self = [super init];
    if (self) {
        _library = [ALAssetsLibrary new];
        
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
    [self getAlbumWithPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(kPLAlbumObjectTagTypeImported)] completion:completion];
}

- (void)getAutomatticallyCreatedAlbumWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self getAlbumWithPredicate:[NSPredicate predicateWithFormat:@"tag_type = %@", @(kPLAlbumObjectTagTypeAutomatically)] completion:completion];
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
                    NSDate *adjustedDate = [PADateFormatter adjustZeroClock:date];
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
        completion ? completion([NSError errorWithDomain:kPLAssetsManagerErrorDomain code:500 userInfo:nil]) : 0;
        return;
    }
    
    __weak typeof(self) wself = self;
    if (_isLibraryUpDated) {
        completion ? completion(nil) : 0;
        return;
    }
    _isLibraryUpDated = YES;
    
    NSDate *date = [NSDate date];
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate:date];
    NSDate *enumurateDate = [NSDate dateWithTimeInterval:seconds sinceDate:date];
    _lastEnumuratedDate = enumurateDate;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSManagedObjectContext *context = [PLCoreDataAPI writeContext];
        
        [_library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (![sself.lastEnumuratedDate isEqualToDate:enumurateDate]) return;
            if (group) {
                NSString *id_str = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
                NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
                NSNumber *albumType = [group valueForProperty:ALAssetsGroupPropertyType];
                NSURL *albumUrl = [group valueForProperty:ALAssetsGroupPropertyURL];
                NSNumber *tag_type = @(kPLAlbumObjectTagTypeImported);
                
                __block PLAlbumObject *album = nil;
                [context performBlockAndWait:^{
                    NSFetchRequest *request = [NSFetchRequest new];
                    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
                    request.fetchLimit = 1;
                    NSError *error = nil;
                    NSArray *tmpalbums = [context executeFetchRequest:request error:&error];
                    if (tmpalbums.count > 0) {
                        album = tmpalbums.firstObject;
                    }
                    else {
                        album = [PLAssetsManager makeNewAlbumWithName:name type:albumType id_str:id_str url:albumUrl enumurateDate:enumurateDate tag_type:tag_type context:context];
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
                        NSArray *tmpphotos = [allPhotos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@ ", url.query]];
                        if (tmpphotos.count > 0) {
                            PLPhotoObject *photo = tmpphotos.firstObject;
                            photo.update = enumurateDate;
                            
                            if (![album.photos.array containsObject:photo]) {
                                [album addPhotosObject:photo];
                            }
                        }
                        else {
                            PLPhotoObject *photo = [PLAssetsManager makeNewPhotoWithURL:url dimensions:dimensions filename:filename type:type date:date duration:duration location:location enumurateDate:enumurateDate albumType:albumType context:context];
                            
                            [album addPhotosObject:photo];
                            
                            [allPhotos addObject:photo];
                        }
                    }];
                }];
            }
            else {
                //写真を全て読み込んだ後の処理
                [context performBlockAndWait:^{
                    typeof(wself) sself = wself;
                    if (!sself || !sself.isLibraryUpDated) {
                        [PLCoreDataAPI writeContextFinish:context];
                        return;
                    }
                    
                    //前回の読み込みから消えた写真を削除
                    [PLAssetsManager deleteNoneAssetPhotoWithContext:context enumurateDate:enumurateDate];
                    
                    //今回の読み込みで追加された新規写真からアルバム作成
                    NSInteger newAutoCreatAlbumCount = 0;
                    if (sself.autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeEnable) {
                        newAutoCreatAlbumCount = [PLAssetsManager makeNewAlbumsFromNewPhotosWithContext:context enumurateDate:enumurateDate];
                    }

                    // 前日に撮った写真からアルバム作成
                    if (sself.autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeEnable) {
                        [PLAssetsManager makeYesterdayAlbumWithContext:context enumurateDate:enumurateDate];
                    }
                    
                    // 自動作成されたアルバムで写真枚数が0になったものを削除
                    [PLAssetsManager deleteAutoCreateAlbumsNoPhotosWithContext:context];
                    
                    NSError *error = nil;
                    if (![context save:&error]) {
#ifdef DEBUG
                        NSLog(@"%@", error);
#endif
                        abort();
                    }
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
    photo.timestamp = [PADateTimestamp timestampByNumberForDate:date];
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

+ (PLAlbumObject *)makeNewAlbumWithName:(NSString *)name type:(NSNumber *)type id_str:(NSString *)id_str url:(NSURL *)url enumurateDate:(NSDate *)enumurateDate tag_type:(NSNumber *)tag_type context:(NSManagedObjectContext *)context {
    PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
    album.name = name;
    album.type = type;
    album.id_str = id_str;
    album.url = url.absoluteString;
    album.import = enumurateDate;
    album.tag_type = tag_type;
    return album;
}

+ (PLAlbumObject *)makeNewAutoCreateAlbumWithEnumurateDate:(NSDate *)enumurateDate adjustedDate:(NSDate *)adjustedDate context:(NSManagedObjectContext *)context {
    PLAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
    album.id_str = [PASnowFlake generateUniqueIDString];
    album.name = [[PADateFormatter formatter] stringFromDate:adjustedDate];
    album.tag_date = adjustedDate;
    album.timestamp = [PADateTimestamp timestampByNumberForDate:adjustedDate];
    album.import = enumurateDate;
    album.update = enumurateDate;
    album.tag_type = @(kPLAlbumObjectTagTypeAutomatically);
    return album;
}

+ (void)deleteNoneAssetPhotoWithContext:(NSManagedObjectContext *)context enumurateDate:(NSDate *)enumurateDate {
    NSFetchRequest *outdatedPhotoRequest = [NSFetchRequest new];
    outdatedPhotoRequest.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
    outdatedPhotoRequest.predicate = [NSPredicate predicateWithFormat:@"update != %@", enumurateDate];
    NSError *error = nil;
    NSArray *outdatedPhotos = [context executeFetchRequest:outdatedPhotoRequest error:&error];
    for (PLPhotoObject *photo in outdatedPhotos) {
        [context deleteObject:photo];
    }
    outdatedPhotos = nil;
}

+ (NSUInteger)makeNewAlbumsFromNewPhotosWithContext:(NSManagedObjectContext *)context enumurateDate:(NSDate *)enumurateDate {
    NSInteger newAutoCreatAlbumCount = 0;
    
    NSFetchRequest *newPhotoRequest = [NSFetchRequest new];
    newPhotoRequest.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
    newPhotoRequest.predicate = [NSPredicate predicateWithFormat:@"(tag_albumtype != %@) AND (import = %@)", @(ALAssetsGroupPhotoStream), enumurateDate];
    newPhotoRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    NSError *error = nil;
    NSArray *newPhotos = [context executeFetchRequest:newPhotoRequest error:&error];
    //NSLog(@"new = %lu", (unsigned long)newPhotos.count);
    
    NSDate *todayAdjustedDate = [PADateFormatter adjustZeroClock:[NSDate date]];
    if (newPhotos.count > 0) {
        //新規写真は振り分けをしなければならない
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"(tag_type = %@) AND (edited = NO)", @(kPLAlbumObjectTagTypeAutomatically)];
        error = nil;
        NSMutableArray *autoCreatedAlbums = [context executeFetchRequest:request error:&error].mutableCopy;
        for (PLPhotoObject *newPhoto in newPhotos) {
            NSDate *adjustedDate = [PADateFormatter adjustZeroClock:newPhoto.date];
            BOOL isDetected = NO;
            for (PLAlbumObject *album in autoCreatedAlbums.reverseObjectEnumerator) {
                if ([album.tag_date isEqualToDate:adjustedDate]) {
                    [album addPhotosObject:newPhoto];
                    isDetected = YES;
                    break;
                }
            }
            if (!isDetected) {
                //今日のやつはアルバムを作らない
                if (![adjustedDate isEqualToDate:todayAdjustedDate]) {
                    //自動作成版アルバムを作る
                    PLAlbumObject *album = [PLAssetsManager makeNewAutoCreateAlbumWithEnumurateDate:enumurateDate adjustedDate:adjustedDate context:context];
                    
                    [album addPhotosObject:newPhoto];
                    
                    [autoCreatedAlbums addObject:album];
                    newAutoCreatAlbumCount++;
                }
            }
        }
    }
    
    return newAutoCreatAlbumCount;
}

+ (void)makeYesterdayAlbumWithContext:(NSManagedObjectContext *)context enumurateDate:(NSDate *)enumurateDate {
    NSDate *adjustedDate = [PADateFormatter adjustZeroClock:[NSDate date]];
    NSDate *adjustedYesterday = [adjustedDate dateByAddingTimeInterval: - 24.0f * 60.0f * 60.0f];
    
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"(tag_type = %@) AND (edited = NO) AND (tag_date = %@)", @(kPLAlbumObjectTagTypeAutomatically), adjustedYesterday];
    NSError *error = nil;
    NSArray *yesterdayAlbums = [context executeFetchRequest:request error:&error];
    if (yesterdayAlbums.count == 0) {
        //今回の読み込みで追加された新規写真
        NSFetchRequest *newPhotoRequest = [NSFetchRequest new];
        newPhotoRequest.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        newPhotoRequest.predicate = [NSPredicate predicateWithFormat:@"(tag_albumtype != %@) AND (date >= %@) AND (date < %@)", @(ALAssetsGroupPhotoStream), adjustedYesterday, adjustedDate];
        newPhotoRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
        NSError *error = nil;
        NSArray *yesterdayPhotos = [context executeFetchRequest:newPhotoRequest error:&error];
        if (yesterdayPhotos.count > 0) {
            PLAlbumObject *album = [PLAssetsManager makeNewAutoCreateAlbumWithEnumurateDate:enumurateDate adjustedDate:adjustedYesterday context:context];
            for (PLPhotoObject *photo in yesterdayPhotos) {
                [album addPhotosObject:photo];
            }
        }
    }
}

+ (void)deleteAutoCreateAlbumsNoPhotosWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"(tag_type = %@) AND (edited = NO)", @(kPLAlbumObjectTagTypeAutomatically)];
    NSError *error = nil;
    NSArray *autoCreatedAlbums = [context executeFetchRequest:request error:&error];
    for (PLAlbumObject *album in autoCreatedAlbums) {
        if (album.photos.count == 0) {
            [context deleteObject:album];
        }
    }
}

@end
