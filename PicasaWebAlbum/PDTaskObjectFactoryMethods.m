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

@implementation PDTaskObjectFactoryMethods

+ (void)makeTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *webAlbumId = fromWebAlbum.id_str;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *photoObjectIDs = @[].mutableCopy;
        NSMutableDictionary *photoObjectSortIndexs = @{}.mutableCopy;
        [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", webAlbumId];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
            NSError *error = nil;
            NSArray *photos = [context executeFetchRequest:request error:&error];
            if (photos.count == 0) {
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"PDTaskObject (methods)" code:0 userInfo:nil]);
                }
                return;
            }
            
            for (PWPhotoObject *photoObject in photos) {
                [photoObjectIDs addObject:photoObject.id_str];
                [photoObjectSortIndexs setObject:photoObject.sortIndex forKey:photoObject.id_str];
            }
        }];
        
        __block NSManagedObjectID *taskObjectID = nil;
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
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
        
        if (completion) {
            completion(taskObjectID, nil);
        }
    });
}

+ (void)makeTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *fromLocalAlbumID = fromLocalAlbum.id_str;
    NSString *toWebAlbumID = toWebAlbum.id_str;
    
    NSManagedObjectContext *context = [PDCoreDataAPI writeContext];
    [context performBlock:^{
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypeLocalAlbumToWebAlbum);
        taskObject.from_album_id_str = fromLocalAlbumID;
        taskObject.to_album_id_str = toWebAlbumID;
        
        NSMutableArray *id_strs = [NSMutableArray array];
        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            for (PLPhotoObject *photoObject in fromLocalAlbum.photos.array) {
                [id_strs addObject:photoObject.id_str];
            }
        }];
        
        __block NSUInteger index = 0;
        NSUInteger count = id_strs.count;
        for (NSString *id_str in id_strs) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDLocalPhotoObject class]) inManagedObjectContext:context];
            localPhoto.photo_object_id_str = id_str;
            localPhoto.task = taskObject;
            [taskObject addPhotosObject:localPhoto];
            
            NSManagedObjectID *taskObjectID = taskObject.objectID;
            
            [localPhoto setUploadTaskToWebAlbumID:id_str completion:^(NSError *error) {
                index++;
                if (index == count) {
                    NSError *error = nil;
                    if (![context save:&error]) {
                        NSLog(@"%@", error.description);
                        abort();
                    }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        if (completion) {
                            completion(taskObjectID, nil);
                        }
                    });
                }
            }];
        }
    }];
}

+ (void)makeTaskFromPhotos:(NSArray *)photos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *to_album_id_str = toLocalAlbum.id_str;
    
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypePhotosToLocalAlbum);
        taskObject.to_album_id_str = to_album_id_str;
        NSManagedObjectID *taskObjectID = taskObject.objectID;
        
        for (PWPhotoObject *photo in photos) {
            if ([photo isKindOfClass:[PWPhotoObject class]]) {
                PDWebPhotoObject *webPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"PDWebPhotoObject" inManagedObjectContext:context];
                webPhoto.photo_object_id_str = photo.id_str;
                webPhoto.tag_sort_index = photo.sortIndex;
                webPhoto.task = taskObject;
                [taskObject addPhotosObject:webPhoto];
            }
            else if ([photo isKindOfClass:[PLPhotoObject class]]) {
                PDLocalCopyPhotoObject *localCopyPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"PDLocalCopyPhotoObject" inManagedObjectContext:context];
                localCopyPhoto.photo_object_id_str = photo.id_str;
                localCopyPhoto.is_done = @(YES);
                [taskObject addPhotosObject:localCopyPhoto];
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (completion) {
                completion(taskObjectID, nil);
            }
        });
    }];
}

+ (void)makeTaskFromPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSManagedObjectID *, NSError *))completion {
    NSString *to_album_id_str = toWebAlbum.id_str;
    
    [PDCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        taskObject.type = @(PDTaskObjectTypePhotosToWebAlbum);
        taskObject.to_album_id_str = to_album_id_str;
        NSManagedObjectID *taskObjectID = taskObject.objectID;
        
        for (id photo in photos) {
            if ([photo isKindOfClass:[PLPhotoObject class]]) {
                PLPhotoObject *localPhoto = photo;
                PDLocalPhotoObject *localPhotoObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDLocalPhotoObject class]) inManagedObjectContext:context];
                localPhotoObject.photo_object_id_str = localPhoto.id_str;
                localPhotoObject.task = taskObject;
                [taskObject addPhotosObject:localPhotoObject];
                
//                ここでアップロードの準備をしてもいい？
//                とりあえずアップロード直前で考える
//                時間制限もしあればここでアップロードの準備
//                [localPhotoObject setUploadTaskToWebAlbumID:localPhoto.id_str completion:^(NSError *error) {
            }
            else if ([photo isKindOfClass:[PWPhotoObject class]]) {
                PWPhotoObject *webPhoto = (PWPhotoObject *)photo;
                
                PDCopyPhotoObject *copyPhotoObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PDCopyPhotoObject class]) inManagedObjectContext:context];
                copyPhotoObject.photo_object_id_str = webPhoto.id_str;
                copyPhotoObject.tag_sort_index = webPhoto.sortIndex;
                copyPhotoObject.task = taskObject;
                [taskObject addPhotosObject:copyPhotoObject];
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (completion) {
                completion(taskObjectID, nil);
            }
        });
    }];
}

@end
