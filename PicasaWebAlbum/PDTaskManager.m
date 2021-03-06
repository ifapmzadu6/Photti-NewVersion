//
//  PDTaskManager.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskManager.h"

#import "PDModelObject.h"
#import "PDCoreDataAPI.h"
#import "PAInAppPurchase.h"

#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PEAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PAKit.h"
#import "PWPicasaAPI.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PASnowFlake.h"
#import "NSURLResponse+methods.h"

static NSString * const kPDTaskManagerBackgroundSessionIdentifier = @"kPDBSI";
static NSString * const kPDTaskManagerErrorDomain = @"com.photti.PDTaskManager";

@interface PDTaskManager () <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSMutableArray *observers;

@property (strong, nonatomic) NSURLSession *backgroundSession;

@property (nonatomic) BOOL isPreparing;
@property (strong, nonatomic) NSURL *location;
@property (strong, nonatomic) NSData *uploadResponseData;

@property (nonatomic) BOOL isOperating;

@end

@implementation PDTaskManager

+ (PDTaskManager *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _observers = @[].mutableCopy;
        
        NSURLSessionConfiguration *config = nil;
        if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
            config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kPDTaskManagerBackgroundSessionIdentifier];
        }
        else {
            config = [NSURLSessionConfiguration backgroundSessionConfiguration:kPDTaskManagerBackgroundSessionIdentifier];
        }
        _backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        
        NSManagedObjectContext *context = [PDCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:context];
        
        _restartTimeInterval = 100;
        
        [self restartTimer];
    }
    return self;
}

+ (NSURLSession *)sharedSession {
    return [[PDTaskManager sharedManager] backgroundSession];
}

#pragma mark OBserver
- (void)addTaskManagerObserver:(id<PDTaskManagerDelegate>)observer {
    if (![_observers containsObject:observer]) {
        [_observers addObject:observer];
    }
}

- (void)removeTaskManagerObserver:(id<PDTaskManagerDelegate>)observer {
    if ([_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}

#pragma mark Tasks
- (BOOL)checkOKAddTask {
    if (!PEAssetsManager.isStatusAuthorized) {
        if (_notAllowedAccessPhotoLibraryAction) _notAllowedAccessPhotoLibraryAction();
        return NO;
    }
    
    if (!PWOAuthManager.isLogined) {
        if (_notLoginGoogleAccountAction) _notLoginGoogleAccountAction();
        return NO;
    }
    
    return YES;
}

- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (fromWebAlbum.gphoto.numphotos.intValue == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PAAnalytics sendEvent:NSStringFromClass(self.class) action:@"addTasks" optionalLabel:@"FromWebAlbum_ToLocalAlbum" optionalValue:@(fromWebAlbum.gphoto.numphotos.intValue)];
    
    __weak typeof(self) wself = self;
    [PDTaskObjectFactoryMethods makeTaskFromWebAlbum:fromWebAlbum toLocalAlbum:toLocalAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        [PDTaskManager getCountOfTasksWithCompletion:^(NSUInteger count, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
                taskObject.sort_index = @(count);
            }];
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil);
                });
            }
            
            [sself start];
        }];
    }];
}

- (void)addTaskFromAssetCollection:(PHAssetCollection *)assetCollection toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion {
    if (assetCollection.estimatedAssetCount == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PAAnalytics sendEvent:NSStringFromClass(self.class) action:@"addTasks" optionalLabel:@"FromAssetCollection_ToWebAlbum" optionalValue:@(assetCollection.estimatedAssetCount)];
    
    __weak typeof(self) wself = self;
    [PDTaskObjectFactoryMethods makeTaskFromAssetCollection:assetCollection toWebAlbum:toWebAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }
        [PDTaskManager getCountOfTasksWithCompletion:^(NSUInteger count, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
                taskObject.sort_index = @(count);
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion ? completion(nil) : 0;
            });
            
            [sself start];
        }];
    }];
}

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion {
    if (fromLocalAlbum.photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PAAnalytics sendEvent:NSStringFromClass(self.class) action:@"addTasks" optionalLabel:@"FromLocalAlbum_ToWebAlbum" optionalValue:@(fromLocalAlbum.photos.count)];
    
    __weak typeof(self) wself = self;
    [PDTaskObjectFactoryMethods makeTaskFromLocalAlbum:fromLocalAlbum toWebAlbum:toWebAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        [PDTaskManager getCountOfTasksWithCompletion:^(NSUInteger count, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
                taskObject.sort_index = @(count);
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion ? completion(nil) : 0;
            });
            
            [sself start];
        }];
    }];
}

- (void)addTaskPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PAAnalytics sendEvent:NSStringFromClass(self.class) action:@"addTasks" optionalLabel:@"FromPhotos_ToWebAlbum" optionalValue:@(photos.count)];
    
    __weak typeof(self) wself = self;
    [PDTaskObjectFactoryMethods makeTaskFromPhotos:photos toWebAlbum:toWebAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        [PDTaskManager getCountOfTasksWithCompletion:^(NSUInteger count, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
                taskObject.sort_index = @(count);
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion ? completion(nil) : 0;
            });
            
            [sself start];
        }];
    }];
}

