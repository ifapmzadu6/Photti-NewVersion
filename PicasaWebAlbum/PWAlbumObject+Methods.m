//
//  PWAlbumObject+Methods.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumObject+Methods.h"

#import "PWModelObject.h"
#import "PWCoreDataAPI.h"

@implementation PWAlbumObject (Methods)

+ (PWAlbumObject *)getAlbumObjectWithID:(NSString *)id_str {
    __block PWAlbumObject *albumObject = nil;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
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
