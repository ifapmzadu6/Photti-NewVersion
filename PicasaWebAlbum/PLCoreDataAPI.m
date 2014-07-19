
//
//  PLCoreDataAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLCoreDataAPI.h"

@interface PLCoreDataAPI ()

@property (strong, nonatomic) NSManagedObjectContext *readContext;
@property (strong, nonatomic) NSManagedObjectContext *storeContext;

@end

@implementation PLCoreDataAPI

+ (PLCoreDataAPI *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = self.new;
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PLModel" withExtension:@"momd"];
        NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[[self class] applicationDocumentsDirectory] URLByAppendingPathComponent:@"PLModel.sqlite"];
        
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        
        NSError *error = nil;
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        _storeContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _storeContext.persistentStoreCoordinator = persistentStoreCoordinator;
        _storeContext.undoManager = nil;
        
        _readContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _readContext.parentContext = _storeContext;
        _readContext.undoManager = nil;
    }
    return self;
}

+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSManagedObjectContext *)writeContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [self sharedManager].readContext;
    context.undoManager = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedManager] selector:@selector(contextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:context];
    
    return context;
}

+ (void)writeContextFinish:(NSManagedObjectContext *)context {
    [[NSNotificationCenter defaultCenter] removeObserver:[self sharedManager] name:NSManagedObjectContextDidSaveNotification object:context];
}

+ (NSManagedObjectContext *)readContext {
    return [self sharedManager].readContext;
}

+ (NSManagedObjectContext *)storeContext {
    return [self sharedManager].storeContext;
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
