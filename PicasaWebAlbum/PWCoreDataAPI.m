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

//@property (strong, nonatomic) NSManagedObjectContext *readContext;
//@property (strong, nonatomic) NSManagedObjectContext *storeContext;

@end

@implementation PWCoreDataAPI

+ (PWCoreDataAPI *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *persistentStoreCoordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PWModel" withExtension:@"momd"];
        NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[PWCoreDataAPI applicationDocumentsDirectory] URLByAppendingPathComponent:@"PWModel.sqlite"];
        
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
    context.parentContext = [PWCoreDataAPI readContext];
    context.undoManager = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:[PWCoreDataAPI sharedManager] selector:@selector(contextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:context];
    
    return context;
}

+ (void)writeContextFinish:(NSManagedObjectContext *)context {
    [[NSNotificationCenter defaultCenter] removeObserver:[PWCoreDataAPI sharedManager] name:NSManagedObjectContextDidSaveNotification object:context];
}

+ (NSManagedObjectContext *)readContext {
    static NSManagedObjectContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        context.parentContext = [PWCoreDataAPI storeContext];
        context.undoManager = nil;
    });
    return context;
}

+ (NSManagedObjectContext *)storeContext {
    static NSManagedObjectContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.persistentStoreCoordinator = [PWCoreDataAPI persistentStoreCoordinator];
        context.undoManager = nil;
    });
    return context;
}


#pragma mark Block
+ (void)writeWithBlock:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [PWCoreDataAPI writeContext];
    [context performBlock:^{
        block(context);
        
        NSError *error = nil;
        if (![context save:&error]) {
            abort();
        }
        
        [PWCoreDataAPI writeContextFinish:context];
    }];
}

+ (void)writeWithBlockAndWait:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [PWCoreDataAPI writeContext];
    [context performBlockAndWait:^{
        block(context);
        
        NSError *error = nil;
        if (![context save:&error]) {
            abort();
        }
        
        [PWCoreDataAPI writeContextFinish:context];
    }];
}

+ (void)readWithBlock:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    [context performBlock:^{
        block(context);
    }];
}

+ (void)readWithBlockAndWait:(void (^)(NSManagedObjectContext *))block {
    if (!block) return;
    
    NSManagedObjectContext *context = [PWCoreDataAPI readContext];
    [context performBlockAndWait:^{
        block(context);
    }];
}

#pragma mark NSNotificationCenter
- (void)contextDidSaveNotification:(NSNotification *)notification {
    if (notification.object != [PWCoreDataAPI readContext] && notification.object != [PWCoreDataAPI storeContext]) {
        [[PWCoreDataAPI readContext] performBlockAndWait:^{
            NSError *error = nil;
            if (![[PWCoreDataAPI readContext] save:&error]) {
                abort();
            }
            
            [[PWCoreDataAPI storeContext] performBlock:^{
                NSError *error = nil;
                if (![[PWCoreDataAPI storeContext] save:&error]) {
                    abort();
                }
            }];
        }];
    }
}


@end
