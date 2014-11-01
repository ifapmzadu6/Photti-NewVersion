//
//  PDWebPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDWebPhotoObject+methods.h"

@import Photos;

#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PWCoreDataAPI.h"
#import "PWModelObject.h"
#import "PASnowFlake.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PADateTimestamp.h"
#import "PAPhotoKit.h"

static NSString * const kPDWebPhotoObjectMethodsErrorDomain = @"com.photti.PDWebPhotoObjectMethods";

@implementation PDWebPhotoObject (methods)

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    __block PWPhotoObject *photoObject = nil;
    __block kPWPhotoObjectType tag_type = kPWPhotoObjectTypeUnknown;
    __block NSArray *contents = nil;
    NSString *photoObjectID = self.photo_object_id_str;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", photoObjectID];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count > 0) {
            photoObject = photos.firstObject;
            tag_type = (kPWPhotoObjectType)photoObject.tag_type.integerValue;
            contents = photoObject.media.content.array;
        }
    }];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    
    NSURL *url = nil;
    if (tag_type == kPWPhotoObjectTypePhoto) {
        url = [NSURL URLWithString:photoObject.tag_originalimage_url];
    }
    else if (tag_type == kPWPhotoObjectTypeVideo) {
        NSArray *mp4contents = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @"video/mpeg4"]];
        mp4contents = [mp4contents sortedArrayUsingComparator:^NSComparisonResult(PWPhotoMediaContentObject * obj1, PWPhotoMediaContentObject * obj2) {
            return MAX(obj1.width.integerValue, obj1.height.integerValue) > MAX(obj2.width.integerValue, obj2.height.integerValue);
        }];
        if (mp4contents.count > 0) {
            PWPhotoMediaContentObject *content = mp4contents.lastObject;
            url = [NSURL URLWithString:content.url];
        }
    }
    NSManagedObjectID *selfObjectID = self.objectID;
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        NSURLSessionTask *sessionTask = [session downloadTaskWithRequest:request];
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDWebPhotoObject *selfObject = (PDWebPhotoObject *)[context objectWithID:selfObjectID];
            selfObject.session_task_identifier = @(sessionTask.taskIdentifier);
        }];
        
        completion ? completion(sessionTask, nil) : 0;
    }];
};

- (void)finishDownloadWithLocation:(NSURL *)location completion:(void (^)(NSError *))completion {
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        [self newFinishDownloadWithLocation:location completion:completion];
    }
    else {
        [self oldFinishDownloadWithLocation:location completion:completion];
    }
}

- (void)newFinishDownloadWithLocation:(NSURL *)location completion:(void (^)(NSError *))completion {
    PDTaskObject *taskObject = self.task;
    NSManagedObjectID *taskObjectID = taskObject.objectID;
    NSString *local_album_id_str = taskObject.to_album_id_str;
    NSString *web_album_id_str = taskObject.from_album_id_str;
    NSString *web_photo_id_str = self.photo_object_id_str;
    NSManagedObjectID *selfObjectID = self.objectID;
    
    __block NSString *contentType = nil;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        PWPhotoObject *photoObject = [PDWebPhotoObject getWebPhotoObjectWithID:web_photo_id_str context:context];
        contentType = photoObject.content_type;
    }];
    __block NSString *albumTitle = nil;
    [PWCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PWAlbumObject *albumObject = [PDWebPhotoObject getWebAlbumWithID:web_album_id_str context:context];
        albumTitle = albumObject.title;
    }];
    
    PHAssetCollection *assetCollection = [PAPhotoKit getAssetCollectionWithIdentifier:local_album_id_str];
    if (!assetCollection) {
        __block NSString *assetCollectionIdentifier = nil;
        NSError *error = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumTitle];
            PHObjectPlaceholder *placeholder = changeRequest.placeholderForCreatedAssetCollection;
            assetCollectionIdentifier = placeholder.localIdentifier;
        } error:&error];
        if (error) {
            completion ? completion(error) : 0;
            return;
        }
        PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionIdentifier] options:nil];
        assetCollection = fetchResult.firstObject;
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *tmpTaskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            tmpTaskObject.to_album_id_str = assetCollectionIdentifier;
        }];
    }
    
    NSString *filePath = nil;
    if ([contentType isEqualToString:kPWPhotoObjectContentType_mp4]) {
        filePath = [location.absoluteString stringByAppendingPathExtension:@"mp4"];
    }
    else if ([contentType isEqualToString:kPWPhotoObjectContentType_jpeg]) {
        filePath = [location.absoluteString stringByAppendingPathExtension:@"jpeg"];
    }
    else if ([contentType isEqualToString:kPWPhotoObjectContentType_png]) {
        filePath = [location.absoluteString stringByAppendingPathExtension:@"png"];
    }
    if (filePath) {
        NSURL *newLocation = [NSURL URLWithString:filePath];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:newLocation error:&error]) {
            completion ? completion(error) : 0;
            return;
        }
        location = newLocation;
    }
    else {
        completion ? completion([NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    
    NSError *error = nil;
    __block NSString *assetIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetChangeRequest *assetRequest = nil;
        if ([contentType isEqualToString:kPWPhotoObjectContentType_mp4]) {
            assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:location];
        }
        else {
            assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:location];
        }
        PHObjectPlaceholder *asset = assetRequest.placeholderForCreatedAsset;
        assetIdentifier = asset.localIdentifier;
    } error:&error];
    if (error) {
        completion ? completion(error) : 0;
        return;
    }
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetIdentifier] options:nil];
    if (result.count == 0) {
        completion ? completion([NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    PHAsset *asset = result.firstObject;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *assetCollectionRequest = nil;
        if (assetCollection) {
            assetCollectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        }
        else {
            assetCollectionRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumTitle];
        }
        [assetCollectionRequest addAssets:@[asset]];
    } error:&error];
    if (error) {
        completion ? completion(error) : 0;
        return;
    }
    
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDWebPhotoObject *webObject = (PDWebPhotoObject *)[context objectWithID:selfObjectID];
        webObject.is_done = @(YES);
    }];
    
    if (![[NSFileManager defaultManager] removeItemAtURL:location error:&error]) {
        completion ? completion(error) : 0;
        return;
    }
    
    completion ? completion(nil) : 0;
}