- (void)addTaskPhotos:(NSArray *)photos toAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(NSError *error))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PAAnalytics sendEvent:NSStringFromClass(self.class) action:@"addTasks" optionalLabel:@"FromPhotos_ToLocalAlbum" optionalValue:@(photos.count)];
    
    __weak typeof(self) wself = self;
    [PDTaskObjectFactoryMethods makeTaskFromPhotos:photos toAssetCollection:assetCollection completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        [PDTaskManager getCountOfTasksWithCompletion:^(NSUInteger count, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
                taskObject.sort_index = @(count);
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion ? completion(nil) : 0;
            });
            
            [sself start];
        }];
    }];
}

- (void)addTaskPhotos:(NSArray *)photos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PAAnalytics sendEvent:NSStringFromClass(self.class) action:@"addTasks" optionalLabel:@"FromPhotos_ToLocalAlbum" optionalValue:@(photos.count)];
    
    __weak typeof(self) wself = self;
    [PDTaskObjectFactoryMethods makeTaskFromPhotos:photos toLocalAlbum:toLocalAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            return;
        }
        [PDTaskManager getCountOfTasksWithCompletion:^(NSUInteger count, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
                taskObject.sort_index = @(count);
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion ? completion(nil) : 0;
            });
            
            [sself start];
        }];
    }];
}

- (void)countOfAllPhotosInTaskWithCompletion:(void (^)(NSUInteger count, NSError *error))completion {
    if (!completion) return;
    
    [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPDBasePhotoObjectName inManagedObjectContext:context];
        NSError *error = nil;
        NSUInteger count = [context countForFetchRequest:request error:&error];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(count, error);
        });
    }];
}

- (void)getRequestingTasksWithCompletion:(void (^)(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks))completion {
    [_backgroundSession getTasksWithCompletionHandler:completion];
}

- (void)start {
    if (_isOperating) {
        return;
    }
    _isOperating = YES;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (dataTasks.count == 0 && uploadTasks.count == 0 && downloadTasks.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    PDTaskObject *taskObject = [PDTaskManager getFirstTaskObject];
                    [sself taskIsDoneAndStartNext:taskObject];
                });
            }
        }];
    });
}

- (void)stop {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            for (NSURLSessionTask *task in dataTasks) [task suspend];
            for (NSURLSessionTask *task in uploadTasks) [task suspend];
            for (NSURLSessionTask *task in downloadTasks) [task suspend];
        }];
    });
}

- (void)cancel {
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            typeof(wself) sself = wself;
            if (!sself) return;
            for (NSURLSessionTask *task in dataTasks) [task cancel];
            for (NSURLSessionTask *task in uploadTasks) [task cancel];
            for (NSURLSessionTask *task in downloadTasks) [task cancel];
            sself.isOperating = NO;
        }];
    });
}

#pragma mark Restart
- (void)restartTimer {
    [self start];
    
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_restartTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        [sself restartTimer];
    });
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    CGFloat progress = (double)totalBytesSent / (double)totalBytesExpectedToSend;
    PDTaskObject *taskObject = [PDTaskManager getFirstTaskObject];
    PDBasePhotoObject *photoObject = taskObject.photos.firstObject;
    for (id<PDTaskManagerDelegate> observer in _observers) {
        if ([observer respondsToSelector:@selector(taskManagerProgress:photoObject:)]) {
            [observer taskManagerProgress:progress photoObject:photoObject];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    
    if (error || !task.response.isSuccess) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        return;
    }
    
    if ([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
        NSURL *location = _location;
        _location = nil;
        
        PDBasePhotoObject *photoObject = [PDTaskManager getFirstTaskObject].photos.firstObject;
        if (![photoObject.session_task_identifier isEqualToNumber:@(task.taskIdentifier)]) {
#ifdef DEBUG
            NSLog(@"[ERROR] DB not match session task!");
#endif
            return;
        }
        
        if ([photoObject isKindOfClass:[PDWebPhotoObject class]]) {
            PDWebPhotoObject *webPhotoObject = (PDWebPhotoObject *)photoObject;
            __weak typeof(self) wself = self;
            [webPhotoObject finishDownloadWithLocation:location completion:^(NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                    return;
                }
                
                [sself taskIsDoneAndStartNext:[PDTaskManager getFirstTaskObject]];
            }];
        }
        else if ([photoObject isKindOfClass:[PDCopyPhotoObject class]]) {
            PDCopyPhotoObject *copyPhotoObject = (PDCopyPhotoObject *)photoObject;
            [copyPhotoObject finishDownloadWithLocation:location];
            
            [self taskIsDoneAndStartNext:[PDTaskManager getFirstTaskObject]];
        }
    }
    else if ([task isKindOfClass:[NSURLSessionUploadTask class]]) {
        PDBasePhotoObject *photoObject = [PDTaskManager getFirstTaskObject].photos.firstObject;
        NSManagedObjectID *photoObjectID = photoObject.objectID;
        
        if ([photoObject isKindOfClass:[PDCopyPhotoObject class]]) {
            [(PDCopyPhotoObject *)photoObject finishUpload];
        }
        else if ([photoObject isKindOfClass:[PDLocalPhotoObject class]]) {
            __block PDTaskObject *taskObject = nil;
            [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
                taskObject = photoObject.task;
            }];
            if (taskObject) {
                NSData *data = _uploadResponseData;
                _uploadResponseData = nil;
                if (!taskObject.to_album_id_str) {
                    [(PDLocalPhotoObject *)photoObject finishMakeNewAlbumSessionWithResponse:task.response data:data];
                }
                else {
                    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                        PDBasePhotoObject *photoObject = (PDBasePhotoObject *)[context objectWithID:photoObjectID];
                        photoObject.is_done = @YES;
                    }];
                }
            }
        }
        [self taskIsDoneAndStartNext:[PDTaskManager getFirstTaskObject]];
    }
}

