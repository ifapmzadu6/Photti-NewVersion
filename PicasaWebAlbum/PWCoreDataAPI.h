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

+ (void)barrierSyncBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)syncBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)asyncBlock:(void (^)(NSManagedObjectContext *context))block;

@end
