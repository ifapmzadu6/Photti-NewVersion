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

@property (strong, nonatomic) NSMutableArray *tasks;

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
        
        _tasks = @[].mutableCopy;
    }
    return self;
}

+ (NSURLSession *)sharedSession {
    return [[PDTaskManager sharedManager] backgroundSession];
}

- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (fromWebAlbum.tag_numphotos.intValue == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    
    if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) {
        if (_notPurchasedUploadDownloadAction) {
            _notPurchasedUploadDownloadAction();
        }
        return;
    }
    
    NSString *webAlbumId = fromWebAlbum.id_str;
    if (!webAlbumId) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block PDWebToLocalAlbumTaskObject *webToLocalAlbumTask = nil;
        [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            webToLocalAlbumTask = [NSEntityDescription insertNewObjectForEntityForName:kPDWebToLocalAlbumTaskObjectName inManagedObjectContext:context];
            webToLocalAlbumTask.album_object_id_str = webAlbumId;
            
            [context save:nil];
        }];
        
        NSMutableArray *photoObjectIDs = @[].mutableCopy;
        NSMutableDictionary *photoObjectSortIndexs = @{}.mutableCopy;
        [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", webAlbumId];
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
            NSError *error = nil;
            NSArray *photos = [context executeFetchRequest:request error:&error];
            if (photos.count == 0) {
                if (completion) {
                    completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
                }
                return;
            }
            
            for (PWPhotoObject *photoObject in photos) {
                [photoObjectIDs addObject:photoObject.id_str];
                [photoObjectSortIndexs setObject:photoObject.sortIndex forKey:photoObject.id_str];
            }
        }];
        
        [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            for (NSString *photoObjectID in photoObjectIDs) {
                PDWebPhotoObject *webPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDWebPhotoObjectName inManagedObjectContext:context];
                webPhoto.photo_object_id_str = photoObjectID;
                webPhoto.tag_sort_index = photoObjectSortIndexs[photoObjectID];
                webPhoto.task = webToLocalAlbumTask;
                [webToLocalAlbumTask addPhotosObject:webPhoto];
                
                PDTask *newTask = [PDTask new];
                newTask.taskObject = webToLocalAlbumTask;
                [sself.tasks addObject:newTask];
            }
            
            [context save:nil];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (completion) {
                    completion(nil);
                }
            });
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (sself.taskManagerChangedBlock) {
                    sself.taskManagerChangedBlock(sself);
                }
            });
        }];
    });
}

- (void)addTaskFromWebPhotos:(NSArray *)fromWebPhotos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *))completion {
    if (fromWebPhotos.count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    
    if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) {
        if (_notPurchasedUploadDownloadAction) {
            _notPurchasedUploadDownloadAction();
        }
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block PDWebToLocalPhotosTaskObject *webToLocalPhotosTask = nil;
        [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            webToLocalPhotosTask = [NSEntityDescription insertNewObjectForEntityForName:kPDWebToLocalAlbumTaskObjectName inManagedObjectContext:context];
            [context save:nil];
        }];
        
        [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            for (PWPhotoObject *photoObject in fromWebPhotos) {
                PDWebPhotoObject *webPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDWebPhotoObjectName inManagedObjectContext:context];
                webPhoto.photo_object_id_str = photoObject.id_str;
                webPhoto.tag_sort_index = photoObject.sortIndex;
                webPhoto.task = webToLocalPhotosTask;
                [webToLocalPhotosTask addPhotosObject:webPhoto];
                
                PDTask *newTask = [PDTask new];
                newTask.taskObject = webToLocalPhotosTask;
                [sself.tasks addObject:newTask];
            }
            
            [context save:nil];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (completion) {
                    completion(nil);
                }
            });
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (sself.taskManagerChangedBlock) {
                    sself.taskManagerChangedBlock(sself);
                }
            });
        }];
    });
}

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion {
    if (fromLocalAlbum.photos.count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    
    if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) {
        if (_notPurchasedUploadDownloadAction) {
            _notPurchasedUploadDownloadAction();
        }
        return;
    }
    
    // TODO: webAlbum = nil ならアルバム新規作成のタスクを投げる
    
    __weak typeof(self) wself = self;
    [PDCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PDLocalToWebAlbumTaskObject *localToWebAlbumTask = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalToWebAlbumTaskObjectName inManagedObjectContext:context];
        localToWebAlbumTask.album_object_id_str = fromLocalAlbum.id_str;
        localToWebAlbumTask.destination_album_id_str = toWebAlbum.id_str;
        
        NSMutableArray *id_strs = [NSMutableArray array];
        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            for (PLPhotoObject *photoObject in fromLocalAlbum.photos.array) {
                [id_strs addObject:photoObject.id_str];
            }
        }];
        
        __block NSUInteger index = 0;
        NSUInteger count = id_strs.count;
        for (NSString *id_str in id_strs) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
            localPhoto.photo_object_id_str = id_str;
            localPhoto.task = localToWebAlbumTask;
            [localToWebAlbumTask addPhotosObject:localPhoto];
            
            PDTask *newTask = [PDTask new];
            [newTask setUploadTaskFromLocalObject:localPhoto toWebAlbumID:localToWebAlbumTask.destination_album_id_str completion:^(NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                
                index++;
                if (index == count) {
                    [context save:nil];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        if (completion) {
                            completion(nil);
                        }
                    });
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        if (sself.taskManagerChangedBlock) {
                            sself.taskManagerChangedBlock(sself);
                        }
                    });
                }
            }];
            newTask.taskObject = localToWebAlbumTask;
            [sself.tasks addObject:newTask];
        }
    }];
}

