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

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

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

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PWModel" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PWModel.sqlite"];
        
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
    NSManagedObjectContext *context = [[PWCoreDataAPI sharedManager] managedObjectContext];
    if (!context) {
        
    }
    return context;
}

+ (void)barrierSyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_barrier_sync(pw_coredata_queue(), ^{
        if (block) {
            block([PWCoreDataAPI context]);
        }
    });
}

+ (void)asyncBlock:(void (^)(NSManagedObjectContext *))block {
    dispatch_async(pw_coredata_queue(), ^{
        if (block) {
            block([PWCoreDataAPI context]);
        }
    });
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
