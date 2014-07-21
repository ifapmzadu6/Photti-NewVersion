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
#import "PDInAppPurchase.h"

#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"

#import "PWPicasaAPI.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWSnowFlake.h"

static NSString * const kPDTaskManagerBackgroundSessionIdentifier = @"kPDBSI";

@interface PDTaskManager ()

@property (strong, nonatomic) NSURLSession *backgroundSession;

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
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kPDTaskManagerBackgroundSessionIdentifier];
        _backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        
        NSManagedObjectContext *context = [PDCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:context];
    }
    return self;
}

+ (NSURLSession *)sharedSession {
    return [[PDTaskManager sharedManager] backgroundSession];
}

- (BOOL)checkOKAddTask {
    if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) {
        if (_notPurchasedUploadDownloadAction) _notPurchasedUploadDownloadAction();
        return NO;
    }
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        if (_notAllowedAccessPhotoLibraryAction) _notAllowedAccessPhotoLibraryAction();
        return NO;
    }
    
    return YES;
}

+ (void)performTaskManagerChangedBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[self class] sharedManager].taskManagerChangedBlock) {
            [[self class] sharedManager].taskManagerChangedBlock([[self class] sharedManager]);
        }
    });
}

- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (fromWebAlbum.tag_numphotos.intValue == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromWebAlbum:fromWebAlbum toLocalAlbum:toLocalAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion {
    if (fromLocalAlbum.photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromLocalAlbum:fromLocalAlbum toWebAlbum:toWebAlbum completion:^(NSManagedObjectID *taskObject, NSError *error) {
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)addTaskPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromPhotos:photos toWebAlbum:toWebAlbum completion:^(NSManagedObjectID *taskObject, NSError *error) {
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)addTaskPhotos:(NSArray *)photos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromPhotos:photos toLocalAlbum:toLocalAlbum completion:^(NSManagedObjectID *taskObject, NSError *error) {
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)countOfAllPhotosInTaskWithCompletion:(void (^)(NSUInteger count, NSError *error))completion {
    if (!completion) return;
    
    [PDCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:NSStringFromClass([PDBasePhotoObject class]) inManagedObjectContext:context];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            if (dataTasks.count == 0 && uploadTasks.count == 0 && downloadTasks.count == 0) {
                PDBasePhotoObject *firstPhoto = [PDTaskManager getFirstTaskObject].photos.firstObject;
                NSURLSessionTask *task = nil;
                if ([firstPhoto isKindOfClass:[PDWebPhotoObject class]]) {
                    task = [(PDWebPhotoObject *)firstPhoto makeSessionTaskWithSession:_backgroundSession];
                }
                else if ([firstPhoto isKindOfClass:[PDLocalPhotoObject class]]) {
                    task = [(PDLocalPhotoObject *)firstPhoto makeSessionTaskWithSession:_backgroundSession];
                }
                else if ([firstPhoto isKindOfClass:[PDCopyPhotoObject class]]) {
                    if ([(PDCopyPhotoObject *)firstPhoto downloaded_data_location]) {
                        task = [(PDCopyPhotoObject *)firstPhoto makeUploadSessionTaskWithSession:_backgroundSession];
                    }
                    else {
                        task = [(PDCopyPhotoObject *)firstPhoto makeDownloadSessionTaskWithSession:_backgroundSession];
                    }
                }
                if (task && task.state != NSURLSessionTaskStateRunning) {
                    [task resume];
                }
            }
        }];
    });
}

- (void)stop {
    
}

