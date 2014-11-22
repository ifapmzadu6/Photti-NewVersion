//
//  PDLocalPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import AVFoundation;
@import Photos;

#define NtN(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#import "PDLocalPhotoObject+methods.h"

#import "PAKit.h"
#import "PAImageResize.h"
#import "PDCoreDataAPI.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PASnowFlake.h"
#import "PADateFormatter.h"
#import "PADateTimestamp.h"
#import "PDModelObject.h"
#import "PWPicasaAPI.h"
#import "PWPicasaParser.h"
#import "XmlReader.h"
#import "PWPicasaPOSTRequest.h"
#import "ALAsset+methods.h"
#import "NSURLResponse+methods.h"
#import "NSFileManager+methods.h"
#import "PDTaskManager.h"
#import "HTTPDefine.h"
#import "PAPhotoKit.h"

static NSString * const kPDLocalPhotoObjectMethodsErrorDomain = @"com.photti.PDLocalPhotoObjectMethods";
static NSString * const kPDLocalPhotoObjectPostURL = @"https://picasaweb.google.com/data/feed/api/user/default/albumid";
static NSString * const kPDLocalPHotoObjectPostNewAlbumURL = @"https://picasaweb.google.com/data/feed/api/user/default";

@implementation PDLocalPhotoObject (methods)

- (void)setUploadTaskToWebAlbumID:(NSString *)webAlbumID completion:(void (^)(NSError *))completion {
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        [self newSetUploadTaskToWebAlbumID:webAlbumID completion:completion];
    }
    else {
        [self oldSetUploadTaskToWebAlbumID:webAlbumID completion:completion];
    }
}

- (void)newSetUploadTaskToWebAlbumID:(NSString *)webAlbumID completion:(void(^)(NSError *error))completion {
    PHAsset *asset = [PAPhotoKit getAssetWithIdentifier:self.photo_object_id_str];
    if (!asset) {
        completion ? completion([NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSString *title = [[PADateFormatter fullStringFormatter] stringFromDate:asset.creationDate];
    NSString *filePath = [PAKit makeUniquePathInTmpDir];
    NSManagedObjectID *selfObjectID = self.objectID;
    if (asset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            NSError *error = nil;
            
            NSData *resizedData = nil;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
                resizedData = [PAImageResize resizedDataWithImageData:imageData maxPixelSize:2048];
            }
            else {
                resizedData = [PAImageResize resizedDataWithImageData:imageData maxPixelSize:NSUIntegerMax];
            }
            
            [resizedData writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error];
            
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
                selfObject.prepared_body_filepath = filePath;
            }];
            
            completion ? completion(error) : 0;
        }];
    }
    else if (asset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        NSString *exportPreset = nil;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
            exportPreset = AVAssetExportPreset640x480;
        }
        else {
            exportPreset = AVAssetExportPreset1280x720;
        }
        [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:options exportPreset:exportPreset resultHandler:^(AVAssetExportSession *exportSession, NSDictionary *info) {
            [PDLocalPhotoObject expotrtVideo:exportSession title:title filePath:filePath completion:^(NSError *error) {
                if (error) {
                    completion ? completion(error) : 0;
                    return;
                }
                [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                    PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
                    selfObject.prepared_body_filepath = filePath;
                }];
                
                completion ? completion(nil) : 0;
            }];
        }];
    }
}

- (void)oldSetUploadTaskToWebAlbumID:(NSString *)webAlbumID completion:(void(^)(NSError *error))completion {
    PLPhotoObject *photoObject = [PLPhotoObject getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion([NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSString *assetUrlString = photoObject.url;
    NSString *title = photoObject.filename;
    NSString *filePath = [PAKit makeUniquePathInTmpDir];
    NSManagedObjectID *selfObjectID = self.objectID;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
        selfObject.prepared_body_filepath = filePath;
    }];
    [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:assetUrlString] resultBlock:^(ALAsset *asset) {
        if (!asset) {
            completion ? completion([NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        NSString *type = [asset valueForProperty:ALAssetPropertyType];
        if ([type isEqualToString:ALAssetTypePhoto]) {
            NSData *imageData = nil;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
                imageData = [asset resizedDataWithMaxPixelSize:2048];
            }
            else {
                imageData = [asset resizedDataWithMaxPixelSize:NSUIntegerMax];
            }
            NSError *error = nil;
            [imageData writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error];
            
            completion ? completion(error) : 0;
        }
        else if ([type isEqualToString:ALAssetTypeVideo]) {
            AVAsset *urlAsset = [AVURLAsset URLAssetWithURL:asset.defaultRepresentation.url options:nil];
            AVAssetExportSession *exportSession = nil;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
                exportSession = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPreset640x480];
            }
            else {
                exportSession = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPreset1280x720];
            }
            [PDLocalPhotoObject expotrtVideo:exportSession title:title filePath:filePath completion:completion];
        }
    } failureBlock:^(NSError *error) {
        completion ? completion(error) : 0;
    }];
}

