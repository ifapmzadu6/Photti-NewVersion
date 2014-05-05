//
//  PWCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWCoreDataAPI.h"

@interface PWCoreDataAPI ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation PWCoreDataAPI

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
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PicasaWebAlbum.sqlite"];
        
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
    NSManagedObjectContext *context = [[PWCoreDataAPI sharedManager] managedObjectContext];
    if (!context) {
//        DDLogError(@"%s", __func__);
        return nil;
    }
    return context;
}

+ (void)performBlock:(void (^)(NSManagedObjectContext *))block {
    NSManagedObjectContext *context = [[PWCoreDataAPI sharedManager] managedObjectContext];
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

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
