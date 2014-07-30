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
#import "PWSnowFlake.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"

static NSString * const kPDWebPhotoObjectMethodsErrorDomain = @"com.photti.PDWebPhotoObjectMethods";

@implementation PDWebPhotoObject (methods)

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    __block PWPhotoObject *photoObject = nil;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", self.photo_object_id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count > 0) {
            photoObject = photos.firstObject;
        }
    }];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDWebPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    
    NSURL *url = [NSURL URLWithString:photoObject.tag_originalimage_url];
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        NSURLSessionTask *sessionTask = [session downloadTaskWithRequest:request];
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            self.session_task_identifier = @(sessionTask.taskIdentifier);
        }];
        
        completion ? completion(sessionTask, nil) : 0;
    }];
};

- (void)finishDownloadWithData:(NSData *)data completion:(void (^)(NSError *))completion {
    PDTaskObject *taskObject = self.task;
    NSString *local_album_id_str = taskObject.to_album_id_str;
    NSString *web_album_id_str = taskObject.from_album_id_str;
    NSManagedObjectID *taskObjectID = taskObject.objectID;
    NSManagedObjectID *objectID = self.objectID;
    
    [[PLAssetsManager sharedLibrary] writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        __block PLAlbumObject *localAlbumObject = [[self class] getLocalAlbumWithID:local_album_id_str];
        if (!localAlbumObject) {
            //アルバムがないので新しく作る
            [[self class] getWebAlbumWithID:web_album_id_str completion:^(PWAlbumObject *webAlbumObject) {
                localAlbumObject = [[self class] makeNewLocalAlbumWithWebAlbum:webAlbumObject];
            }];
            
            NSString *id_str = localAlbumObject.id_str;
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDTaskObject *task = (PDTaskObject *)[context objectWithID:taskObjectID];
                task.to_album_id_str = id_str;
            }];
        }
        
        NSUInteger localAlbumObjectTagType = localAlbumObject.tag_type.integerValue;
        NSString *localAlbumObjectURL = localAlbumObject.url;
        NSManagedObjectID *localAlbumObjectID = localAlbumObject.objectID;
        [[PLAssetsManager sharedLibrary] assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            if (localAlbumObjectTagType == PLAlbumObjectTagTypeImported) {
                [[PLAssetsManager sharedLibrary] groupForURL:[NSURL URLWithString:localAlbumObjectURL] resultBlock:^(ALAssetsGroup *group) {
                    [group addAsset:asset];
                    
                    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                        PDWebPhotoObject *webObject = (PDWebPhotoObject *)[context objectWithID:objectID];
                        webObject.is_done = @(YES);
                    }];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        if (completion) {
                            completion(nil);
                        }
                    });
                } failureBlock:^(NSError *error) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        if (completion) {
                            completion(error);
                        }
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
                
                [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                    PLAlbumObject *album = (PLAlbumObject *)[context objectWithID:localAlbumObjectID];
                    PLPhotoObject *photo = [[self class] makeNewPhotoWithURL:url dimensions:dimensions filename:filename type:type date:date duration:duration location:location enumurateDate:[NSDate date] albumType:album.tag_type context:context];
                    [album addPhotosObject:photo];
                }];
                
                [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                    PDWebPhotoObject *webObject = (PDWebPhotoObject *)[context objectWithID:objectID];
                    webObject.is_done = @(YES);
                }];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    if (completion) {
                        completion(nil);
                    }
                });
            }
        } failureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                if (completion) {
                    completion(error);
                }
            });
        }];
    }];
}


#pragma mark GetData
+ (PLAlbumObject *)getLocalAlbumWithID:(NSString *)id_str {
    __block PLAlbumObject *localAlbumObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (albums.count > 0) {
            localAlbumObject = albums.firstObject;
        }
    }];
    return localAlbumObject;
}

+ (void)getWebAlbumWithID:(NSString *)id_str completion:(void (^)(PWAlbumObject *webAlbumObject))completion {
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (albums.count > 0) {
            if (completion) {
                completion(albums.firstObject);
            }
        }
    }];
}

#pragma mark MakeData
+ (PLAlbumObject *)makeNewLocalAlbumWithWebAlbum:(PWAlbumObject *)webAlbumObject {
    __block PLAlbumObject *localAlbumObject = nil;
    [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        localAlbumObject = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
        localAlbumObject.id_str = [PWSnowFlake generateUniqueIDString];
        localAlbumObject.name = webAlbumObject.title;
        localAlbumObject.tag_date = [NSDate dateWithTimeIntervalSince1970:webAlbumObject.timestamp.longLongValue / 1000];
        localAlbumObject.timestamp = @(webAlbumObject.timestamp.longLongValue);
        NSDate *enumurateDate = [NSDate date];
        localAlbumObject.import = enumurateDate;
        localAlbumObject.update = enumurateDate;
        localAlbumObject.tag_type = @(PLAlbumObjectTagTypeAutomatically);
    }];
    return localAlbumObject;
}

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

@end
