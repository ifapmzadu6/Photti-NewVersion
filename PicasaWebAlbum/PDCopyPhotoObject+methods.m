//
//  PDCopyPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDCopyPhotoObject+methods.h"

#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PWCoreDataAPI.h"
#import "PWModelObject.h"
#import "PWSnowFlake.h"
#import "PLAssetsManager.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"

static NSString * const kPDCopyPhotoObjectMethodsErrorDomain = @"com.photti.PDCopyPhotoObjectMethods";

@implementation PDCopyPhotoObject (methods)

- (void)makeSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    if (self.downloaded_data_location) {
        [self makeUploadSessionTaskWithSession:session completion:^(NSURLSessionTask *task, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                self.session_task_identifier = @(task.taskIdentifier);
            }];
            
            completion ? completion(task, error) : 0;
        }];
    }
    else {
        [self makeDownloadSessionTaskWithSession:session completion:^(NSURLSessionTask *task, NSError *error) {
            [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                self.session_task_identifier = @(task.taskIdentifier);
            }];
            
            completion ? completion(task, error) : 0;
        }];
    }
}

- (void)makeDownloadSessionTaskWithSession:(NSURLSession *)session completion:(void (^)(NSURLSessionTask *, NSError *))completion {
    PWPhotoObject *photoObject = [self getPhotoObjectWithID:self.photo_object_id_str];
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
    
    PWPhotoObject *photoObject = [self getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) {
        completion ? completion(nil, [NSError errorWithDomain:kPDCopyPhotoObjectMethodsErrorDomain code:0 userInfo:nil]) : 0;
        return;
    };
    
    NSString *requestUrlString = [NSString stringWithFormat:@"https://picasaweb.google.com/data/feed/api/user/default/albumid/%@", webAlbumID];
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:requestUrlString] completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            completion ? completion(nil, error) : 0;
            return;
        }
        
        request.HTTPMethod = @"POST";
        NSString *filePath = self.downloaded_data_location;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if (photoObject.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
            [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        }
        else if (photoObject.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
            [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:@"Content-Type"];
            [request addValue:@"1.0" forHTTPHeaderField:@"MIME-version"];
        }
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)fileAttributes[NSFileSize]] forHTTPHeaderField:@"Content-Length"];
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
    PWPhotoObject *photoObject = [self getPhotoObjectWithID:self.photo_object_id_str];
    if (!photoObject) return;
    
    NSString *filePath = [[self class] makeUniquePathInTmpDir];
    NSURL *filePathURL = [NSURL fileURLWithPath:filePath];
    
    if (photoObject.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:filePathURL error:&error]) {
            NSLog(@"%@", error);
        }
    }
    else if (photoObject.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
        NSData *body = [[self class] makeBodyFromFilePath:location.absoluteString title:photoObject.title];
        NSError *error = nil;
        if (![body writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error]) {
            NSLog(@"%@", error);
        }
    }
    
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        self.downloaded_data_location = filePath;
    }];
}

- (void)finishUpload {
    [PDCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
        self.is_done = @(YES);
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

#pragma mark Data
- (PWPhotoObject *)getPhotoObjectWithID:(NSString *)id_str {
    __block PWPhotoObject *photoObject = nil;
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count > 0) {
            photoObject = photos.firstObject;
        }
    }];
    return photoObject;
}

#pragma mark FilePath
+ (NSString *)makeUniquePathInTmpDir {
    NSString *homeDirectory = [NSString stringWithString:NSHomeDirectory()];
    NSString *tmpDirectory = [homeDirectory stringByAppendingPathComponent:@"/tmp"];
    NSString *filePath = [tmpDirectory stringByAppendingFormat:@"/%@", [PWSnowFlake generateUniqueIDString]];
    return filePath;
}


@end
