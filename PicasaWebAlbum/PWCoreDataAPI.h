//
//  PWCoreDataAPI.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

@interface PWCoreDataAPI : NSObject

+ (BOOL)shouldPerformCoreDataMigration;

+ (NSManagedObjectContext *)readContext;
+ (NSManagedObjectContext *)writeContext;
+ (void)writeContextFinish:(NSManagedObjectContext *)context;

//  Block
+ (void)writeWithBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)writeWithBlockAndWait:(void (^)(NSManagedObjectContext *context))block;
+ (void)readWithBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)readWithBlockAndWait:(void (^)(NSManagedObjectContext *context))block;

@end
