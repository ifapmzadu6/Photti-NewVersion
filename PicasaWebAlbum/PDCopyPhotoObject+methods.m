//
//  PDCopyPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDCopyPhotoObject+methods.h"

#import "PAKit.h"
#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PWCoreDataAPI.h"
#import "PWModelObject.h"
#import "PASnowFlake.h"
#import "HTTPDefine.h"
#import "NSFileManager+methods.h"

static NSString * const kPDCopyPhotoObjectMethodsErrorDomain = @"com.photti.PDCopyPhotoObjectMethods";
static NSString * const kPDCopyPhotoObjectPostURL = @"https://picasaweb.google.com/data/feed/api/user/default/albumid";

@implementation PDCopyPhotoObject (methods)

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    NSString *filePath = self.downloaded_data_location;
    NSManagedObjectID *selfObjectID = self.objectID;
    if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self makeUploadSessionTaskWithSession:session completion:^(NSURLSessionTask *task, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDCopyPhotoObject *selfObject = (PDCopyPhotoObject *)[context objectWithID:selfObjectID];
                selfObject.session_task_identifier = @(task.taskIdentifier);
            }];
            
            completion ? completion(task, error) : 0;
        }];
    }
    else {
        [self makeDownloadSessionTaskWithSession:session completion:^(NSURLSessionTask *task, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                PDCopyPhotoObject *selfObject = (PDCopyPhotoObject *)[context objectWithID:selfObjectID];
                selfObject.session_task_identifier = @(task.taskIdentifier);
            }];
            
            completion ? completion(task, error) : 0;
        }];
    }
}

- (void)makeDownloadSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    PWPhotoObject *photoObject = [PWPhotoObject getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDCopyPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSURL *url = [NSURL URLWithString:photoObject.tag_originalimage_url];
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        
        NSURLSessionTask *task = [session downloadTaskWithRequest:request];
        
        completion ? completion(task, nil) : 0;
    }];
    
};

- (void)makeUploadSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    PDTaskObject *taskObject = self.task;
    NSString *webAlbumID = taskObject.to_album_id_str;
    if (!webAlbumID) {
        completion ? completion(nil, [NSError errorWithDomain:kPDCopyPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    PWPhotoObject *photoObject = [PWPhotoObject getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDCopyPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSString *filePath = self.downloaded_data_location;
    NSString *requestUrlString = [NSString stringWithFormat:@"%@/%@", kPDCopyPhotoObjectPostURL, webAlbumID];
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:requestUrlString] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        
        request.HTTPMethod = @"POST";
        [NSFileManager cancelProtect:filePath];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if (photoObject.tag_type.integerValue == kPWPhotoObjectTypePhoto) {
            [request addValue:kPWPhotoObjectContentType_jpeg forHTTPHeaderField:kHTTPHeaderFieldContentType];
        }
        else if (photoObject.tag_type.integerValue == kPWPhotoObjectTypeVideo) {
            [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:kHTTPHeaderFieldContentType];
            [request addValue:@"1.0" forHTTPHeaderField:kHTTPHeaderFieldMIMEVersion];
        }
        [request addValue:[NSString stringWithFormat:@"%lu", [fileAttributes[NSFileSize] unsignedLongValue]] forHTTPHeaderField:kHTTPHeaderFieldContentLength];
        NSURL *filePathURL = [NSURL fileURLWithPath:filePath];
        NSURLSessionTask *sessionTask = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            sessionTask = [session uploadTaskWithRequest:request fromFile:filePathURL];
            
            completion ? completion(sessionTask, nil) : 0;
        }
        else {
            
            completion ? completion(nil, [NSError errorWithDomain:kPDCopyPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        }
    }];
}

- (void)finishDownloadWithLocation:(NSURL *)location {
    PWPhotoObject *photoObject = [PWPhotoObject getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) return;
    
    NSString *filePath = [PAKit makeUniquePathInTmpDir];
    NSURL *filePathURL = [NSURL fileURLWithPath:filePath];
    
    if (photoObject.tag_type.integerValue == kPWPhotoObjectTypePhoto) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:filePathURL error:&error]) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }
    }
    else if (photoObject.tag_type.integerValue == kPWPhotoObjectTypeVideo) {
        NSData *body = [PDCopyPhotoObject makeBodyFromFilePath:location.absoluteString title:photoObject.title];
        NSError *error = nil;
        if (![body writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error]) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }
    }
    [NSFileManager cancelProtect:filePath];
    NSManagedObjectID *selfObjectID = self.objectID;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDCopyPhotoObject *selfObject = (PDCopyPhotoObject *)[context objectWithID:selfObjectID];
        selfObject.downloaded_data_location = filePath;
    }];
}

- (void)finishUpload {
    NSManagedObjectID *selfObjectID = self.objectID;
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        PDCopyPhotoObject *selfObject = (PDCopyPhotoObject *)[context objectWithID:selfObjectID];
        selfObject.is_done = @YES;
    }];
}

#pragma mark Body
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
