
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

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *persistentStoreCoordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PLModel" withExtension:@"momd"];
        NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[PLCoreDataAPI applicationDocumentsDirectory] URLByAppendingPathComponent:@"PLModel.sqlite"];
        
        NSPersistentStoreCoordinator *tmpPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        
        NSError *error = nil;
        if (![tmpPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        persistentStoreCoordinator = tmpPersistentStoreCoordinator;
    });
    return persistentStoreCoordinator;
}

+ (NSManagedObjectContext *)readContext {
    static NSManagedObjectContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPersistentStoreCoordinator *coordinator = [PLCoreDataAPI persistentStoreCoordinator];
        if (coordinator != nil) {
            NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            managedObjectContext.persistentStoreCoordinator = coordinator;
            
            context = managedObjectContext;
        }
    });
    return context;
}

+ (NSManagedObjectContext *)writeContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [PLCoreDataAPI readContext];
    return context;
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
