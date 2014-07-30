//
//  PDLocalPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import AVFoundation;

#define NtN(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#import "PDLocalPhotoObject+methods.h"

#import "PDCoreDataAPI.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PWSnowFlake.h"
#import "PDModelObject.h"
#import "PWPicasaAPI.h"
#import "PWPicasaParser.h"
#import "XmlReader.h"
#import "PWPicasaPOSTRequest.h"
#import "ALAsset+methods.h"
#import "NSURLResponse+methods.h"

static NSString * const kPDLocalPhotoObjectMethodsErrorDomain = @"com.photti.PDLocalPhotoObjectMethods";

@implementation PDLocalPhotoObject (methods)

- (void)setUploadTaskToWebAlbumID:(NSString *)webAlbumID completion:(void(^)(NSError *error))completion {
    PLPhotoObject *photoObject = [self getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        if (completion) {
            completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
        }
        return;
    };
    
    NSString *assetUrlString = photoObject.url;
    NSString *title = photoObject.filename;
    NSString *filePath = [[self class] makeUniquePathInTmpDir];
    self.prepared_body_filepath = filePath;
    [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:assetUrlString] resultBlock:^(ALAsset *asset) {
        if (!asset) {
            if (completion) {
                completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
            }
            return;
        }
        
        NSString *type = [asset valueForProperty:ALAssetPropertyType];
        if ([type isEqualToString:ALAssetTypePhoto]) {
            NSData *imageData = [asset resizedDataWithMaxPixelSize:2048];
            NSError *error = nil;
            [imageData writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error];
            if (completion) {
                completion(error);
            }
        }
        else if ([type isEqualToString:ALAssetTypeVideo]) {
            NSString *tmpFilePath = [[self class] makeUniquePathInTmpDir];
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
                        completion(sExportSession.error);
                    }
                    return;
                }
                
                NSData *body = [[self class] makeBodyFromFilePath:tmpFilePath title:title];
                if (!body) {
                    if (completion) {
                        completion([NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:nil]);
                    }
                    return;
                }
                
                NSError *error = nil;
                if (![body writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error]) {
                    if (completion) {
                        completion(error);
                    }
                    return;
                }
                [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:&error];
                if (completion) {
                    completion(error);
                }
            }];
        }
    } failureBlock:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    PDTaskObject *taskObject = self.task;
    NSString *webAlbumID = taskObject.to_album_id_str;
    if (!webAlbumID) {
        [self makeNewAlbumSessionTaskWithSession:session completion:completion];
        return;
    };
    
    NSString *requestUrlString = [NSString stringWithFormat:@"https://picasaweb.google.com/data/feed/api/user/default/albumid/%@", webAlbumID];
    
    PLPhotoObject *photoObject = [self getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:requestUrlString] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        
        request.HTTPMethod = @"POST";
        NSString *filePath = self.prepared_body_filepath;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([photoObject.type isEqualToString:ALAssetTypePhoto]) {
            [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        }
        else if ([photoObject.type isEqualToString:ALAssetTypeVideo]) {
            [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:@"Content-Type"];
            [request addValue:@"1.0" forHTTPHeaderField:@"MIME-version"];
        }
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)fileAttributes[NSFileSize]] forHTTPHeaderField:@"Content-Length"];
        NSURLSessionTask *sessionTask = [session uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            self.session_task_identifier = @(sessionTask.taskIdentifier);
        }];
        
        completion ? completion(sessionTask, nil) : 0;
    }];
}

- (void)makeNewAlbumSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    __block NSString *from_album_id_str = nil;
    [PDCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        from_album_id_str = self.task.from_album_id_str;
    }];
    if (!from_album_id_str) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
    }
    
    PLAlbumObject *albumObject = [self getAlbumObjectWithID:from_album_id_str];
    if (!albumObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSString *postURL = @"https://picasaweb.google.com/data/feed/api/user/default";
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:postURL] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        
        NSString *body = [PWPicasaPOSTRequest makeBodyWithGPhotoID:nil Title:albumObject.name summary:nil location:nil access:nil timestamp:albumObject.timestamp.stringValue keywords:nil];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        NSString *filePath = [[self class] makeUniquePathInTmpDir];
        if (![bodyData writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error]) {
            completion ? completion(nil, [NSError errorWithDomain:kPDLocalPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        
        request.HTTPMethod = @"POST";
        [request addValue:@"application/atom+xml" forHTTPHeaderField:@"Content-Type"];
        [request addValue:[NSString stringWithFormat:@"%ld", (long)bodyData.length] forHTTPHeaderField:@"Content-Length"];
        NSURLSessionTask *sessionTask = [session uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
        
        [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            self.session_task_identifier = @(sessionTask.taskIdentifier);
        }];
        
        completion ? completion(sessionTask, nil) : 0;
    }];
}

- (void)finishMakeNewAlbumSessionWithResponse:(NSURLResponse *)response data:(NSData *)data {
    if (!response.isSuccess) {
        NSLog(@"%@", response.description);
        return;
    }
    
    NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
    //        NSLog(@"%@", json.description);
    
    id entries = NtN(json[@"entry"]);
    if (!entries) {
        NSLog(@"Parser Error");
        NSLog(@"%s", __func__);
        return;
    };
    
    __block NSString *to_web_album_id_str = nil;
    [PWCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PWAlbumObject *album = [PWPicasaParser albumFromJson:entries existingAlbums:nil context:context];
        to_web_album_id_str = album.id_str;
    }];
    
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDTaskObject *taskObject = self.task;
        taskObject.to_album_id_str = to_web_album_id_str;
    }];
}


#pragma mark methods
+ (NSData *)makeBodyFromFilePath:(NSString *)filepath title:(NSString *)title {
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
    [firstBodyString appendFormat:@"<title>%@</title>", title];
    [firstBodyString appendString:@"<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#photo'/>"];
    [firstBodyString appendString:@"</entry>"];
    [firstBodyString appendString:@"\n--END_OF_PART\n"];
    [body appendData:[firstBodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableString *secondHeaderString = [NSMutableString string];
    [secondHeaderString appendString:@"Content-Type: video/mp4"];
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

+ (NSString *)makeUniquePathInTmpDir {
    NSString *homeDirectory = [NSString stringWithString:NSHomeDirectory()];
    NSString *tmpDirectory = [homeDirectory stringByAppendingPathComponent:@"/tmp"];
    NSString *filePath = [tmpDirectory stringByAppendingFormat:@"/%@", [PWSnowFlake generateUniqueIDString]];
    return [filePath stringByStandardizingPath];
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
