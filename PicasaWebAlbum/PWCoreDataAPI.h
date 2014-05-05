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

+ (id)sharedManager;

+ (NSManagedObjectContext *)context;

+ (void)performBlock:(void (^)(NSManagedObjectContext *context))block;

@end