- (void)addTaskFromLocalPhotos:(NSArray *)fromLocalPhotos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion {
    if (fromLocalPhotos.count == 0) {
        if (completion) {
            completion([NSError errorWithDomain:kPDTaskManagerErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    
    if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) {
        if (_notPurchasedUploadDownloadAction) {
            _notPurchasedUploadDownloadAction();
        }
        return;
    }
    
    __weak typeof(self) wself = self;
    [PDCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PDLocalToWebPhotosTaskObject *localToWebPhotoTask = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalToWebPhotosTaskObjectName inManagedObjectContext:context];
        localToWebPhotoTask.destination_album_id_str = toWebAlbum.id_str;
        
        NSMutableArray *id_strs = [NSMutableArray array];
        [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            for (PLPhotoObject *photoObject in fromLocalPhotos) {
                [id_strs addObject:photoObject.id_str];
            }
        }];
        
        __block NSUInteger index = 0;
        NSUInteger count = id_strs.count;
        for (NSString *id_str in id_strs) {
            PDLocalPhotoObject *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:kPDLocalPhotoObjectName inManagedObjectContext:context];
            localPhoto.photo_object_id_str = id_str;
            localPhoto.task = localToWebPhotoTask;
            [localToWebPhotoTask addPhotosObject:localPhoto];
            
            PDTask *newTask = [PDTask new];
            [newTask setUploadTaskFromLocalObject:localPhoto toWebAlbumID:localToWebPhotoTask.destination_album_id_str completion:^(NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                
                index++;
                if (index == count) {
                    [context save:nil];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        if (completion) {
                            completion(nil);
                        }
                    });
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        if (sself.taskManagerChangedBlock) {
                            sself.taskManagerChangedBlock(sself);
                        }
                    });
                }
            }];
            newTask.taskObject = localToWebPhotoTask;
            [sself.tasks addObject:newTask];
        }
    }];
}

- (void)countOfAllPhotosInTaskWithCompletion:(void (^)(NSUInteger count, NSError *error))completion {
    if (!completion) {
        return;
    }
    
    [PDCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
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
    PDBaseTaskObject *taskObject = firstPhoto.task;
    [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
        [taskObject removePhotosObject:firstPhoto];
        [context deleteObject:firstPhoto];
        [context save:nil];
    }];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if (sself.taskManagerChangedBlock) {
            sself.taskManagerChangedBlock(sself);
        }
    });
    
    if (allPhotoObject.count > 1) {
        NSURLSessionTask *task = [self makeSessionTaskWithPhoto:allPhotoObject[1]];
        [task resume];
    }
    else {
        [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            [context deleteObject:taskObject];
            [context save:nil];
        }];
    }
}

