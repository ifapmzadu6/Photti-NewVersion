//
//  PDLocalCopyPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/28.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDLocalCopyPhotoObject+methods.h"

@import Photos;

#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PDModelObject.h"
#import "PDCoreDataAPI.h"
#import "PAPhotoKit.h"

@implementation PDLocalCopyPhotoObject (methods)

- (void)copyToLocalAlbum {
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        [self newCopyToLocalAlbum];
    }
    else {
        [self oldCopyToLocalAlbum];
    }
}

- (void)newCopyToLocalAlbum {
    NSString *albumIdentifier = self.task.to_album_id_str;
    PHAssetCollection *assetCollection = [PAPhotoKit getAssetCollectionWithIdentifier:albumIdentifier];
    
    NSString *photoIdentifier = self.photo_object_id_str;
    PHAsset *asset = [PAPhotoKit getAssetWithIdentifier:photoIdentifier];
    
    NSError *error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [request addAssets:@[asset]];
    } error:&error];
    if (error) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
    }
    else {
        NSManagedObjectID *selfObjectID = self.objectID;
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDBasePhotoObject *selfObject = (PDBasePhotoObject *)[context objectWithID:selfObjectID];
            selfObject.is_done = @YES;
        }];
    }
}

- (void)oldCopyToLocalAlbum {
    NSString *id_str = self.photo_object_id_str;
    NSString *album_id_str = self.task.to_album_id_str;
    
    [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count == 0) {
            return;
        }
        PLPhotoObject *photoObject = objects.firstObject;
        
        request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", album_id_str];
        request.fetchLimit = 1;
        NSError *albumError = nil;
        NSArray *albums = [context executeFetchRequest:request error:&albumError];
        if (albums.count == 0) {
            return;
        }
        PLAlbumObject *albumObject = albums.firstObject;
        
        [albumObject addPhotosObject:photoObject];
    }];
    
    NSManagedObjectID *selfObjectID = self.objectID;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDBasePhotoObject *selfObject = (PDBasePhotoObject *)[context objectWithID:selfObjectID];
        selfObject.is_done = @YES;
    }];
}

@end
