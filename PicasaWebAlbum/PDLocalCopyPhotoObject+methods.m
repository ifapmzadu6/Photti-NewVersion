//
//  PDLocalCopyPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/28.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDLocalCopyPhotoObject+methods.h"

#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PDModelObject.h"

@implementation PDLocalCopyPhotoObject (methods)

- (void)copyToLocalAlbum {
    NSString *id_str = self.photo_object_id_str;
    NSString *album_id_str = self.task.to_album_id_str;
    
    [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:@"PLPhotoObject" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count == 0) {
            return;
        }
        PLPhotoObject *photoObject = objects.firstObject;
        
        request.entity = [NSEntityDescription entityForName:@"PLAlbumObject" inManagedObjectContext:context];
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
}

@end
