//
//  PDTaskObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskObjectFactoryMethods.h"

#import "PDModelObject.h"
#import "PDCoreDataAPI.h"
#import "PDTaskObject.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "NSFileManager+methods.h"

@implementation PDTaskObjectFactoryMethods

+ (void)makeTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *webAlbumId = fromWebAlbum.id_str;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray *photoObjectIDs = @[].mutableCopy;
        NSMutableDictionary *photoObjectSortIndexs = @{}.mutableCopy;
        [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPWPhotoObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", webAlbumId];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
            NSError *error = nil;
            NSArray *photos = [context executeFetchRequest:request error:&error];
            if (error) {
                completion ? completion(nil, error) : 0;
                return;
            }
            if (photos.count == 0) {
                completion ? completion(nil, [NSError errorWithDomain:@"PDTaskObject (methods)" code:0 userInfo:nil]) : 0;
                return;
            }
            
            BOOL isContainGif = NO;
            for (PWPhotoObject *photoObject in photos) {
                NSOrderedSet *filterdContent = [photoObject.media.content filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", kPWPhotoObjectContentType_mp4]];
                if ((filterdContent.count == 0) && [photoObject.content_type isEqualToString:kPWPhotoObjectContentType_gif]) {
                    isContainGif = YES;
                }
                else {
                    [photoObjectIDs addObject:photoObject.id_str];
                    [photoObjectSortIndexs setObject:photoObject.sortIndex forKey:photoObject.id_str];
                }
            }
            if (isContainGif) {
                [PDTaskObjectFactoryMethods showNotSupportGifSkipAlertView];
            }
        }];
        
        __block NSManagedObjectID *taskObjectID = nil;
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:kPDTaskObjectName inManagedObjectContext:context];
            taskObject.type = @(PDTaskObjectTypeWebAlbumToLocalAlbum);
            taskObject.from_album_id_str = webAlbumId;
            
            for (NSString *photoObjectID in photoObjectIDs) {
                PDWebPhotoObject *webPhoto = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDWebPhotoObject class]) inManagedObjectContext:context];
                webPhoto.photo_object_id_str = photoObjectID;
                webPhoto.tag_sort_index = photoObjectSortIndexs[photoObjectID];
                webPhoto.task = taskObject;
                [taskObject addPhotosObject:webPhoto];
            }
            
            taskObjectID = taskObject.objectID;
        }];
        
        completion ? completion(taskObjectID, nil) : 0;
    });
}

+ (void)makeTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *fromLocalAlbumID = fromLocalAlbum.id_str;
    NSString *toWebAlbumID = toWebAlbum.id_str;
    NSOrderedSet *fromLocalAlbums = fromLocalAlbum.photos;
    
    __block NSManagedObjectID *taskObjectID = nil;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:kPDTaskObjectName inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypeLocalAlbumToWebAlbum);
        taskObject.from_album_id_str = fromLocalAlbumID;
        taskObject.to_album_id_str = toWebAlbumID;
        taskObjectID = taskObject.objectID;
        
        NSMutableArray *id_strs = @[].mutableCopy;
        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            for (PLPhotoObject *photoObject in fromLocalAlbums) {
                [id_strs addObject:photoObject.id_str];
            }
        }];
        
        for (NSString *id_str in id_strs) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDLocalPhotoObject class]) inManagedObjectContext:context];
            localPhoto.photo_object_id_str = id_str;
            localPhoto.task = taskObject;
            [taskObject addPhotosObject:localPhoto];
        }
    }];
    
    completion ? completion(taskObjectID, nil) : 0;
}

+ (void)makeTaskFromAssetCollection:(PHAssetCollection *)assetCollection toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *localIdentifier = assetCollection.localIdentifier;
    NSString *toWebAlbumID = toWebAlbum.id_str;
    NSMutableArray *assetIdentifiers = @[].mutableCopy;
    PHFetchResult *fetchResults = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    for (PHAsset *asset in fetchResults) {
        [assetIdentifiers addObject:asset.localIdentifier];
    }
    
    __block NSManagedObjectID *taskObjectID = nil;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:kPDTaskObjectName inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypeLocalAlbumToWebAlbum);
        taskObject.from_album_id_str = localIdentifier;
        taskObject.to_album_id_str = toWebAlbumID;
        taskObjectID = taskObject.objectID;
        
        for (NSString *id_str in assetIdentifiers) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDLocalPhotoObject class]) inManagedObjectContext:context];
            localPhoto.photo_object_id_str = id_str;
            localPhoto.task = taskObject;
            [taskObject addPhotosObject:localPhoto];
        }
    }];
    
    completion ? completion(taskObjectID, nil) : 0;
}

