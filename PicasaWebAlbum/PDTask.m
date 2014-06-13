//
//  PWTask.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTask.h"

#import "PDModelObject.h"
#import "PDCoreDataAPI.h"
#import "PDTaskManager.h"

#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PWSnowFlake.h"

#import "PWPicasaAPI.h"

@import ImageIO;
@import MobileCoreServices;
@import AVFoundation;

@interface PDTask ()

@end

@implementation PDTask

static NSString * const kPDTaskErrorDomain = @"PDTaskErrorDomain";

static dispatch_queue_t pd_task_queue() {
    static dispatch_queue_t pd_task_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pd_task_queue = dispatch_queue_create("com.photti.pdtask", DISPATCH_QUEUE_SERIAL);
    });
    return pd_task_queue;
}

- (id)initWithTaskObject:(PDBaseTaskObject *)taskObject {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setUploadTaskFromLocalObject:(PDLocalPhotoObject *)localPhotoObject toWebAlbumID:(NSString *)webAlbumID backgroundSession:(NSURLSession *)backgroundSession completion:(void (^)(NSError *error))completion {
    _photoObject = localPhotoObject;
    
    NSString *filePath = [PDTask makeUniquePathInTmpDir];
    localPhotoObject.prepared_body_filepath = filePath;
    
    __weak typeof(self) wself = self;
    [self makeUploadTaskFromLocalObject:localPhotoObject toWebAlbumID:webAlbumID backgroundSession:backgroundSession filePath:filePath completion:^(NSURLSessionUploadTask *task, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.sessionTask = task;
        sself.identifier = task.taskIdentifier;
        
        if (completion) {
            completion(error);
        }
    }];
}

- (void)setDownloadTaskFromWebObject:(PDWebPhotoObject *)webPhotoObject backgroundSession:(NSURLSession *)backgroundSession completion:(void (^)(NSURLSessionDownloadTask *task, NSError *error))completion {
    _photoObject = webPhotoObject;
    
    __block PWPhotoObject *photo = nil;
    [PWCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", webPhotoObject.photo_object_id_str];
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count == 0) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:kPDTaskErrorDomain code:0 userInfo:nil]);
            }
            return;
        }
        photo = photos.firstObject;
    }];
    
    NSURL *requestUrl = [NSURL URLWithString:photo.tag_screenimage_url];
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:requestUrl completion:^(NSMutableURLRequest *request, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        dispatch_async(pd_task_queue(), ^{
            NSURLSessionDownloadTask *task = [backgroundSession downloadTaskWithRequest:request];
            sself.sessionTask = task;
            sself.identifier = task.taskIdentifier;
            
            if (completion) {
                completion(task, nil);
            }
        });
    }];
}

