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
#import "PWSnowFlake.h"

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
        webToLocalAlbumTask.album_object_id_str = fromWebAlbum.id_str;
        
        [context save:nil];
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
            webPhoto.tag_sort_index = photoObject.sortIndex;
            webPhoto.task = webToLocalAlbumTask;
            
            [webToLocalAlbumTask addPhotosObject:webPhoto];
            
            PDTask *newTask = [[PDTask alloc] init];
            [newTask setDownloadTaskFromWebObject:webPhoto backgroundSession:sself.backgroundSession completion:^(NSURLSessionDownloadTask *task, NSError *error) {
                index++;
                if (index == count) {
                    if (completion) {
                        completion(nil);
                    }
                    
                    NSError *error = nil;
                    [context save:&error];
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
    [[PDTaskManager sharedManager] addTaskFromLocalAlbum:fromLocalAlbum toWebAlbum:toWebAlbum completion:completion];
}

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion {
    if (fromLocalAlbum.photos.count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:400 userInfo:nil]);
        }
        return;
    }
    
    __weak typeof(self) wself = self;
    [PDCoreDataAPI barrierAsyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PDLocalToWebAlbumTaskObject *localToWebAlbumTask = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalToWebAlbumTaskObjectName inManagedObjectContext:context];
        localToWebAlbumTask.album_object_id_str = fromLocalAlbum.id_str;
        localToWebAlbumTask.destination_album_id_str = toWebAlbum.id_str;
        
        __block NSUInteger index = 0;
        
        NSMutableArray *id_strs = [NSMutableArray array];
        [PLCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            for (PLPhotoObject *photoObject in fromLocalAlbum.photos.array) {
                [id_strs addObject:photoObject.id_str];
            }
        }];
        
        NSUInteger count = id_strs.count;
        for (NSString *id_str in id_strs) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
            
            localPhoto.photo_object_id_str = id_str;
            localPhoto.task = localToWebAlbumTask;
            
            [localToWebAlbumTask addPhotosObject:localPhoto];
            
            PDTask *newTask = [[PDTask alloc] init];
            [newTask setUploadTaskFromLocalObject:localPhoto toWebAlbumID:localToWebAlbumTask.destination_album_id_str backgroundSession:sself.backgroundSession completion:^(NSError *error) {
                index++;
                if (index == count) {
                    if (completion) {
                        completion(nil);
                    }
                }
            }];
            newTask.taskObject = localToWebAlbumTask;
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
    NSLog(@"Status Code = %lu", (unsigned long)statusCode);
    
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
            
            [PLCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", webToLocalAlbumTask.destination_album_object_id_str];
                NSError *error = nil;
                __block PLAlbumObject *localAlbumObject = nil;
                NSArray *albums = [context executeFetchRequest:request error:&error];
                if (albums.count > 0) {
                    localAlbumObject = albums.firstObject;
                }
                else {
                    //アルバムがないので新しく作る
                    [PWCoreDataAPI syncBlock:^(NSManagedObjectContext *webContext) {
                        //情報を得るためにウェブアルバムを取得する
                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
                        request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:webContext];
                        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", webToLocalAlbumTask.album_object_id_str];
                        NSError *error = nil;
                        NSArray *albums = [webContext executeFetchRequest:request error:&error];
                        if (albums.count > 0) {
                            PWAlbumObject *webAlbumObject = albums.firstObject;
                            
                            localAlbumObject = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
                            localAlbumObject.id_str = [PWSnowFlake generateUniqueIDString];
                            localAlbumObject.name = webAlbumObject.title;
                            // TODO: 後でやること
//                            localAlbumObject.tag_date = adjustedDate;
                            localAlbumObject.timestamp = @(webAlbumObject.timestamp.integerValue);
                            NSDate *enumurateDate = [NSDate date];
                            localAlbumObject.import = enumurateDate;
                            localAlbumObject.update = enumurateDate;
                            localAlbumObject.tag_type = @(PLAlbumObjectTagTypeAutomatically);
                            
                            webToLocalAlbumTask.destination_album_object_id_str = localAlbumObject.id_str;
                            
                            [context save:nil];
                        }
                    }];
                }
                
                [PLAssetsManager assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                    
                    if (localAlbumObject.tag_type.integerValue == PLAlbumObjectTagTypeImported) {
                        [PLAssetsManager groupForURL:[NSURL URLWithString:localAlbumObject.url] resultBlock:^(ALAssetsGroup *group) {
                            [group addAsset:asset];
                        } failureBlock:^(NSError *error) {
                            
                        }];
                    }
                    else {
                        PLPhotoObject *photo = [NSEntityDescription insertNewObjectForEntityForName:kPLPhotoObjectName inManagedObjectContext:context];
                        NSURL *url = asset.defaultRepresentation.url;
                        photo.url = url.absoluteString;
                        CGSize dimensions = asset.defaultRepresentation.dimensions;
                        photo.width = @(dimensions.width);
                        photo.height = @(dimensions.height);
                        photo.filename = asset.defaultRepresentation.filename;
                        photo.type = [asset valueForProperty:ALAssetPropertyType];
                        NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
                        photo.timestamp = @((unsigned long)([date timeIntervalSince1970]) * 1000);
                        CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
                        photo.date = date;
                        photo.latitude = @(location.coordinate.latitude);
                        photo.longitude = @(location.coordinate.longitude);
                        NSDate *enumurateDate = [NSDate date];
                        photo.update = enumurateDate;
                        photo.import = enumurateDate;
                        
                        photo.tag_albumtype = @(PLAlbumObjectTagTypeImported);
                        photo.id_str = url.query;
                        
                        [localAlbumObject addPhotosObject:photo];
                        
                        [context save:nil];
                    }
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