- (void)cancel {
    
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"%s", __func__);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"%s", __func__);
}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    NSLog(@"%s", __func__);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSLog(@"%s", __func__);
    
    NSLog(@"Send Data = %lld / %lld", totalBytesSent, totalBytesExpectedToSend);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"%s", __func__);
    
    NSURLResponse *response = task.response;
    NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    NSLog(@"Status Code = %lu", (unsigned long)statusCode);
    if (error) {
        NSLog(@"%@", error.description);
    }
    
    NSArray *allPhotoObject = [[self class] getFirstTaskObject].photos.array;
    PDBasePhotoObject *firstPhoto = allPhotoObject.firstObject;
    if (firstPhoto.is_done.boolValue) {
        PDBasePhotoObject *nextPhotoObject = nil;
        if (allPhotoObject.count >= 2) {
            nextPhotoObject = allPhotoObject[1];
        }
        PDTaskObject *taskObject = firstPhoto.task;
        NSManagedObjectID *firstObjectID = firstPhoto.objectID;
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSManagedObject *firstObject = [context objectWithID:firstObjectID];
            [taskObject removePhotosObject:firstPhoto];
            [context deleteObject:firstObject];
        }];
        
        if (nextPhotoObject) {
            NSURLSessionTask *sessionTask = nil;
            if ([nextPhotoObject isKindOfClass:[PDWebPhotoObject class]]) {
                sessionTask = [(PDWebPhotoObject *)nextPhotoObject makeSessionTaskWithSession:_backgroundSession];
            }
            else if([nextPhotoObject isKindOfClass:[PDLocalPhotoObject class]]) {
                sessionTask = [(PDLocalPhotoObject *)nextPhotoObject makeSessionTaskWithSession:_backgroundSession];
            }
            if (sessionTask) {
                [sessionTask resume];
            }
        }
        else {
            NSManagedObjectID *taskObjectID = taskObject.objectID;
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                NSManagedObject *object = [context objectWithID:taskObjectID];
                [context deleteObject:object];
            }];
        }
    }
    else {
        NSURLSessionTask *sessionTask = nil;
        if ([firstPhoto isKindOfClass:[PDWebPhotoObject class]]) {
            sessionTask = [(PDWebPhotoObject *)firstPhoto makeSessionTaskWithSession:_backgroundSession];
        }
        else if([firstPhoto isKindOfClass:[PDLocalPhotoObject class]]) {
            sessionTask = [(PDLocalPhotoObject *)firstPhoto makeSessionTaskWithSession:_backgroundSession];
        }
        if (sessionTask) {
            [sessionTask resume];
        }
    }
    
    [[self class] donnedASessionTask];
}

#pragma mark NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"%s", __func__);
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    PDBasePhotoObject *photoObject = [PDTaskManager getFirstTaskObject].photos.firstObject;
    
    if ([photoObject isKindOfClass:[PDWebPhotoObject class]]) {
        PDWebPhotoObject *webPhotoObject = (PDWebPhotoObject *)photoObject;
        NSManagedObjectID *webPhotoObjectID = webPhotoObject.objectID;
        [webPhotoObject finishDownloadWithData:data completion:^(NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDWebPhotoObject *photoObject = (PDWebPhotoObject *)[context objectWithID:webPhotoObjectID];
                photoObject.is_done = @(YES);
            }];
        }];
    }
    if ([photoObject isKindOfClass:[PDCopyPhotoObject class]]) {
        PDCopyPhotoObject *copyPhotoObject = (PDCopyPhotoObject *)photoObject;
        [copyPhotoObject finishDownloadWithLocation:location.absoluteString];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"%s", __func__);
    
    NSLog(@"Received Data = %lld / %lld", totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"%s", __func__);
}

#pragma mark NSURLSessionDataTask
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    PDBasePhotoObject *firstObject = [[self class] getFirstTaskObject].photos.firstObject;
    if ([firstObject isKindOfClass:[PDLocalPhotoObject class]]) {
        __block PDTaskObject *taskObject = nil;
        [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            taskObject = firstObject.task;
        }];
        if (!taskObject.to_album_id_str) {
            [(PDLocalPhotoObject *)firstObject finishMakeNewAlbumSessionWithResponse:dataTask.response data:data];
        }
        else {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                firstObject.is_done = @(YES);
            }];
        }
    }
    
    NSLog(@"%s", __func__);
}

#pragma mark DoneSessionTask
+ (void)donnedASessionTask {
    if ([PDTaskManager getCountOfTasks] == 0) {
        if ([PDTaskManager sharedManager].backgroundComplecationHandler) {
            [PDTaskManager sharedManager].backgroundComplecationHandler();
        }
    }
}

#pragma mark contextchanged
- (void)contextDidSaveNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_taskManagerChangedBlock) {
            _taskManagerChangedBlock(self);
        }
    });
}

#pragma GetData
+ (PDTaskObject *)getFirstTaskObject {
    __block PDTaskObject *taskObject = nil;
    [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:@"PDTaskObject" inManagedObjectContext:context];
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

+ (NSUInteger)getCountOfTasks {
    __block NSUInteger count = 0;
    [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        NSError *error = nil;
        count = [context countForFetchRequest:request error:&error];
    }];
    return count;
}

@end