#pragma mark NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *filePath = [PAKit makeUniquePathInTmpDir];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        return;
    }
    
    _location = fileURL;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    CGFloat progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    PDTaskObject *taskObject = [PDTaskManager getFirstTaskObject];
    PDBasePhotoObject *photoObject = taskObject.photos.firstObject;
    for (id<PDTaskManagerDelegate> observer in _observers) {
        if ([observer respondsToSelector:@selector(taskManagerProgress:photoObject:)]) {
            [observer taskManagerProgress:progress photoObject:photoObject];
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

#pragma mark NSURLSessionDataTask
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    _uploadResponseData = data;
}

#pragma mark contextchanged
- (void)contextDidSaveNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<PDTaskManagerDelegate> observer in _observers) {
            if ([observer respondsToSelector:@selector(taskManagerChangedTaskCount)]) {
                [observer taskManagerChangedTaskCount];
            }
        }
        
        [self countOfAllPhotosInTaskWithCompletion:^(NSUInteger count, NSError *error) {
            if (count == 0) {
                _isOperating = NO;
            }
        }];
    });
}

#pragma mark Start Task
- (void)taskIsDoneAndStartNext:(PDTaskObject *)taskObject {
    if (!taskObject) {
        _isOperating = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_backgroundComplecationHandler) {
                _backgroundComplecationHandler();
                _backgroundComplecationHandler = nil;
            }
        });
        
        return;
    }
    NSManagedObjectID *taskObjectID = taskObject.objectID;
    
    NSOrderedSet *photos = taskObject.photos;
    if (photos.count == 0) {
        if (taskObject.type.integerValue == PDTaskObjectTypeLocalAlbumToWebAlbum || taskObject.type.integerValue == PDTaskObjectTypePhotosToWebAlbum) {
            [PWPicasaAPI getListOfAlbumsWithIndex:0 completion:nil];
        }
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *tmpTaskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            if (tmpTaskObject) {
                [context deleteObject:tmpTaskObject];
            }
        }];
        
        [self taskIsDoneAndStartNext:[PDTaskManager getFirstTaskObject]];
        return;
    }
    
    PDBasePhotoObject *photoObject = photos.firstObject;
    NSManagedObjectID *photoObjectID = photoObject.objectID;
    if (photoObject.is_done.boolValue) {
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *tmpTaskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            PDBasePhotoObject *tmpPhotoObject = (PDBasePhotoObject *)[context objectWithID:photoObjectID];
            if (tmpTaskObject && tmpPhotoObject) {
                [tmpTaskObject removePhotosObject:tmpPhotoObject];
            }
            if (tmpPhotoObject) {
                [context deleteObject:tmpPhotoObject];
            }
        }];
        
        [self taskIsDoneAndStartNext:[PDTaskManager getFirstTaskObject]];
    }
    else {
        if (![photoObject isKindOfClass:[PDLocalCopyPhotoObject class]]) {
            [photoObject makeSessionTaskWithSession:_backgroundSession completion:^(NSURLSessionTask *task, NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
                else {
                    [task resume];
                }
            }];
        }
        else {
            [(PDLocalCopyPhotoObject *)photoObject copyToLocalAlbum];
            [self taskIsDoneAndStartNext:[PDTaskManager getFirstTaskObject]];
        }
    }
}

#pragma GetData
+ (PDTaskObject *)getFirstTaskObject {
    __block PDTaskObject *taskObject = nil;
    [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPDTaskObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sort_index" ascending:YES]];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count >= 1) {
            taskObject = objects.firstObject;
        }
    }];
    return taskObject;
}

+ (void)getCountOfTasksWithCompletion:(void (^)(NSUInteger, NSError *))completion {
    if (!completion) return;
    
    __block NSUInteger count = 0;
    [PDCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPDTaskObjectName inManagedObjectContext:context];
        NSError *error = nil;
        count = [context countForFetchRequest:request error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(count, error);
        });
    }];
}

@end