- (void)makeUploadTaskFromLocalObject:(PDLocalPhotoObject *)localPhotoObject toWebAlbumID:(NSString *)webAlbumID backgroundSession:(NSURLSession *)backgroundSession filePath:(NSString *)filePath completion:(void (^)(NSURLSessionUploadTask *task, NSError *error))completion {
    
    __block NSString *assetUrlString = nil;
    [PLCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", localPhotoObject.photo_object_id_str];
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count == 0) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:kPDTaskErrorDomain code:0 userInfo:nil]);
            }
            return;
        }
        PLPhotoObject *photo = photos.firstObject;
        assetUrlString = photo.url;
    }];
    
    NSString *requestUrlString = [NSString stringWithFormat:@"https://picasaweb.google.com/data/feed/api/user/default/albumid/%@", webAlbumID];
    NSURL *requestUrl = [NSURL URLWithString:requestUrlString];
    
    [PLAssetsManager assetForURL:[NSURL URLWithString:assetUrlString] resultBlock:^(ALAsset *asset) {
        if (!asset) {
            if (completion) {
                  completion(nil, [NSError errorWithDomain:kPDTaskErrorDomain code:0 userInfo:nil]);
            }
            return;
        }
        
        NSString *type = [asset valueForProperty:ALAssetPropertyType];
        if ([type isEqualToString:ALAssetTypePhoto]) {
            
            [PWPicasaAPI getAuthorizedURLRequest:requestUrl completion:^(NSMutableURLRequest *request, NSError *error) {
                if (error) {
                    if (completion) {
                        completion(nil, error);
                    }
                    return;
                }
                
                dispatch_async(pd_task_queue(), ^{
                    request.HTTPMethod = @"POST";
                    [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
                    
                    NSData *imageData = [PDTask resizedDataFromAsset:asset];
                    NSError *error = nil;
                    [imageData writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error];
                    if (error) {
                        if (completion) {
                            completion(nil, [NSError errorWithDomain:kPDTaskErrorDomain code:0 userInfo:nil]);
                        }
                        return;
                    }
                    
                    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)imageData.length] forHTTPHeaderField:@"Content-Length"];
                    
                    NSURLSessionUploadTask *task = [backgroundSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
                    
                    if (completion) {
                        completion(task, nil);
                    }
                });
            }];
        }
        else if ([type isEqualToString:ALAssetTypeVideo]) {
            
            NSString *tmpFilePath = [PDTask makeUniquePathInTmpDir];
            
            AVAsset *urlAsset = [AVURLAsset URLAssetWithURL:asset.defaultRepresentation.url options:nil];
            AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPreset640x480];
            exportSession.outputFileType = AVFileTypeMPEG4;
            exportSession.shouldOptimizeForNetworkUse = YES;
            exportSession.outputURL = [NSURL fileURLWithPath:tmpFilePath];
            __weak typeof(exportSession) wExportSession = exportSession;
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                typeof(wExportSession) sExportSession = wExportSession;
                if (!sExportSession) return;
                
                if (sExportSession.status != AVAssetExportSessionStatusCompleted){
                    if (completion) {
                        completion(nil, sExportSession.error);
                    }
                    return;
                }
                
                [PWPicasaAPI getAuthorizedURLRequest:requestUrl completion:^(NSMutableURLRequest *request, NSError *error) {
                    if (error) {
                        if (completion) {
                            completion(nil, error);
                        }
                        return;
                    }
                    
                    dispatch_async(pd_task_queue(), ^{
                        request.HTTPMethod = @"POST";
                        [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:@"Content-Type"];
                        [request addValue:@"1.0" forHTTPHeaderField:@"MIME-version"];
                        
                        NSMutableData *body = [NSMutableData data];
                        
                        NSMutableString *bodyString = [NSMutableString string];
                        [bodyString appendString:@"Media multipart posting"];
                        [bodyString appendString:@"\n--END_OF_PART\n"];
                        [body appendData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        NSMutableString *firstHeaderString = [NSMutableString string];
                        [firstHeaderString appendString:@"Content-Type: application/atom+xml"];
                        [firstHeaderString appendString:@"\n\n"];
                        [body appendData:[firstHeaderString dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        NSMutableString *firstBodyString = [NSMutableString string];
                        [firstBodyString appendString:@"<entry xmlns='http://www.w3.org/2005/Atom'>"];
                        [firstBodyString appendString:@"<title>fromiOS.mp4</title>"];
                        [firstBodyString appendString:@"<summary>Real cat wants attention too.</summary>"];
                        [firstBodyString appendString:@"<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#photo'/>"];
                        [firstBodyString appendString:@"</entry>"];
                        [firstBodyString appendString:@"\n--END_OF_PART\n"];
                        [body appendData:[firstBodyString dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        NSMutableString *secondHeaderString = [NSMutableString string];
                        [secondHeaderString appendString:@"Content-Type: video/mp4"];
                        [secondHeaderString appendString:@"\n\n"];
                        [body appendData:[secondHeaderString dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        NSData *data = [NSData dataWithContentsOfFile:tmpFilePath];
                        if (!data) {
                            if (completion) {
                                completion(nil, [NSError errorWithDomain:kPDTaskErrorDomain code:0 userInfo:nil]);
                            }
                            return;
                        }
                        [body appendData:data];
                        
                        NSMutableString *secondFooterString = [NSMutableString string];
                        [secondFooterString appendString:@"\n--END_OF_PART--\n"];
                        [body appendData:[secondFooterString dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        [body writeToFile:filePath atomically:YES];
                        [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:nil];
                        
                        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)body.length] forHTTPHeaderField:@"Content-Length"];
                        
                        NSURLSessionUploadTask *task = [backgroundSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
                        
                        if (completion) {
                            completion(task, nil);
                        }
                    });
                }];
            }];
        }
    } failureBlock:^(NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (NSData *)resizedDataFromAsset:(ALAsset *)asset {
    
    NSMutableData *resizedData = nil;
    
    @autoreleasepool {
        ALAssetRepresentation *representation = asset.defaultRepresentation;
        
        NSUInteger size = (NSUInteger)representation.size;
        uint8_t *buff = (uint8_t *)malloc(sizeof(uint8_t)*size);
        if(buff == nil){
            return nil;
        }
        
        
        NSError *error = nil;
        NSUInteger bytesRead = [representation getBytes:buff fromOffset:0 length:size error:&error];
        if (bytesRead && !error) {
            NSData *photoData = [NSData dataWithBytesNoCopy:buff length:bytesRead freeWhenDone:YES];
            
            //metadataの取得
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)photoData, nil);
            NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
            
            //リサイズ
            CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)@{(NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES, (NSString *)kCGImageSourceThumbnailMaxPixelSize: @(2048)});
            CFRelease(imageSource);
            
            //metadataの埋め込み
            resizedData = [[NSMutableData alloc] init];
            CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)resizedData, kUTTypeJPEG, 1, nil);
            CGImageDestinationAddImage(dest, imageRef, (__bridge CFDictionaryRef)metadata);
            CFRelease(imageRef);
            CGImageDestinationFinalize(dest);
            CFRelease(dest);
        }
        if (error) {
            NSLog(@"error:%@", error);
            free(buff);
        }
    }
    
    return resizedData;
}

+ (NSString *)makeUniquePathInTmpDir {
    NSString *homeDirectory = [NSString stringWithString:NSHomeDirectory()];
    NSString *tmpDirectory = [homeDirectory stringByAppendingPathComponent:@"/tmp"];
    NSString *filePath = [tmpDirectory stringByAppendingFormat:@"/%@", [PWSnowFlake generateUniqueIDString]];
    
    return filePath;
}

@end
