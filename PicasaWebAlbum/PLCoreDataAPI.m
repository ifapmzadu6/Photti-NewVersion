
//
//  PLCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLCoreDataAPI.h"

@interface PLCoreDataAPI ()

@end

@implementation PLCoreDataAPI

static dispatch_queue_t pl_coredata_queue() {
    static dispatch_queue_t pl_coredata_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pl_coredata_queue = dispatch_queue_create("com.photti.plcoredata", DISPATCH_QUEUE_CONCURRENT);
    });
    return pl_coredata_queue;
}

+ (NSManagedObjectContext *)context {
    static NSManagedObjectContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_barrier_sync(pl_coredata_queue(), ^{
            NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PLModel" withExtension:@"momd"];
            NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            
            NSURL *storeURL = [[PLCoreDataAPI applicationDocumentsDirectory] URLByAppendingPathComponent:@"PLModel.sqlite"];
            
            NSError *error = nil;
            NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
            if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
                
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            
            NSPersistentStoreCoordinator *coordinator = persistentStoreCoordinator;
            if (coordinator != nil) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
                managedObjectContext.persistentStoreCoordinator = coordinator;
                
                context = managedObjectContext;
            }
        });
    });
    return context;
}

+ (void)barrierAsyncBlock:(void (^)(NSManagedObjectContext *))block {
    id context = [PLCoreDataAPI context];
    dispatch_barrier_async(pl_coredata_queue(), ^{
        if (block) {
            block(context);
        }
    });
}

+ (void)barrierSyncBlock:(void (^)(NSManagedObjectContext *))block {
    id context = [PLCoreDataAPI context];
    dispatch_barrier_sync(pl_coredata_queue(), ^{
        if (block) {
            block(context);
        }
    });
}

+ (void)asyncBlock:(void (^)(NSManagedObjectContext *))block {
    id context = [PLCoreDataAPI context];
    dispatch_async(pl_coredata_queue(), ^{
        if (block) {
            block(context);
        }
    });
}

+ (void)syncBlock:(void (^)(NSManagedObjectContext *))block {
    id context = [PLCoreDataAPI context];
    dispatch_sync(pl_coredata_queue(), ^{
        if (block) {
            block(context);
        }
    });
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
