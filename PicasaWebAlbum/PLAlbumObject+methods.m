//
//  PLAlbumObject+methods.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumObject+methods.h"

#import "PLModelObject.h"
#import "PLCoreDataAPI.h"

@implementation PLAlbumObject (methods)

+ (PLAlbumObject *)getAlbumObjectWithID:(NSString *)id_str {
    __block PLAlbumObject *albumObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count > 0) {
            albumObject = objects.firstObject;
        }
    }];
    return albumObject;
}

@end
