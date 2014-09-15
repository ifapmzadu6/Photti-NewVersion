//
//  PDWebPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDWebPhotoObject+methods.h"

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

static NSString * const kPDWebPhotoObjectMethodsErrorDomain = @"com.photti.PDWebPhotoObjectMethods";

@implementation PDWebPhotoObject (methods)

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    __block PWPhotoObject *photoObject = nil;
    __block PWPhotoManagedObjectType tag_type = PWPhotoManagedObjectTypeUnknown;
    __block NSArray *contents = nil;
    NSString *photoObjectID = self.photo_object_id_str;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", photoObjectID];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count > 0) {
            photoObject = photos.firstObject;
            tag_type = (PWPhotoManagedObjectType)photoObject.tag_type.integerValue;
            contents = photoObject.media.content.array;
        }
    }];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    
    NSURL *url = nil;
    if (tag_type == PWPhotoManagedObjectTypePhoto) {
        url = [NSURL URLWithString:photoObject.tag_originalimage_url];
    }
    else if (tag_type == PWPhotoManagedObjectTypeVideo) {
        NSArray *mp4contents = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @"video/mpeg4"]];
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
    PDTaskObject *taskObject = self.task;
    NSString *local_album_id_str = taskObject.to_album_id_str;
    NSString *web_album_id_str = taskObject.from_album_id_str;
    NSManagedObjectID *taskObjectID = taskObject.objectID;
    NSManagedObjectID *objectID = self.objectID;
    
    NSManagedObjectContext *plContext = [PLCoreDataAPI writeContext];
    
    __block PLAlbumObject *localAlbumObject = [PDWebPhotoObject getLocalAlbumWithID:local_album_id_str context:plContext];
    __block NSString *id_str = nil;
    __block NSUInteger localAlbumObjectTagType = NSUIntegerMax;
    __block NSString *localAlbumObjectURL = nil;
    __block NSManagedObjectID *localAlbumObjectID = nil;
    if (!localAlbumObject) {
        //アルバムがないので新しく作る
        [plContext performBlockAndWait:^{
            PWAlbumObject *webAlbumObject = [PDWebPhotoObject getWebAlbumWithID:web_album_id_str context:[PWCoreDataAPI readContext]];
            
            localAlbumObject = [PDWebPhotoObject makeNewLocalAlbumWithWebAlbum:webAlbumObject context:plContext];
            id_str = localAlbumObject.id_str;
            localAlbumObjectTagType = localAlbumObject.tag_type.integerValue;
            localAlbumObjectURL = localAlbumObject.url;
            localAlbumObjectID = localAlbumObject.objectID;
        }];
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *task = (PDTaskObject *)[context objectWithID:taskObjectID];
            task.to_album_id_str = id_str;
        }];
    }
    else {
        id_str = localAlbumObject.id_str;
        localAlbumObjectTagType = localAlbumObject.tag_type.integerValue;
        localAlbumObjectURL = localAlbumObject.url;
        localAlbumObjectID = localAlbumObject.objectID;
    }
    if (!localAlbumObject) {
        completion ? completion([NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    
    if (localAlbumObjectTagType == PLAlbumObjectTagTypeImported) {
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
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            [PLCoreDataAPI writeContextFinish:plContext];
            return;
        }
        
        [[PLAssetsManager sharedLibrary] assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            if (!asset) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                [PLCoreDataAPI writeContextFinish:plContext];
                return;
            }
            
            if (localAlbumObjectTagType == PLAlbumObjectTagTypeImported) {
                [[PLAssetsManager sharedLibrary] groupForURL:[NSURL URLWithString:localAlbumObjectURL] resultBlock:^(ALAssetsGroup *group) {
                    if (!group) {
#ifdef DEBUG
                        NSLog(@"%@", error);
#endif
                        [PLCoreDataAPI writeContextFinish:plContext];
                        return;
                    }
                    
                    [group addAsset:asset];
                    
                    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                        PDWebPhotoObject *webObject = (PDWebPhotoObject *)[context objectWithID:objectID];
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
                    PDWebPhotoObject *webObject = (PDWebPhotoObject *)[context objectWithID:objectID];
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
    if (webPhotoObject.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
        NSData *data = [NSData dataWithContentsOfURL:location];
        [[PLAssetsManager sharedLibrary] writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:completionBlock];
    }
    else if (webPhotoObject.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
        NSURL *newLocation = [location URLByAppendingPathExtension:@"mp4"];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:newLocation error:&error]) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
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

+ (PWAlbumObject *)getWebAlbumWithID:(NSString *)id_str context:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
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
    request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
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
    localAlbumObject.tag_type = @(PLAlbumObjectTagTypeAutomatically);
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
