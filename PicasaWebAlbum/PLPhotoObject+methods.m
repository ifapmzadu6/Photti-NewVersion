//
//  PLPhotoObject+methods.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPhotoObject+methods.h"

#import "PLModelObject.h"
#import "PLCoreDataAPI.h"

@implementation PLPhotoObject (methods)

+ (PLPhotoObject *)getPhotoObjectWithID:(NSString *)id_str {
    __block PLPhotoObject *photoObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count > 0) {
            photoObject = objects.firstObject;
        }
    }];
    return photoObject;
}

@end
