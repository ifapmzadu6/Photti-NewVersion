//
//  PDCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDCoreDataAPI.h"

@interface PDCoreDataAPI ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation PDCoreDataAPI

static dispatch_queue_t pd_coredata_queue() {
    static dispatch_queue_t pd_coredata_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pd_coredata_queue = dispatch_queue_create("com.photti.pdcoredata", DISPATCH_QUEUE_CONCURRENT);
    });
    return pd_coredata_queue;
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
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PDModel" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PDModel.sqlite"];
        
        NSError *error = nil;
        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
        if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        if (coordinator != nil) {
            self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
            self.managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    return self;
}

+ (NSManagedObjectContext *)context {
    NSManagedObjectContext *context = [[PDCoreDataAPI sharedManager] managedObjectContext];
    if (!context) {
        
    }
    return context;
}

+ (void)barrierAsyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_barrier_async(pd_coredata_queue(), ^{
        if (block) {
            block([PDCoreDataAPI context]);
        }
    });
}

+ (void)barrierSyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_barrier_sync(pd_coredata_queue(), ^{
        if (block) {
            block([PDCoreDataAPI context]);
        }
    });
}

+ (void)asyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_async(pd_coredata_queue(), ^{
        if (block) {
            block([PDCoreDataAPI context]);
        }
    });
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
