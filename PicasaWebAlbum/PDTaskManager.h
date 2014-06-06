//
//  PDTaskManager.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

#import "PDTask.h"
#import "PDModelObject.h"

@class PLAlbumObject, PWAlbumObject;

static NSString * const kPDBackgroundSessionIdentifier = @"kPDBSI";

@interface PDTaskManager : NSObject <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

+ (id)sharedManager;

+ (NSURLSession *)sharedSession;

+ (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;

+ (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;

+ (void)addTaskFromLocalPhotos:(NSArray *)fromLocalPhotos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;

+ (void)addTaskFromWebPhotos:(NSArray *)from toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;

+ (void)resumeAllTasks;

@end