#pragma mark NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"%s", __func__);
    
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    PDBasePhotoObject *photoObject = [PDTaskManager getAllPhotoObject].firstObject;
    PDBaseTaskObject *baseTaskObject = photoObject.task;
    
    if ([baseTaskObject isKindOfClass:[PDWebToLocalAlbumTaskObject class]]) {
        PDWebToLocalAlbumTaskObject *webToLocalAlbumTask = (PDWebToLocalAlbumTaskObject *)baseTaskObject;
        
        __weak typeof(self) wself = self;
        [[PLAssetsManager sharedLibrary] writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            __block PLAlbumObject *localAlbumObject = [PDTaskManager getLocalAlbumWithID:webToLocalAlbumTask.destination_album_object_id_str];
            if (!localAlbumObject) {
                //アルバムがないので新しく作る
                [PDTaskManager getWebAlbumWithID:webToLocalAlbumTask.album_object_id_str completion:^(PWAlbumObject *webAlbumObject) {
                    if (!webAlbumObject) return;
                    localAlbumObject = [PDTaskManager makeNewLocalAlbumWithWebAlbum:webAlbumObject];
                }];
                
                webToLocalAlbumTask.destination_album_object_id_str = localAlbumObject.id_str;
                [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
                    [context save:nil];
                }];
            }
            
            [[PLAssetsManager sharedLibrary] assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                typeof(wself) sself = wself;
                if (!sself) return;
                
                if (localAlbumObject.tag_type.integerValue == PLAlbumObjectTagTypeImported) {
                    [[PLAssetsManager sharedLibrary] groupForURL:[NSURL URLWithString:localAlbumObject.url] resultBlock:^(ALAssetsGroup *group) {
                        [group addAsset:asset];
                        
                        [PDTaskManager donnedASessionTask];
                    } failureBlock:^(NSError *error) {
                        [PDTaskManager donnedASessionTask];
                    }];
                }
                else {
                    PLPhotoObject *photo = [PDTaskManager makeNewPhotoWithAsset:asset];
                    [localAlbumObject addPhotosObject:photo];
                    
                    [PDTaskManager donnedASessionTask];
                }
            } failureBlock:^(NSError *error) {
                [PDTaskManager donnedASessionTask];
            }];
        }];
    }
    else if ([baseTaskObject isKindOfClass:[PDWebToLocalPhotosTaskObject class]]) {
//        PDWebToLocalPhotosTaskObject *webToPhotosTask = (PDWebToLocalPhotosTaskObject *)baseTaskObject;
        
        
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
        PDWebPhotoObject *webPhotoObject = (PDWebPhotoObject *)basePhoto;
        __block NSMutableURLRequest *request = nil;
        [PDTaskManager getWebPhotoWithID:webPhotoObject.photo_object_id_str completion:^(PWPhotoObject *webPhotoObject) {
            NSURL *url = [NSURL URLWithString:webPhotoObject.tag_originalimage_url];
            [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *authorizedRequest, NSError *error) {
                request = authorizedRequest;
            }];
        }];
        if (!request) {
            return nil;
        }
        else {
            return [_backgroundSession downloadTaskWithRequest:request];
        }
    }
    else if([basePhoto isKindOfClass:[PDLocalPhotoObject class]]) {
        PDLocalPhotoObject *localPhotoObject = (PDLocalPhotoObject *)basePhoto;
        PDBaseTaskObject *baseTaskObject = localPhotoObject.task;
        NSString *webAlbumID = nil;
        if ([baseTaskObject isKindOfClass:[PDLocalToWebAlbumTaskObject class]]) {
            PDLocalToWebAlbumTaskObject *taskObject = (PDLocalToWebAlbumTaskObject *)baseTaskObject;
            webAlbumID = taskObject.destination_album_id_str;
        }
        else if ([baseTaskObject isKindOfClass:[PDLocalToWebPhotosTaskObject class]]) {
            PDLocalToWebPhotosTaskObject *taskObject = (PDLocalToWebPhotosTaskObject *)baseTaskObject;
            webAlbumID = taskObject.destination_album_id_str;
        }
        if (!webAlbumID) return nil;
        
        NSString *requestUrlString = [NSString stringWithFormat:@"https://picasaweb.google.com/data/feed/api/user/default/albumid/%@", webAlbumID];
        NSURL *url = [NSURL URLWithString:requestUrlString];
        PLPhotoObject *photoObject = [PDTaskManager getLocalPhotoWithID:localPhotoObject.photo_object_id_str];
        if (!photoObject) return nil;
        if ([photoObject.type isEqualToString:ALAssetTypePhoto]) {
            __block NSURLSessionTask *sessionTask = nil;
            [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
                request.HTTPMethod = @"POST";
                [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
                NSString *filePath = localPhotoObject.prepared_body_filepath;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)fileAttributes[NSFileSize]] forHTTPHeaderField:@"Content-Length"];
                sessionTask = [_backgroundSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
            }];
            
            return sessionTask;
        }
        else if ([photoObject.type isEqualToString:ALAssetTypeVideo]) {
            __block NSURLSessionTask *sessionTask = nil;
            [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
                request.HTTPMethod = @"POST";
                [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:@"Content-Type"];
                [request addValue:@"1.0" forHTTPHeaderField:@"MIME-version"];
                NSString *filePath = localPhotoObject.prepared_body_filepath;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)fileAttributes[NSFileSize]] forHTTPHeaderField:@"Content-Length"];
                sessionTask = [_backgroundSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
            }];
            
            return sessionTask;
        }
        else {
            
        }
        
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
+ (void)getWebAlbumWithID:(NSString *)id_str completion:(void (^)(PWAlbumObject *webAlbumObject))completion {
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
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

+ (PLAlbumObject *)getLocalAlbumWithID:(NSString *)id_str {
    __block PLAlbumObject *localAlbumObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLAlbumObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        NSError *error = nil;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (albums.count > 0) {
            localAlbumObject = albums.firstObject;
        }
    }];
    return localAlbumObject;
}

