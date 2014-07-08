//
//  PDCoreDataAPI.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

@interface PDCoreDataAPI : NSObject

+ (NSManagedObjectContext *)readContext;
+ (NSManagedObjectContext *)writeContext;
+ (void)writeContextFinish:(NSManagedObjectContext *)context;

//  Block
+ (void)writeWithBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)writeWithBlockAndWait:(void (^)(NSManagedObjectContext *context))block;
+ (void)readWithBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)readWithBlockAndWait:(void (^)(NSManagedObjectContext *context))block;

@end