- (void)oldFinishDownloadWithLocation:(NSURL *)location completion:(void (^)(NSError *))completion {
    PDTaskObject *taskObject = self.task;
    NSManagedObjectID *taskObjectID = taskObject.objectID;
    
    NSString *local_album_id_str = taskObject.to_album_id_str;
    NSString *web_album_id_str = taskObject.from_album_id_str;
    NSManagedObjectID *selfObjectID = self.objectID;
    
    NSManagedObjectContext *plContext = [PLCoreDataAPI writeContext];
    
    __block PLAlbumObject *localAlbumObject = [PDWebPhotoObject getLocalAlbumIfNeededMakeNewOneAlbumID:local_album_id_str webAlbumID:web_album_id_str taskObjectID:taskObjectID context:plContext];
    if (!localAlbumObject) {
        completion ? completion([NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    __block NSUInteger localAlbumObjectTagType = localAlbumObject.tag_type.integerValue;
    __block NSString *localAlbumObjectURL = localAlbumObject.url;
    __block NSManagedObjectID *localAlbumObjectID = localAlbumObject.objectID;
    
    if (localAlbumObjectTagType == kPLAlbumObjectTagTypeImported) {
        [plContext performBlockAndWait:^{
            NSError *error = nil;
            if (![plContext save:&error]) {
                abort();
            }
        }];
        [PLCoreDataAPI writeContextFinish:plContext];
    }
    
    void (^completionBlock)(NSURL *, NSError *) = ^(NSURL *assetURL, NSError *error){
        if (error || !assetURL) {
            [PLCoreDataAPI writeContextFinish:plContext];
            return;
        }
        
        [[PLAssetsManager sharedLibrary] assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            if (!asset) {
                [PLCoreDataAPI writeContextFinish:plContext];
                return;
            }
            
            if (localAlbumObjectTagType == kPLAlbumObjectTagTypeImported) {
                [[PLAssetsManager sharedLibrary] groupForURL:[NSURL URLWithString:localAlbumObjectURL] resultBlock:^(ALAssetsGroup *group) {
                    if (!group) {
                        [PLCoreDataAPI writeContextFinish:plContext];
                        return;
                    }
                    
                    [group addAsset:asset];
                    
                    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                        PDWebPhotoObject *webObject = (PDWebPhotoObject *)[context objectWithID:selfObjectID];
                        webObject.is_done = @(YES);
                    }];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion ? completion(nil) : 0;
                    });
                } failureBlock:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion ? completion(error) : 0;
                    });
                }];
            }
            else {
                ALAssetRepresentation *representation = asset.defaultRepresentation;
                NSURL *url = representation.url;
                CGSize dimensions = representation.dimensions;
                NSString *filename = representation.filename;
                NSString *type = [asset valueForProperty:ALAssetPropertyType];
                NSNumber *duration = nil;
                if ([type isEqualToString:ALAssetTypeVideo]) {
                    duration = [asset valueForProperty:ALAssetPropertyDuration];
                }
                NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
                CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
                
                [plContext performBlockAndWait:^{
                    PLAlbumObject *album = (PLAlbumObject *)[plContext objectWithID:localAlbumObjectID];
                    PLPhotoObject *photo = [PDWebPhotoObject makeNewPhotoWithURL:url dimensions:dimensions filename:filename type:type date:date duration:duration location:location enumurateDate:[NSDate date] albumType:album.tag_type context:plContext];
                    [album addPhotosObject:photo];
                    
                    NSError *error = nil;
                    if (![plContext save:&error]) {
                        abort();
                    }
                }];
                
                [PLCoreDataAPI writeContextFinish:plContext];
                
                [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                    PDWebPhotoObject *webObject = (PDWebPhotoObject *)[context objectWithID:selfObjectID];
                    if (webObject) {
                        webObject.is_done = @(YES);
                    }
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion ? completion(nil) : 0;
                });
            }
        } failureBlock:^(NSError *error) {
            [PLCoreDataAPI writeContextFinish:plContext];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(error);
                }
            });
        }];
    };
    
    PWPhotoObject *webPhotoObject = [PDWebPhotoObject getWebPhotoObjectWithID:self.photo_object_id_str context:[PWCoreDataAPI readContext]];
    if (webPhotoObject.tag_type.integerValue == kPWPhotoObjectTypePhoto) {
        NSData *data = [NSData dataWithContentsOfURL:location];
        [[PLAssetsManager sharedLibrary] writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:completionBlock];
    }
    else if (webPhotoObject.tag_type.integerValue == kPWPhotoObjectTypeVideo) {
        NSURL *newLocation = [location URLByAppendingPathExtension:@"mp4"];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:newLocation error:&error]) {
            return;
        }
        if ([[PLAssetsManager sharedLibrary] videoAtPathIsCompatibleWithSavedPhotosAlbum:newLocation]) {
            [[PLAssetsManager sharedLibrary] writeVideoAtPathToSavedPhotosAlbum:newLocation completionBlock:completionBlock];
        }
        else {
            completion ? completion([NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        }
    }
}


