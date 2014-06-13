
//
//  PLCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLCoreDataAPI.h"

@interface PLCoreDataAPI ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

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

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PLModel" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PicasaWebAlbumLocal.sqlite"];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        NSPersistentStoreCoordinator *coordinator = _persistentStoreCoordinator;
        if (coordinator != nil) {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    return self;
}

+ (NSManagedObjectContext *)context {
    NSManagedObjectContext *context = [[PLCoreDataAPI sharedManager] managedObjectContext];
    if (!context) {
        
    }
    return context;
}

+ (void)barrierAsyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_barrier_async(pl_coredata_queue(), ^{
        if (block) {
            block([PLCoreDataAPI context]);
        }
    });
}

+ (void)barrierSyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_barrier_sync(pl_coredata_queue(), ^{
        if (block) {
            block([PLCoreDataAPI context]);
        }
    });
}

+ (void)asyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_async(pl_coredata_queue(), ^{
        if (block) {
            block([PLCoreDataAPI context]);
        }
    });
}

+ (void)syncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_sync(pl_coredata_queue(), ^{
        if (block) {
            block([PLCoreDataAPI context]);
        }
    });
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
