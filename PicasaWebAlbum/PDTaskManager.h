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

+ (PDTaskManager *)sharedManager;

- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;

- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;

//- (void)addTaskFromLocalPhotos:(NSArray *)fromLocalPhotos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;

//- (void)addTaskFromWebPhotos:(NSArray *)from toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;

- (void)countOfAllPhotosInTaskWithCompletion:(void (^)(NSUInteger count, NSError *error))completion;

- (void)start;
- (void)stop;
- (void)cancel;


@property (strong, nonatomic) void (^taskManagerChangedBlock)(PDTaskManager *taskManager);

@property (strong, nonatomic) void (^backgroundComplecationHandler)();

@end

@interface PDTaskManagerDownloadedItem : NSObject

@property (nonatomic) NSUInteger sortIndex;
@property (strong, nonatomic) NSURL *location;
@property (strong, nonatomic) PDTask *task;

@end
