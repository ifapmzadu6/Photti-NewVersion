//
//  PWCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWCoreDataAPI.h"

@interface PWCoreDataAPI ()

@end

@implementation PWCoreDataAPI

+ (PWCoreDataAPI *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

+ (NSManagedObjectModel *)managedObjectModel {
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PWModel" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *persistentStoreCoordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSManagedObjectModel *managedObjectModel = [self managedObjectModel];
        NSURL *storeURL = [self storeURL];
        
        NSPersistentStoreCoordinator *tmpPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        
        NSDictionary *options = @{NSInferMappingModelAutomaticallyOption:@YES, NSMigratePersistentStoresAutomaticallyOption:@YES};
        NSError *error = nil;
        if (![tmpPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
            
#ifdef DEBUG
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#endif
            abort();
        }
        
        persistentStoreCoordinator = tmpPersistentStoreCoordinator;
    });
    return persistentStoreCoordinator;
}

+ (NSURL *)storeURL {
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PWModel.sqlite"];
}

+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (BOOL)shouldPerformCoreDataMigration {
    NSError *error = nil;
    NSDictionary *sourceMetaData = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:[self storeURL] error:&error];
    if (!sourceMetaData) {
        return NO;
    }
    
    NSManagedObjectModel *managedObjectModel = [self managedObjectModel];
    BOOL isCompatible = [managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetaData];
    return !isCompatible;
}

#pragma mark Block
+ (NSManagedObjectContext *)writeContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [self readContext];
    context.undoManager = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedManager] selector:@selector(contextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:context];
    
    return context;
}

+ (void)writeContextFinish:(NSManagedObjectContext *)context {
    [[NSNotificationCenter defaultCenter] removeObserver:[self sharedManager] name:NSManagedObjectContextDidSaveNotification object:context];
}

+ (NSManagedObjectContext *)readContext {
    static NSManagedObjectContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([NSThread isMainThread]) {
            context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            context.parentContext = [self storeContext];
            context.undoManager = nil;
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                context.parentContext = [self storeContext];
                context.undoManager = nil;
            });
        }
    });
    return context;
}

+ (NSManagedObjectContext *)storeContext {
    static NSManagedObjectContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.persistentStoreCoordinator = [self persistentStoreCoordinator];
        context.undoManager = nil;
    });
    return context;
}


#pragma mark Block
+ (void)writeWithBlock:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [self writeContext];
    [context performBlock:^{
        block(context);
        
        NSError *error = nil;
        if (![context save:&error]) {
            abort();
        }
        
        [self writeContextFinish:context];
    }];
}

+ (void)writeWithBlockAndWait:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [self writeContext];
    [context performBlockAndWait:^{
        block(context);
        
        NSError *error = nil;
        if (![context save:&error]) {
            abort();
        }
        
        [self writeContextFinish:context];
    }];
}

+ (void)readWithBlock:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [self readContext];
    [context performBlock:^{
        block(context);
    }];
}

+ (void)readWithBlockAndWait:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [self readContext];
    [context performBlockAndWait:^{
        block(context);
    }];
}

#pragma mark NSNotificationCenter
- (void)contextDidSaveNotification:(NSNotification *)notification {
    if (notification.object != [self.class readContext] && notification.object != [self.class storeContext]) {
        [[self.class readContext] performBlockAndWait:^{
            NSError *error = nil;
            if (![[self.class readContext] save:&error]) {
                abort();
            }
            
            [[self.class storeContext] performBlock:^{
                NSError *error = nil;
                if (![[self.class storeContext] save:&error]) {
                    abort();
                }
            }];
        }];
    }
}


@end
