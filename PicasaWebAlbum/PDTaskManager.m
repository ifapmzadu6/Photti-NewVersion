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

static NSString * const kPDTaskManagerErrorDomain = @"PDTaskManagerErrorDomain";

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

- (void)addTaskFromWebPhotos:(NSArray *)fromWebPhotos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (fromWebPhotos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
}


- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (fromWebAlbum.tag_numphotos.intValue == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
}

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion {
    if (fromLocalAlbum.photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
    
}

- (void)addTaskPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (photos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
}

- (void)addTaskFromWebPhotos:(NSArray *)fromWebPhotos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (fromWebPhotos.count == 0) {
        if (completion) completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        return;
    }
    if (![self checkOKAddTask]) return;
    
//    [PDCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
//        PDWebToWebPhotosTask *webToWebPhotoTask = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalToWebPhotosTaskObjectName inManagedObjectContext:context];
//        webToWebPhotoTask.destination_album_id_str = toWebAlbum.id_str;
//        
//        NSMutableArray *id_strs = [NSMutableArray array];
//        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
//            for (PLPhotoObject *photoObject in fromWebPhotos) {
//                [id_strs addObject:photoObject.id_str];
//            }
//        }];
//        
//        for (NSString *id_str in id_strs) {
//            PDWebPhotoObject *downloadPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDWebPhotoObjectName inManagedObjectContext:context];
//            downloadPhoto.photo_object_id_str = id_str;
//            downloadPhoto.task = webToWebPhotoTask;
//            [webToWebPhotoTask addPhotosObject:downloadPhoto];
//            
//            PDLocalPhotoObject *uploadPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
//            uploadPhoto.task = webToWebPhotoTask;
//            [webToWebPhotoTask addPhotosObject:uploadPhoto];
//            
//            if (completion) {
//                completion(nil);
//            }
//            [[self class] performTaskManagerChangedBlock];
//        }
//    }];
}

- (void)countOfAllPhotosInTaskWithCompletion:(void (^)(NSUInteger count, NSError *error))completion {
    if (!completion) return;
    
    [PDCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
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
//    __weak typeof(self) wself = self;
//    [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
//        typeof(wself) sself = wself;
//        if (!sself) return;
//        
//        if (dataTasks.count == 0 && uploadTasks.count == 0 && downloadTasks.count == 0) {
//            PDBasePhotoObject *firstPhoto = [PDTaskManager getAllPhotoObject].firstObject;
//            NSURLSessionTask *task = [sself makeSessionTaskWithPhoto:firstPhoto];
//            if (task.state != NSURLSessionTaskStateRunning) {
//                [task resume];
//            }
//        }
//    }];
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
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    NSLog(@"%s", __func__);
}

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
    
    NSArray *allPhotoObject = [PDTaskManager getAllPhotoObject];
    PDBasePhotoObject *firstPhoto = allPhotoObject.firstObject;
    PDTaskObject *taskObject = firstPhoto.task;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        [taskObject removePhotosObject:firstPhoto];
        [context deleteObject:firstPhoto];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_taskManagerChangedBlock) {
            _taskManagerChangedBlock(self);
        }
    });
    
    if (allPhotoObject.count > 1) {
        NSURLSessionTask *task = [self makeSessionTaskWithPhoto:allPhotoObject[1]];
        if (task) {
            [task resume];
        }
    }
    else {
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            [context deleteObject:taskObject];
        }];
    }
}

#pragma mark NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"%s", __func__);
    
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    PDBasePhotoObject *photoObject = [PDTaskManager getAllPhotoObject].firstObject;
    
    if ([photoObject isKindOfClass:[PDWebPhotoObject class]]) {
        PDWebPhotoObject *webPhotoObject = (PDWebPhotoObject *)photoObject;
        [webPhotoObject finishDownloadWithData:data completion:^(NSError *error) {
            
        }];
    }
    if ([photoObject isKindOfClass:[PDLocalPhotoObject class]]) {
        
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"%s", __func__);
    
    NSLog(@"Received Data = %lld / %lld", totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"%s", __func__);
}

#pragma mark MakeSessionTask
- (NSURLSessionTask *)makeSessionTaskWithPhoto:(PDBasePhotoObject *)basePhoto {
    if ([basePhoto isKindOfClass:[PDWebPhotoObject class]]) {
        return [(PDWebPhotoObject *)basePhoto makeSessionTaskWithSession:_backgroundSession];
    }
    else if([basePhoto isKindOfClass:[PDLocalPhotoObject class]]) {
        return [(PDLocalPhotoObject *)basePhoto makeSessionTaskWithSession:_backgroundSession];
    }
    
    return nil;
}

#pragma mark DoneSessionTask
+ (void)donnedASessionTask {
    if ([PDTaskManager getCountOfTasks] == 0) {
        if ([PDTaskManager sharedManager].backgroundComplecationHandler) {
            [PDTaskManager sharedManager].backgroundComplecationHandler();
        }
    }
}

#pragma GetData

+ (void)getWebPhotoWithID:(NSString *)id_str completion:(void (^)(PWPhotoObject *webPhotoObject))completion {
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        NSError *error = nil;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (albums.count > 0) {
            if (completion) {
                completion(albums.firstObject);
            }
        }
    }];
}



+ (NSArray *)getAllPhotoObject {
    __block NSArray *photoObjects = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPDBasePhotoObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tag_sort_index" ascending:YES]];
        NSError *error = nil;
        photoObjects = [context executeFetchRequest:request error:&error];
    }];
    return photoObjects;
}

+ (NSUInteger)getCountOfTasks {
    __block NSUInteger count = 0;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPDTaskObjectName inManagedObjectContext:context];
        NSError *error = nil;
        count = [context countForFetchRequest:request error:&error];
    }];
    return count;
}


@end
