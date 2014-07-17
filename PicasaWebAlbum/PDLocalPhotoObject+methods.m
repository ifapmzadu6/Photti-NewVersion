//
//  PDLocalPhotoObject+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/16.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import AVFoundation;
@import ImageIO;
@import MobileCoreServices;

#import "PDLocalPhotoObject+methods.h"

#import "PDCoreDataAPI.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PWSnowFlake.h"
#import "PDModelObject.h"
#import "PWPicasaAPI.h"

@implementation PDLocalPhotoObject (methods)

- (void)setUploadTaskToWebAlbumID:(NSString *)webAlbumID completion:(void(^)(NSError *error))completion {
    
    __block NSString *assetUrlString = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", self.photo_object_id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *photos = [context executeFetchRequest:request error:&error];
        if (photos.count > 0) {
            PLPhotoObject *photo = photos.firstObject;
            assetUrlString = photo.url;
        }
    }];
    if (!assetUrlString) {
        if (completion) {
            completion([NSError errorWithDomain:@"PDLocalPhotoObject (methods)" code:0 userInfo:nil]);
        }
        return;
    }
    
    NSString *filePath = [[self class] makeUniquePathInTmpDir];
    self.prepared_body_filepath = filePath;
    [[PLAssetsManager sharedLibrary] assetForURL:[NSURL URLWithString:assetUrlString] resultBlock:^(ALAsset *asset) {
        if (!asset) {
            if (completion) {
                completion([NSError errorWithDomain:@"PDLocalPhotoObject (methods)" code:0 userInfo:nil]);
            }
            return;
        }
        
        NSString *type = [asset valueForProperty:ALAssetPropertyType];
        if ([type isEqualToString:ALAssetTypePhoto]) {
            NSData *imageData = [[self class] resizedDataFromAsset:asset];
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
                        completion([NSError errorWithDomain:@"PDLocalPhotoObject (methods)" code:0 userInfo:nil]);
                    }
                    return;
                }
                [body appendData:data];
                
                NSMutableString *secondFooterString = [NSMutableString string];
                [secondFooterString appendString:@"\n--END_OF_PART--\n"];
                [body appendData:[secondFooterString dataUsingEncoding:NSUTF8StringEncoding]];
                
                NSError *error = nil;
                [body writeToFile:filePath options:(NSDataWritingAtomic | NSDataWritingFileProtectionNone) error:&error];
                if (error) {
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

- (NSURLSessionTask *)makeSessionTaskWithSession:(NSURLSession *)session {
    PDTaskObject *taskObject = self.task;
    NSString *webAlbumID = taskObject.to_album_id_str;
    if (!webAlbumID) return nil;
    
    NSString *requestUrlString = [NSString stringWithFormat:@"https://picasaweb.google.com/data/feed/api/user/default/albumid/%@", webAlbumID];
    NSURL *url = [NSURL URLWithString:requestUrlString];
    
    __block PLPhotoObject *photoObject = nil;
    [PLCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPLPhotoObjectName inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", self.photo_object_id_str];
        request.fetchLimit = 1;
        NSError *error = nil;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (albums.count > 0) {
            photoObject = albums.firstObject;
        }
    }];
    if (!photoObject) return nil;
    if ([photoObject.type isEqualToString:ALAssetTypePhoto]) {
        __block NSURLSessionTask *sessionTask = nil;
        [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
            request.HTTPMethod = @"POST";
            [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
            NSString *filePath = self.prepared_body_filepath;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)fileAttributes[NSFileSize]] forHTTPHeaderField:@"Content-Length"];
            sessionTask = [session uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
        }];
        
        return sessionTask;
    }
    else if ([photoObject.type isEqualToString:ALAssetTypeVideo]) {
        __block NSURLSessionTask *sessionTask = nil;
        [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
            request.HTTPMethod = @"POST";
            [request addValue:@"multipart/related; boundary=\"END_OF_PART\"" forHTTPHeaderField:@"Content-Type"];
            [request addValue:@"1.0" forHTTPHeaderField:@"MIME-version"];
            NSString *filePath = self.prepared_body_filepath;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)fileAttributes[NSFileSize]] forHTTPHeaderField:@"Content-Length"];
            sessionTask = [session uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath]];
        }];
        
        return sessionTask;
    }
    return nil;
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
