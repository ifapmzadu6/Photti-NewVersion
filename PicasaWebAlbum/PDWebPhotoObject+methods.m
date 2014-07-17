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

@implementation PDWebPhotoObject (methods)

- (NSURLSessionTask *)makeSessionTaskWithSession:(NSURLSession *)session {
    __block NSMutableURLRequest *request = nil;
    
    __block PWPhotoObject *photoObject = nil;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", self.photo_object_id_str];
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count > 0) {
            photoObject = photos.firstObject;
        }
    }];
    
    NSURL *url = [NSURL URLWithString:photoObject.tag_originalimage_url];
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *authorizedRequest, NSError *error) {
        request = authorizedRequest;
    }];
    
    if (!request) {
        return nil;
    }
    else {
        return [session downloadTaskWithRequest:request];
    }
};

- (void)finishDownloadWithData:(NSData *)data completion:(void (^)(NSError *))completion {
    PDBaseTaskObject *baseTaskObject = self.task;
    PDWebToLocalAlbumTaskObject *webToLocalAlbumTask = (PDWebToLocalAlbumTaskObject *)baseTaskObject;
    
    [[PLAssetsManager sharedLibrary] writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        __block PLAlbumObject *localAlbumObject = [[self class] getLocalAlbumWithID:webToLocalAlbumTask.destination_album_object_id_str];
        if (!localAlbumObject) {
            //アルバムがないので新しく作る
            [[self class] getWebAlbumWithID:webToLocalAlbumTask.album_object_id_str completion:^(PWAlbumObject *webAlbumObject) {
                localAlbumObject = [[self class] makeNewLocalAlbumWithWebAlbum:webAlbumObject];
            }];
            
            NSString *id_str = localAlbumObject.id_str;
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                webToLocalAlbumTask.destination_album_object_id_str = id_str;
            }];
        }
        
        [[PLAssetsManager sharedLibrary] assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            if (localAlbumObject.tag_type.integerValue == PLAlbumObjectTagTypeImported) {
                [[PLAssetsManager sharedLibrary] groupForURL:[NSURL URLWithString:localAlbumObject.url] resultBlock:^(ALAssetsGroup *group) {
                    [group addAsset:asset];
                    
                    if (completion) {
                        completion(nil);
                    }
                } failureBlock:^(NSError *error) {
                    if (completion) {
                        completion(error);
                    }
                }];
            }
            else {
                [PLCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                    PLPhotoObject *photo = [[self class] makeNewPhotoWithAsset:asset];
                    [localAlbumObject addPhotosObject:photo];
                }];
                
                if (completion) {
                    completion(nil);
                }
            }
        } failureBlock:^(NSError *error) {
            if (completion) {
                completion(error);
            }
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

+ (PLPhotoObject *)makeNewPhotoWithAsset:(ALAsset *)asset {
    __block PLPhotoObject *photoObject = nil;
    [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        photoObject = [NSEntityDescription insertNewObjectForEntityForName:kPLPhotoObjectName inManagedObjectContext:context];
        NSURL *url = asset.defaultRepresentation.url;
        photoObject.url = url.absoluteString;
        CGSize dimensions = asset.defaultRepresentation.dimensions;
        photoObject.width = @(dimensions.width);
        photoObject.height = @(dimensions.height);
        photoObject.filename = asset.defaultRepresentation.filename;
        photoObject.type = [asset valueForProperty:ALAssetPropertyType];
        NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
        photoObject.timestamp = @((long long)([date timeIntervalSince1970]) * 1000);
        CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
        photoObject.date = date;
        photoObject.latitude = @(location.coordinate.latitude);
        photoObject.longitude = @(location.coordinate.longitude);
        NSDate *enumurateDate = [NSDate date];
        photoObject.update = enumurateDate;
        photoObject.import = enumurateDate;
        
        photoObject.tag_albumtype = @(PLAlbumObjectTagTypeImported);
        photoObject.id_str = url.query;
    }];
    return photoObject;
}

@end