+ (void)expotrtVideo:(AVAssetExportSession *)exportSession title:(NSString *)title filePath:(NSString *)filePath completion:(void (^)(NSError *))completion {
    NSString *tmpFilePath = [PAKit makeUniquePathInTmpDir];
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputURL = [NSURL fileURLWithPath:tmpFilePath];
    __weak typeof(exportSession) wExportSession = exportSession;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        typeof(wExportSession) sExportSession = wExportSession;
        if (!sExportSession) return;
        if (sExportSession.status != AVAssetExportSessionStatusCompleted){
            completion ? completion(sExportSession.error) : 0;
            return;
        }
        
        NSData *body = [PDLocalPhotoObject makeBodyFromFilePath:tmpFilePath title:title];
        if (!body) {
            completion ? completion([NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        NSError *error = nil;
        if (![body writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error]) {
            completion ? completion(error) : 0;
            return;
        }
        [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:&error];
        
        completion ? completion(error) : 0;
    }];
}

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        [self newMakeSessionTaskWithSession:session completion:completion];
    }
    else {
        [self oldMakeSessionTaskWithSession:session completion:completion];
    }
}

- (void)newMakeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    NSString *webAlbumID = self.task.to_album_id_str;
    if (!webAlbumID) {
        [self makeNewAlbumSessionTaskWithSession:session completion:completion];
        return;
    };
    NSString *requestUrlString = [NSString stringWithFormat:@"%@/%@", kPDLocalPhotoObjectPostURL, webAlbumID];
    
    PHAsset *asset = [PAPhotoKit getAssetWithIdentifier:self.photo_object_id_str];
    if (!asset) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    BOOL isVideo = (asset.mediaType == PHAssetMediaTypeVideo) ? YES : NO;
    NSString *filePath = self.prepared_body_filepath;
    if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        __weak typeof(self) wself = self;
        [self setUploadTaskToWebAlbumID:webAlbumID completion:^(NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself makeSessionTaskWithSession:session completion:completion];
        }];
        return;
    }
    [NSFileManager cancelProtect:filePath];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSUInteger bodySize = [fileAttributes[NSFileSize] unsignedLongValue];
    
    NSManagedObjectID *selfObjectID = self.objectID;
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:requestUrlString] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        NSURLSessionTask *sessionTask = [PDLocalPhotoObject getSessionTaskWithRequest:request session:session filePath:filePath bodySize:bodySize isVideo:isVideo];
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
            selfObject.session_task_identifier = @(sessionTask.taskIdentifier);
        }];
        
        completion ? completion(sessionTask, nil) : 0;
    }];
}

- (void)oldMakeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    NSString *webAlbumID = self.task.to_album_id_str;
    if (!webAlbumID) {
        [self makeNewAlbumSessionTaskWithSession:session completion:completion];
        return;
    };
    NSString *requestUrlString = [NSString stringWithFormat:@"%@/%@", kPDLocalPhotoObjectPostURL, webAlbumID];
    
    PLPhotoObject *photoObject = [PLPhotoObject getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    BOOL isVideo = [photoObject.type isEqualToString:ALAssetTypeVideo];
    NSString *filePath = self.prepared_body_filepath;
    if (!filePath) {
        __weak typeof(self) wself = self;
        [self setUploadTaskToWebAlbumID:webAlbumID completion:^(NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself makeSessionTaskWithSession:session completion:completion];
        }];
        return;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    [NSFileManager cancelProtect:filePath];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSUInteger bodySize = [fileAttributes[NSFileSize] unsignedLongValue];
    
    NSManagedObjectID *selfObjectID = self.objectID;
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:requestUrlString] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        NSURLSessionTask *sessionTask = [PDLocalPhotoObject getSessionTaskWithRequest:request session:session filePath:filePath bodySize:bodySize isVideo:isVideo];
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
            selfObject.session_task_identifier = @(sessionTask.taskIdentifier);
        }];
        
        completion ? completion(sessionTask, nil) : 0;
    }];
}

+ (NSURLSessionTask *)getSessionTaskWithRequest:(NSMutableURLRequest *)request session:(NSURLSession *)session filePath:(NSString *)filePath bodySize:(NSUInteger)bodySize isVideo:(BOOL)isVideo {
    request.HTTPMethod = @"POST";
    if (isVideo) {
        [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:kHTTPHeaderFieldContentType];
        [request addValue:@"1.0" forHTTPHeaderField:kHTTPHeaderFieldMIMEVersion];
    }
    else {
        [request addValue:kPWPhotoObjectContentType_jpeg forHTTPHeaderField:kHTTPHeaderFieldContentType];
    }
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)bodySize] forHTTPHeaderField:kHTTPHeaderFieldContentLength];
    
    NSURLSessionTask *sessionTask = [session uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
    return sessionTask;
}

