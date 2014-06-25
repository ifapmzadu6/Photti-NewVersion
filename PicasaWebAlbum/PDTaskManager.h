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

static NSString * const kPDTaskManagerIsResizePhotosKey = @"kPDTMIRPK";

@interface PDTaskManager : NSObject <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

+ (PDTaskManager *)sharedManager;

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;

- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;

- (void)addTaskFromLocalPhotos:(NSArray *)fromLocalPhotos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;

- (void)addTaskFromWebPhotos:(NSArray *)fromWebPhotos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;

- (void)countOfAllPhotosInTaskWithCompletion:(void (^)(NSUInteger count, NSError *error))completion;

- (void)getRequestingTasksWithCompletion:(void (^)(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks))completion;

- (void)start;
- (void)stop;
- (void)cancel;


@property (copy, nonatomic) void (^taskManagerChangedBlock)(PDTaskManager *taskManager);

@property (copy, nonatomic) void (^backgroundComplecationHandler)();

@property (copy, nonatomic) void (^notPurchasedUploadDownloadAction)();


@end