#pragma mark GetData
+ (PLAlbumObject *)getLocalAlbumWithID:(NSString *)id_str context:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *albums = [context executeFetchRequest:request error:&error];
    if (albums.count > 0) {
        return albums.firstObject;
    }
    return nil;
}

+ (PLAlbumObject *)getLocalAlbumIfNeededMakeNewOneAlbumID:(NSString *)id_str webAlbumID:(NSString *)web_album_id_str taskObjectID:(NSManagedObjectID *)taskObjectID context:(NSManagedObjectContext *)plContext {
    __block PLAlbumObject *localAlbumObject = [PDWebPhotoObject getLocalAlbumWithID:id_str context:plContext];
    __block NSString *newLocalAlbumID = nil;
    if (!localAlbumObject) {
        //アルバムがないので新しく作る
        [plContext performBlockAndWait:^{
            PWAlbumObject *webAlbumObject = [PDWebPhotoObject getWebAlbumWithID:web_album_id_str context:[PWCoreDataAPI readContext]];
            
            localAlbumObject = [PDWebPhotoObject makeNewLocalAlbumWithWebAlbum:webAlbumObject context:plContext];
            newLocalAlbumID = localAlbumObject.id_str;
        }];
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *task = (PDTaskObject *)[context objectWithID:taskObjectID];
            task.to_album_id_str = newLocalAlbumID;
        }];
    }
    return localAlbumObject;
}

+ (PWAlbumObject *)getWebAlbumWithID:(NSString *)id_str context:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *albums = [context executeFetchRequest:request error:&error];
    if (albums.count > 0) {
        return albums.firstObject;
    }
    return nil;
}

+ (PWPhotoObject *)getWebPhotoObjectWithID:(NSString *)id_str context:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects.firstObject;
    }
    return nil;
}

#pragma mark MakeData
+ (PLAlbumObject *)makeNewLocalAlbumWithWebAlbum:(PWAlbumObject *)webAlbumObject context:(NSManagedObjectContext *)context {
    PLAlbumObject *localAlbumObject = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
    localAlbumObject.id_str = [PASnowFlake generateUniqueIDString];
    localAlbumObject.name = webAlbumObject.title;
    localAlbumObject.tag_date = [PADateTimestamp dateForTimestamp:webAlbumObject.gphoto.timestamp];
    localAlbumObject.timestamp = @(webAlbumObject.gphoto.timestamp.longLongValue);
    NSDate *enumurateDate = [NSDate date];
    localAlbumObject.import = enumurateDate;
    localAlbumObject.update = enumurateDate;
    localAlbumObject.tag_type = @(kPLAlbumObjectTagTypeAutomatically);
    return localAlbumObject;
}

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


@end
