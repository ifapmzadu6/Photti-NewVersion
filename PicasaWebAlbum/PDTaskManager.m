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

#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"

#import "PWModelObject.h"
#import "PWCoreDataAPI.h"

@interface PDTaskManager ()

@property (strong, nonatomic) NSURLSession *backgroundSession;

@property (strong, nonatomic) NSMutableArray *tasks;

@end

@implementation PDTaskManager

static NSString * const kPDTaskManagerErrorDomain = @"PDTaskManagerErrorDomain";

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kPDBackgroundSessionIdentifier];
        config.HTTPMaximumConnectionsPerHost = 1;
        _backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        
        _tasks = @[].mutableCopy;
    }
    return self;
}

+ (NSURLSession *)sharedSession {
    return [[PDTaskManager sharedManager] backgroundSession];
}

+ (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    [[PDTaskManager sharedManager] addTaskFromWebAlbum:fromWebAlbum toLocalAlbum:toLocalAlbum completion:completion];
}

- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    NSUInteger count = fromWebAlbum.tag_numphotos.intValue;
    if (count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:400 userInfo:nil]);
        }
        return;
    }
    
    __block PDWebToLocalAlbumTaskObject *webToLocalAlbumTask = nil;
    [PDCoreDataAPI barrierSyncBlock:^(NSManagedObjectContext *context) {
        webToLocalAlbumTask = [NSEntityDescription insertNewObjectForEntityForName:kPDWebToLocalAlbumTaskObjectName inManagedObjectContext:context];
        webToLocalAlbumTask.album_object_id_str = toLocalAlbum.id_str;
    }];
    
    __block NSArray *photos = nil;
    [PWCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", fromWebAlbum.id_str];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        NSError *error = nil;
        photos = [context executeFetchRequest:request error:&error];
    }];
    if (photos.count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    
    __weak typeof(self) wself = self;
    [PDCoreDataAPI barrierSyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        __block NSUInteger index = 0;
        NSUInteger count = photos.count;
        for (PWPhotoObject *photoObject in photos) {
            PDWebPhotoObject *webPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDWebPhotoObjectName inManagedObjectContext:context];
            
            webPhoto.photo_object_id_str = photoObject.id_str;
            webPhoto.task = webToLocalAlbumTask;
            
            [webToLocalAlbumTask addPhotosObject:webPhoto];
            
            PDTask *newTask = [[PDTask alloc] init];
            [newTask setDownloadTaskFromWebObject:webPhoto backgroundSession:sself.backgroundSession completion:^(NSURLSessionDownloadTask *task, NSError *error) {
                index++;
                if (index == count) {
                    if (completion) {
                        completion(nil);
                    }
                }
            }];
            newTask.taskObject = webToLocalAlbumTask;
            
            [sself.tasks addObject:newTask];
        }
        
        NSError *error = nil;
        [context save:&error];
        if (error) {
            if (completion) {
                completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:401 userInfo:nil]);
            }
            return;
        }
    }];
}

+ (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (fromLocalAlbum.photos.count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:400 userInfo:nil]);
        }
        return;
    }
    
    [PDCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
        PDLocalToWebAlbumTaskObject *localToWebAlbumTask = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalToWebAlbumTaskObjectName inManagedObjectContext:context];
        localToWebAlbumTask.album_object_id_str = fromLocalAlbum.id_str;
        localToWebAlbumTask.destination_album_id_str = toWebAlbum.id_str;
        
        __block NSUInteger index = 0;
        NSUInteger count = fromLocalAlbum.photos.array.count;
        for (PLPhotoObject *photoObject in fromLocalAlbum.photos.array) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
            
            localPhoto.photo_object_id_str = photoObject.id_str;
            localPhoto.task = localToWebAlbumTask;
            
            [localToWebAlbumTask addPhotosObject:localPhoto];
            
            PDTask *newTask = [[PDTask alloc] init];
            [newTask setUploadTaskFromLocalObject:localPhoto toWebAlbumID:localToWebAlbumTask.destination_album_id_str backgroundSession:[PDTaskManager sharedSession] completion:^(NSError *error) {
                index++;
                if (index == count) {
                    if (completion) {
                        completion(nil);
                    }
                }
            }];
            newTask.taskObject = localToWebAlbumTask;
            PDTaskManager *taskManager = [PDTaskManager sharedManager];
            [taskManager.tasks addObject:newTask];
        }
        
        NSError *error = nil;
        [context save:&error];
        if (error) {
            if (completion) {
                completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:401 userInfo:nil]);
            }
            return;
        }
    }];
}

