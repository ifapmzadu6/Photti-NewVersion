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
#import "NSURLResponse+methods.h"

static NSString * const kPDTaskManagerBackgroundSessionIdentifier = @"kPDBSI";

@interface PDTaskManager () <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSURLSession *backgroundSession;

@property (nonatomic) BOOL isPreparing;
@property (strong, nonatomic) NSURL *location;
@property (strong, nonatomic) NSData *uploadResponseData;

@property (nonatomic) BOOL operating;

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
    if (fromWebAlbum.gphoto.numphotos.intValue == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromWebAlbum:fromWebAlbum toLocalAlbum:toLocalAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        NSUInteger count = [PDTaskManager getCountOfTasks];
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            taskObject.sort_index = @(count);
        }];
        
        if (completion) {
            completion(nil);
        }
        
        [[PDTaskManager sharedManager] start];
    }];
}

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion {
    if (fromLocalAlbum.photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromLocalAlbum:fromLocalAlbum toWebAlbum:toWebAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        NSUInteger count = [PDTaskManager getCountOfTasks];
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            taskObject.sort_index = @(count);
        }];
        
        if (completion) {
            completion(nil);
        }
        
        [[PDTaskManager sharedManager] start];
    }];
}

- (void)addTaskPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromPhotos:photos toWebAlbum:toWebAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        NSUInteger count = [PDTaskManager getCountOfTasks];
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            taskObject.sort_index = @(count);
        }];
        
        if (completion) {
            completion(nil);
        }
        
        [[PDTaskManager sharedManager] start];
    }];
}

- (void)addTaskPhotos:(NSArray *)photos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    [PDTaskObjectFactoryMethods makeTaskFromPhotos:photos toLocalAlbum:toLocalAlbum completion:^(NSManagedObjectID *taskObjectID, NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        NSUInteger count = [PDTaskManager getCountOfTasks];
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *taskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            taskObject.sort_index = @(count);
        }];
        
        if (completion) {
            completion(nil);
        }
        
        [[PDTaskManager sharedManager] start];
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
    if (_operating) {
        return;
    }
    _operating = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            if (dataTasks.count == 0 && uploadTasks.count == 0 && downloadTasks.count == 0) {
                PDTaskObject *taskObject = [PDTaskManager getFirstTaskObject];
                [self taskIsDoneAndStartNext:taskObject];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            for (NSURLSessionTask *task in dataTasks) [task cancel];
            for (NSURLSessionTask *task in uploadTasks) [task cancel];
            for (NSURLSessionTask *task in downloadTasks) [task cancel];
        }];
    });
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"%s", __func__);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"%s", __func__);
}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
//    NSLog(@"%s", __func__);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"%s", __func__);
    
    if (error || !task.response.isSuccess) {
        NSLog(@"%@", error.description);
        return;
    }
    
    if ([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
        NSURL *location = _location;
        _location = nil;
        
        PDBasePhotoObject *photoObject = [PDTaskManager getFirstTaskObject].photos.firstObject;
        if (![photoObject.session_task_identifier isEqualToNumber:@(task.taskIdentifier)]) {
            NSLog(@"[ERROR] DB not match session task!");
            return;
        }
        
        if ([photoObject isKindOfClass:[PDWebPhotoObject class]]) {
            PDWebPhotoObject *webPhotoObject = (PDWebPhotoObject *)photoObject;
            [webPhotoObject finishDownloadWithLocation:location completion:^(NSError *error) {
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                
                [self taskIsDoneAndStartNext:[[self class] getFirstTaskObject]];
            }];
        }
        else if ([photoObject isKindOfClass:[PDCopyPhotoObject class]]) {
            PDCopyPhotoObject *copyPhotoObject = (PDCopyPhotoObject *)photoObject;
            [copyPhotoObject finishDownloadWithLocation:location];
            
            [self taskIsDoneAndStartNext:[[self class] getFirstTaskObject]];
        }
    }
    else if ([task isKindOfClass:[NSURLSessionUploadTask class]]) {
        PDBasePhotoObject *photoObject = [PDTaskManager getFirstTaskObject].photos.firstObject;
        
        if ([photoObject isKindOfClass:[PDCopyPhotoObject class]]) {
            [(PDCopyPhotoObject *)photoObject finishUpload];
        }
        else if ([photoObject isKindOfClass:[PDLocalPhotoObject class]]) {
            __block PDTaskObject *taskObject = nil;
            [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
                taskObject = photoObject.task;
            }];
            
            NSData *data = _uploadResponseData;
            _uploadResponseData = nil;
            if (!taskObject.to_album_id_str) {
                [(PDLocalPhotoObject *)photoObject finishMakeNewAlbumSessionWithResponse:task.response data:data];
            }
            else {
                [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                    photoObject.is_done = @(YES);
                }];
            }
        }
        [self taskIsDoneAndStartNext:[[self class] getFirstTaskObject]];
    }
}