+ (void)makeTaskFromPhotos:(NSArray *)photos toAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(NSManagedObjectID *taskObject, NSError *error))completion {
    NSString *to_album_id_str = assetCollection.localIdentifier;
    __block NSManagedObjectID *taskObjectID = nil;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypePhotosToLocalAlbum);
        taskObject.to_album_id_str = to_album_id_str;
        taskObjectID = taskObject.objectID;
        
        for (id tmpphoto in photos) {
            if ([tmpphoto isKindOfClass:[PWPhotoObject class]]) {
                PWPhotoObject *photo = (PWPhotoObject *)tmpphoto;
                PDWebPhotoObject *webPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDWebPhotoObjectName inManagedObjectContext:context];
                webPhoto.photo_object_id_str = photo.id_str;
                webPhoto.tag_sort_index = photo.sortIndex;
                webPhoto.task = taskObject;
                [taskObject addPhotosObject:webPhoto];
            }
            else if ([tmpphoto isKindOfClass:[PLPhotoObject class]]) {
                PLPhotoObject *photo = (PLPhotoObject *)tmpphoto;
                PDLocalCopyPhotoObject *localCopyPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalCopyPhotoObjectName inManagedObjectContext:context];
                localCopyPhoto.photo_object_id_str = photo.id_str;
                localCopyPhoto.task = taskObject;
                [taskObject addPhotosObject:localCopyPhoto];
            }
            else if ([tmpphoto isKindOfClass:[PHAsset class]]) {
                PHAsset *asset = (PHAsset *)tmpphoto;
                PDLocalCopyPhotoObject *localCopyPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalCopyPhotoObjectName inManagedObjectContext:context];
                localCopyPhoto.photo_object_id_str = asset.localIdentifier;
                localCopyPhoto.task = taskObject;
                [taskObject addPhotosObject:localCopyPhoto];
            }
        }
    }];
    
    completion ? completion(taskObjectID, nil): 0;
}

+ (void)makeTaskFromPhotos:(NSArray *)photos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *to_album_id_str = toLocalAlbum.id_str;
    
    __block NSManagedObjectID *taskObjectID = nil;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypePhotosToLocalAlbum);
        taskObject.to_album_id_str = to_album_id_str;
        taskObjectID = taskObject.objectID;
        
        for (id tmpphoto in photos) {
            if ([tmpphoto isKindOfClass:[PWPhotoObject class]]) {
                PWPhotoObject *photo = (PWPhotoObject *)tmpphoto;
                PDWebPhotoObject *webPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDWebPhotoObjectName inManagedObjectContext:context];
                webPhoto.photo_object_id_str = photo.id_str;
                webPhoto.tag_sort_index = photo.sortIndex;
                webPhoto.task = taskObject;
                [taskObject addPhotosObject:webPhoto];
            }
            else if ([tmpphoto isKindOfClass:[PLPhotoObject class]]) {
                PLPhotoObject *photo = (PLPhotoObject *)tmpphoto;
                PDLocalCopyPhotoObject *localCopyPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalCopyPhotoObjectName inManagedObjectContext:context];
                localCopyPhoto.photo_object_id_str = photo.id_str;
                localCopyPhoto.task = taskObject;
                [taskObject addPhotosObject:localCopyPhoto];
            }
            else if ([tmpphoto isKindOfClass:[PHAsset class]]) {
                PHAsset *asset = (PHAsset *)tmpphoto;
                PDLocalCopyPhotoObject *localCopyPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalCopyPhotoObjectName inManagedObjectContext:context];
                localCopyPhoto.photo_object_id_str = asset.localIdentifier;
                localCopyPhoto.task = taskObject;
                [taskObject addPhotosObject:localCopyPhoto];
            }
        }
    }];
    
    completion ? completion(taskObjectID, nil): 0;
}

+ (void)makeTaskFromPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *to_album_id_str = toWebAlbum.id_str;
    
    __block NSManagedObjectID *taskObjectID = nil;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypePhotosToWebAlbum);
        taskObject.to_album_id_str = to_album_id_str;
        taskObjectID = taskObject.objectID;
        
        for (id photo in photos) {
            if ([photo isKindOfClass:[PLPhotoObject class]]) {
                PLPhotoObject *localPhoto = photo;
                PDLocalPhotoObject *localPhotoObject = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
                localPhotoObject.photo_object_id_str = localPhoto.id_str;
                localPhotoObject.task = taskObject;
                [taskObject addPhotosObject:localPhotoObject];
            }
            else if ([photo isKindOfClass:[PWPhotoObject class]]) {
                PWPhotoObject *webPhoto = (PWPhotoObject *)photo;
                PDCopyPhotoObject *copyPhotoObject = [NSEntityDescription insertNewObjectForEntityForName:kPDCopyPhotoObjectName inManagedObjectContext:context];
                copyPhotoObject.photo_object_id_str = webPhoto.id_str;
                copyPhotoObject.tag_sort_index = webPhoto.sortIndex;
                copyPhotoObject.task = taskObject;
                [taskObject addPhotosObject:copyPhotoObject];
            }
            else if ([photo isKindOfClass:[PHAsset class]]) {
                PHAsset *asset = (PHAsset *)photo;
                PDLocalPhotoObject *localPhotoObject = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
                localPhotoObject.photo_object_id_str = asset.localIdentifier;
                localPhotoObject.task = taskObject;
                [taskObject addPhotosObject:localPhotoObject];
            }
        }
    }];
    
    completion ? completion(taskObjectID, nil) : 0;
}

#pragma mark UIAlertView
+ (void)showNotSupportGifSkipAlertView {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = NSLocalizedString(@"Not Support Gif Image", nil);
        NSString *message = NSLocalizedString(@"Will be skipped.", nil);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [alertView show];
    });
}

@end
