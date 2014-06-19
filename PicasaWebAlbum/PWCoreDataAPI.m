//
//  PWCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWCoreDataAPI.h"

#import "DDLog.h"

@interface PWCoreDataAPI ()

@end

@implementation PWCoreDataAPI

static dispatch_queue_t pw_coredata_queue() {
    static dispatch_queue_t pw_coredata_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pw_coredata_queue = dispatch_queue_create("com.photti.pwcoredata", DISPATCH_QUEUE_CONCURRENT);
    });
    return pw_coredata_queue;
}

+ (NSManagedObjectContext *)context {
    static NSManagedObjectContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_barrier_sync(pw_coredata_queue(), ^{
            NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PWModel" withExtension:@"momd"];
            NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            
            NSURL *storeURL = [[PWCoreDataAPI applicationDocumentsDirectory] URLByAppendingPathComponent:@"PWModel.sqlite"];
            
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
    if (!block) return;
    id context = [PWCoreDataAPI context];
    dispatch_barrier_async(pw_coredata_queue(), ^{
        block(context);
    });
}

+ (void)barrierSyncBlock:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    id context = [PWCoreDataAPI context];
    dispatch_barrier_sync(pw_coredata_queue(), ^{
        block(context);
    });
}

+ (void)syncBlock:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    id context = [PWCoreDataAPI context];
    dispatch_sync(pw_coredata_queue(), ^{
        block(context);
    });
}

+ (void)asyncBlock:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    id context = [PWCoreDataAPI context];
    dispatch_async(pw_coredata_queue(), ^{
        block(context);
    });
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