- (void)makeNewAlbumSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    __block NSString *from_album_id_str = nil;
    NSManagedObjectID *selfObjectID = self.objectID;
    [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
        from_album_id_str = selfObject.task.from_album_id_str;
    }];
    if (!from_album_id_str) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    }
    
    NSString *title = nil;
    NSString *timestamp = nil;
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        PHAssetCollection *assetCollection = [PAPhotoKit getAssetCollectionWithIdentifier:from_album_id_str];
        title = [PAPhotoKit titleForMoment:assetCollection];
        timestamp = [PADateTimestamp timestampForDate:assetCollection.startDate];
    }
    else {
        PLAlbumObject *albumObject = [PLAlbumObject getAlbumObjectWithID:from_album_id_str];
        if (!albumObject) {
            completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
            return;
        };
        title = albumObject.name;
        timestamp = albumObject.timestamp.stringValue;
    }
    
    NSURL *url = [NSURL URLWithString:kPDLocalPHotoObjectPostNewAlbumURL];
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        
        NSString *body = [PWPicasaPOSTRequest makeBodyWithGPhotoID:nil Title:title summary:nil location:nil access:nil timestamp:timestamp keywords:nil];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        NSString *filePath = [PAKit makeUniquePathInTmpDir];
        if (![bodyData writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error]) {
            completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        
        request.HTTPMethod = @"POST";
        [request addValue:kHTTPHeaderFieldContentTypeValue_AtomXml forHTTPHeaderField:kHTTPHeaderFieldContentType];
        [request addValue:[NSString stringWithFormat:@"%ld", (long)bodyData.length] forHTTPHeaderField:kHTTPHeaderFieldContentLength];
        NSURLSessionTask *sessionTask = [session uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
            selfObject.session_task_identifier = @(sessionTask.taskIdentifier);
        }];
        
        completion ? completion(sessionTask, nil) : 0;
    }];
}

- (void)finishMakeNewAlbumSessionWithResponse:(NSURLResponse *)response data:(NSData *)data {
    if (!response.isSuccess) {
#ifdef DEBUG
        NSLog(@"%@", response);
#endif
        return;
    }
    
    NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
    
    id entries = NtN(json[@"entry"]);
    if (!entries) {
#ifdef DEBUG
        NSLog(@"Parser Error");
        NSLog(@"%s", __func__);
#endif
        return;
    };
    
    __block NSString *to_web_album_id_str = nil;
    [PWCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PWAlbumObject *album = [PWPicasaParser albumFromJson:entries existingAlbums:nil context:context];
        to_web_album_id_str = album.id_str;
    }];
    
    if (to_web_album_id_str) {
        NSManagedObjectID *selfObjectID = self.objectID;
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
            PDTaskObject *taskObject = selfObject.task;
            taskObject.to_album_id_str = to_web_album_id_str;
        }];
    }
}


#pragma mark methods
+ (NSData *)makeBodyFromFilePath:(NSString *)filepath title:(NSString *)title {
    NSMutableData *body = [NSMutableData data];
    
    NSMutableString *bodyString = [NSMutableString string];
    [bodyString appendString:@"Media multipart posting"];
    [bodyString appendString:@"\n--END_OF_PART\n"];
    [body appendData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableString *firstHeaderString = [NSMutableString string];
    [firstHeaderString appendString:[NSString stringWithFormat:@"%@: %@", kHTTPHeaderFieldContentType, kHTTPHeaderFieldContentTypeValue_AtomXml]];
    [firstHeaderString appendString:@"\n\n"];
    [body appendData:[firstHeaderString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableString *firstBodyString = [NSMutableString string];
    [firstBodyString appendString:@"<entry xmlns='http://www.w3.org/2005/Atom'>"];
    [firstBodyString appendFormat:@"<title>%@</title>", title];
    [firstBodyString appendString:@"<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#photo'/>"];
    [firstBodyString appendString:@"</entry>"];
    [firstBodyString appendString:@"\n--END_OF_PART\n"];
    [body appendData:[firstBodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableString *secondHeaderString = [NSMutableString string];
    [secondHeaderString appendString:[NSString stringWithFormat:@"%@: %@", kHTTPHeaderFieldContentType, kPWPhotoObjectContentType_mp4]];
    [secondHeaderString appendString:@"\n\n"];
    [body appendData:[secondHeaderString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    if (!data) {
        return nil;
    }
    [body appendData:data];
    
    NSMutableString *secondFooterString = [NSMutableString string];
    [secondFooterString appendString:@"\n--END_OF_PART--\n"];
    [body appendData:[secondFooterString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return body;
}

@end
