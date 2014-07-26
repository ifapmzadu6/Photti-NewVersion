//
//  PDCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDCoreDataAPI.h"

@interface PDCoreDataAPI ()

@end

@implementation PDCoreDataAPI

+ (PDCoreDataAPI *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *persistentStoreCoordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PDModel" withExtension:@"momd"];
        NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PDModel.sqlite"];
        
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

+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

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
    if (notification.object != [[self class] readContext] && notification.object != [[self class] storeContext]) {
        [[[self class] readContext] performBlockAndWait:^{
            NSError *error = nil;
            if (![[[self class] readContext] save:&error]) {
                abort();
            }
            
            [[[self class] storeContext] performBlock:^{
                NSError *error = nil;
                if (![[[self class] storeContext] save:&error]) {
                    abort();
                }
            }];
        }];
    }
}

@end
