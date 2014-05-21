
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
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    return self;
}

+ (NSManagedObjectContext *)context {
    NSManagedObjectContext *context = [[PLCoreDataAPI sharedManager] managedObjectContext];
    if (!context) {
//        DDLogError(@"%s", __func__);
        return nil;
    }
    return context;
}

+ (void)performBlock:(void (^)(NSManagedObjectContext *))block {
    NSManagedObjectContext *context = [[PLCoreDataAPI sharedManager] managedObjectContext];
    if (!context) {
//        DDLogError(@"%s", __func__);
        return;
    }
    [context performBlock:^{
        if (block) {
            block(context);
        }
    }];
}

+ (void)performBlockAndWait:(void (^)(NSManagedObjectContext *))block {
    NSManagedObjectContext *context = [[PLCoreDataAPI sharedManager] managedObjectContext];
    if (!context) {
//        DDLogError(@"%s", __func__);
        return;
    }
    [context performBlockAndWait:^{
        if (block) {
            block(context);
        }
    }];
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