+ (void)addTaskFromLocalPhotos:(NSArray *)fromLocalPhotos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (fromLocalPhotos.count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:400 userInfo:nil]);
        }
        return;
    }
    
    [PDCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
        PDLocalToWebPhotosTaskObject *localToWebPhotosTask = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalToWebPhotosTaskObjectName inManagedObjectContext:context];
        localToWebPhotosTask.destination_album_id_str = toWebAlbum.id_str;
        
        __block NSUInteger index = 0;
        NSUInteger count = fromLocalPhotos.count;
        for (PLPhotoObject *photoObject in fromLocalPhotos) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
            
            localPhoto.photo_object_id_str = photoObject.id_str;
            localPhoto.task = localToWebPhotosTask;
            
            [localToWebPhotosTask addPhotosObject:localPhoto];
            
            PDTask *newTask = [[PDTask alloc] init];
            [newTask setUploadTaskFromLocalObject:localPhoto toWebAlbumID:localToWebPhotosTask.destination_album_id_str backgroundSession:[PDTaskManager sharedSession] completion:^(NSError *error) {
                if (index == count) {
                    if (completion) {
                        completion(nil);
                    }
                }
            }];
            newTask.taskObject = localToWebPhotosTask;
            PDTaskManager *taskManager = [PDTaskManager sharedManager];
            [taskManager.tasks addObject:newTask];
        }
        
        NSError *error = nil;
        [context save:&error];
        if (error) {
            if (completion) {
                completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:401 userInfo:nil]);
            }
            return;
        }
    }];
}

+ (void)resumeAllTasks {
    PDTaskManager *taskManager = [PDTaskManager sharedManager];
    for (PDTask *task in taskManager.tasks) {
        NSURLSessionTask *sessionTask = task.sessionTask;
        if (sessionTask) {
            if (sessionTask.state == NSURLSessionTaskStateSuspended) {
                [sessionTask resume];
            }
        }
    }
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
    NSLog(@"Status Code = %d", statusCode);
    
    if (error) {
        NSLog(@"%@", error.description);
    }
}

#pragma mark NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"%s", __func__);
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    
    NSArray *filteredTasks = [_tasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %d", downloadTask.taskIdentifier]];
    if (filteredTasks.count == 0) {
        return;
    }
    
    PDTask *task = filteredTasks.firstObject;
    [_tasks removeObject:task];
    
    [PLAssetsManager writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        
        if ([task.taskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
            PDWebToLocalAlbumTaskObject *webToLocalAlbumTask = (PDWebToLocalAlbumTaskObject *)task.taskObject;
            
            [PLCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", webToLocalAlbumTask.album_object_id_str];
                NSError *error = nil;
                NSArray *photos = [context executeFetchRequest:request error:&error];
                if (photos.count == 0) {
                    NSLog(@"Incollect photo database.");
                    return;
                }
                PLAlbumObject *albumObject = photos.firstObject;
                
                if (albumObject.tag_type.integerValue != PLAlbumObjectTagTypeImported) {
                    return;
                }
                
                [PLAssetsManager groupForURL:[NSURL URLWithString:albumObject.url] resultBlock:^(ALAssetsGroup *group) {
                    
                    [PLAssetsManager assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        
                        [group addAsset:asset];
                        
                    } failureBlock:^(NSError *error) {
                        
                    }];
                    
                } failureBlock:^(NSError *error) {
                    
                }];
            }];
        }
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"%s", __func__);
    
    NSLog(@"Received Data = %lld / %lld", totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"%s", __func__);
}

@end
