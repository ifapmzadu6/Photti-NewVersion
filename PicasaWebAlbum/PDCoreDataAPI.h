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

+ (void)barrierAsyncBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)barrierSyncBlock:(void (^)(NSManagedObjectContext *context))block;
+ (void)asyncBlock:(void (^)(NSManagedObjectContext *context))block;

@end