- (void)taskIsDoneAndStartNext:(PDTaskObject *)taskObject {
    if (!taskObject) {
        _operating = NO;
        
        if (_backgroundComplecationHandler) {
            _backgroundComplecationHandler();
            _backgroundComplecationHandler = nil;
        }
        
        return;
    }
    NSManagedObjectID *taskObjectID = taskObject.objectID;
    
    NSArray *allPhotoObject = taskObject.photos.array;
    if (allPhotoObject.count == 0) {
        if (taskObject.type.integerValue == PDTaskObjectTypeLocalAlbumToWebAlbum || taskObject.type.integerValue == PDTaskObjectTypePhotosToWebAlbum) {
            [PWPicasaAPI getListOfAlbumsWithIndex:0 completion:nil];
        }
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *tmpTaskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            [context deleteObject:tmpTaskObject];
        }];
        
        [self taskIsDoneAndStartNext:[[self class] getFirstTaskObject]];
        return;
    }
    
    PDBasePhotoObject *photoObject = allPhotoObject.firstObject;
    NSManagedObjectID *photoObjectID = photoObject.objectID;
    if (photoObject.is_done.boolValue) {
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDTaskObject *tmpTaskObject = (PDTaskObject *)[context objectWithID:taskObjectID];
            PDBasePhotoObject *tmpPhotoObject = (PDBasePhotoObject *)[context objectWithID:photoObjectID];
            [tmpTaskObject removePhotosObject:tmpPhotoObject];
            [context deleteObject:tmpPhotoObject];
        }];
        
        [self taskIsDoneAndStartNext:[[self class] getFirstTaskObject]];
    }
    else {
        if (![photoObject isKindOfClass:[PDLocalCopyPhotoObject class]]) {
            [photoObject makeSessionTaskWithSession:_backgroundSession completion:^(NSURLSessionTask *task, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.description);
                }
                else {
                    [task resume];
                }
            }];
        }
        else {
            [(PDLocalCopyPhotoObject *)photoObject copyToLocalAlbum];
            
            [self taskIsDoneAndStartNext:[[self class] getFirstTaskObject]];
        }
    }
}

#pragma mark NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
//    NSLog(@"%s", __func__);
    
    NSString *filePath = [[self class] makeUniquePathInTmpDir];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error]) {
        NSLog(@"%@", error.description);
    }
    
    _location = fileURL;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
//    NSLog(@"%s", __func__);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

#pragma mark NSURLSessionDataTask
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
//    NSLog(@"%s", __func__);
    _uploadResponseData = data;
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

#pragma mark FilePath
+ (NSString *)makeUniquePathInTmpDir {
    NSString *homeDirectory = [NSString stringWithString:NSHomeDirectory()];
    NSString *tmpDirectory = [homeDirectory stringByAppendingPathComponent:@"/tmp"];
    NSString *filePath = [tmpDirectory stringByAppendingFormat:@"/%@", [PWSnowFlake generateUniqueIDString]];
    return filePath;
}

@end
