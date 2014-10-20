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
#import "PDCoreDataAPI.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PASnowFlake.h"
#import "PADateFormatter.h"
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
    PHAsset *asset = [self getAssetWithIdentifier:self.photo_object_id_str];
    if (!asset) {
        completion ? completion([NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSString *title = [[PADateFormatter fullStringFormatter] stringFromDate:asset.creationDate];
    NSString *filePath = [PAKit makeUniquePathInTmpDir];
    if (asset.mediaType == PHAssetMediaTypeImage) {
        
    }
    else if (asset.mediaType == PHAssetMediaTypeVideo) {
        
    }
}

- (void)oldSetUploadTaskToWebAlbumID:(NSString *)webAlbumID completion:(void(^)(NSError *error))completion {
    PLPhotoObject *photoObject = [self getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion([NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSString *assetUrlString = photoObject.url;
    NSString *title = photoObject.filename;
    NSString *filePath = [PAKit makeUniquePathInTmpDir];
    self.prepared_body_filepath = filePath;
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
            NSString *tmpFilePath = [PAKit makeUniquePathInTmpDir];
            AVAsset *urlAsset = [AVURLAsset URLAssetWithURL:asset.defaultRepresentation.url options:nil];
            AVAssetExportSession *exportSession = nil;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
                exportSession = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPreset640x480];
            }
            else {
                exportSession = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPreset1280x720];
            }
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
    } failureBlock:^(NSError *error) {
        completion ? completion(error) : 0;
    }];
}

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    PDTaskObject *taskObject = self.task;
    NSString *webAlbumID = taskObject.to_album_id_str;
    if (!webAlbumID) {
        [self makeNewAlbumSessionTaskWithSession:session completion:completion];
        return;
    };
    
    NSString *requestUrlString = [NSString stringWithFormat:@"%@/%@", kPDLocalPhotoObjectPostURL, webAlbumID];
    
    PLPhotoObject *photoObject = [self getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSManagedObjectID *selfObjectID = self.objectID;
    void (^block)() = ^{
        __weak typeof(self) wself = self;
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:requestUrlString] completion:^(NSMutableURLRequest *request, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
                completion ? completion(nil, error) : 0;
                return;
            }
            
            request.HTTPMethod = @"POST";
            NSString *filePath = sself.prepared_body_filepath;
            if (!filePath) {
                completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
                return;
            }
            
            [NSFileManager cancelProtect:filePath];
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            if ([photoObject.type isEqualToString:ALAssetTypePhoto]) {
                [request addValue:kPWPhotoObjectContentType_jpeg forHTTPHeaderField:kHTTPHeaderFieldContentType];
            }
            else if ([photoObject.type isEqualToString:ALAssetTypeVideo]) {
                [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:kHTTPHeaderFieldContentType];
                [request addValue:@"1.0" forHTTPHeaderField:kHTTPHeaderFieldMIMEVersion];
            }
            [request addValue:[NSString stringWithFormat:@"%lu", [fileAttributes[NSFileSize] unsignedLongValue]] forHTTPHeaderField:kHTTPHeaderFieldContentLength];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
                return;
            }
            
            NSURLSessionTask *sessionTask = [session uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDLocalPhotoObject *selfObject = (PDLocalPhotoObject *)[context objectWithID:selfObjectID];
                selfObject.session_task_identifier = @(sessionTask.taskIdentifier);
            }];
            
            completion ? completion(sessionTask, nil) : 0;
        }];
    };
    
    NSString *filePath = self.prepared_body_filepath;
    if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self setUploadTaskToWebAlbumID:taskObject.to_album_id_str completion:^(NSError *error) {
            block();
        }];
    }
    else {
        block();
    }
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
    
    PLAlbumObject *albumObject = [self getAlbumObjectWithID:from_album_id_str];
    if (!albumObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSURL *url = [NSURL URLWithString:kPDLocalPHotoObjectPostNewAlbumURL];
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        
        NSString *body = [PWPicasaPOSTRequest makeBodyWithGPhotoID:nil Title:albumObject.name summary:nil location:nil access:nil timestamp:albumObject.timestamp.stringValue keywords:nil];
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

#pragma mark Photo
- (PHAsset *)getAssetWithIdentifier:(NSString *)identifier {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (fetchResult.count == 0) {
        fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[identifier] options:nil];
    }
    PHAsset *asset = fetchResult.firstObject;
    NSAssert(asset, nil);
    return asset;
}


#pragma mark Data
- (PLPhotoObject *)getPhotoObjectWithID:(NSString *)id_str {
    __block PLPhotoObject *photoObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:@"PLPhotoObject" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count > 0) {
            photoObject = objects.firstObject;
        }
    }];
    return photoObject;
}

- (PLAlbumObject *)getAlbumObjectWithID:(NSString *)id_str {
    __block PLAlbumObject *albumObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:@"PLAlbumObject" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects.count > 0) {
            albumObject = objects.firstObject;
        }
    }];
    return albumObject;
}

@end
