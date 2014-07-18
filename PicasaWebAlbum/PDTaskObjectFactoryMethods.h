//
//  PDTaskObject+methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import CoreData;

@class PWAlbumObject, PLAlbumObject;

@interface PDTaskObjectFactoryMethods : NSObject

+ (void)makeTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSManagedObjectID *taskObjectID, NSError *error))completion;
+ (void)makeTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSManagedObjectID *taskObject, NSError *error))completion;
+ (void)makeTaskFromPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSManagedObjectID *taskObject, NSError *error))completion;
+ (void)makeTaskFromPhotos:(NSArray *)photos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSManagedObjectID *taskObject, NSError *error))completion;

@end