+ (PLPhotoObject *)getLocalPhotoWithID:(NSString *)id_str {
    __block PLPhotoObject *localPhotoObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        NSError *error = nil;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (albums.count > 0) {
            localPhotoObject = albums.firstObject;
        }
    }];
    return localPhotoObject;
}

+ (NSArray *)getAllPhotoObject {
    __block NSArray *photoObjects = nil;
    [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
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
    [PDCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPDBaseTaskObjectName inManagedObjectContext:context];
        NSError *error = nil;
        count = [context countForFetchRequest:request error:&error];
    }];
    return count;
}

#pragma mark MakeData
+ (PLAlbumObject *)makeNewLocalAlbumWithWebAlbum:(PWAlbumObject *)webAlbumObject {
    __block PLAlbumObject *localAlbumObject = nil;
    [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        localAlbumObject = [NSEntityDescription insertNewObjectForEntityForName:kPLAlbumObjectName inManagedObjectContext:context];
        localAlbumObject.id_str = [PWSnowFlake generateUniqueIDString];
        localAlbumObject.name = webAlbumObject.title;
        localAlbumObject.tag_date = [NSDate dateWithTimeIntervalSince1970:webAlbumObject.timestamp.longLongValue / 1000];
        localAlbumObject.timestamp = @(webAlbumObject.timestamp.longLongValue);
        NSDate *enumurateDate = [NSDate date];
        localAlbumObject.import = enumurateDate;
        localAlbumObject.update = enumurateDate;
        localAlbumObject.tag_type = @(PLAlbumObjectTagTypeAutomatically);
    }];
    return localAlbumObject;
}

+ (PLPhotoObject *)makeNewPhotoWithAsset:(ALAsset *)asset {
    __block PLPhotoObject *photoObject = nil;
    [PLCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        photoObject = [NSEntityDescription insertNewObjectForEntityForName:kPLPhotoObjectName inManagedObjectContext:context];
        NSURL *url = asset.defaultRepresentation.url;
        photoObject.url = url.absoluteString;
        CGSize dimensions = asset.defaultRepresentation.dimensions;
        photoObject.width = @(dimensions.width);
        photoObject.height = @(dimensions.height);
        photoObject.filename = asset.defaultRepresentation.filename;
        photoObject.type = [asset valueForProperty:ALAssetPropertyType];
        NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
        photoObject.timestamp = @((long long)([date timeIntervalSince1970]) * 1000);
        CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
        photoObject.date = date;
        photoObject.latitude = @(location.coordinate.latitude);
        photoObject.longitude = @(location.coordinate.longitude);
        NSDate *enumurateDate = [NSDate date];
        photoObject.update = enumurateDate;
        photoObject.import = enumurateDate;
        
        photoObject.tag_albumtype = @(PLAlbumObjectTagTypeImported);
        photoObject.id_str = url.query;
    }];
    return photoObject;
}

@end
