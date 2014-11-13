//
//  PDTaskManager.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

#import "PDModelObject.h"

@class PLAlbumObject, PWAlbumObject;

static NSString * const kPDTaskManagerIsResizePhotosKey = @"kPDTMIRPK";

@interface PDTaskManager : NSObject

// Default Time Interval is 100 sec.
@property (nonatomic) NSUInteger restartTimeInterval;

- (void)addTaskFromWebAlbum:(PWAlbumObject *)fromWebAlbum toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;
- (void)addTaskFromAssetCollection:(PHAssetCollection *)assetCollection toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *))completion;
- (void)addTaskPhotos:(NSArray *)photos toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;
- (void)addTaskPhotos:(NSArray *)photos toAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(NSError *error))completion;

#pragma mark Deprecated
- (void)addTaskFromLocalAlbum:(PLAlbumObject *)fromLocalAlbum toWebAlbum:(PWAlbumObject *)toWebAlbum completion:(void (^)(NSError *error))completion;
- (void)addTaskPhotos:(NSArray *)photos toLocalAlbum:(PLAlbumObject *)toLocalAlbum completion:(void (^)(NSError *error))completion;


+ (PDTaskManager *)sharedManager;

- (void)countOfAllPhotosInTaskWithCompletion:(void (^)(NSUInteger count, NSError *error))completion;

- (void)getRequestingTasksWithCompletion:(void (^)(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks))completion;

- (void)start;
- (void)stop;
- (void)cancel;


@property (copy, nonatomic) void (^taskManagerChangedBlock)(PDTaskManager *taskManager);

@property (copy, nonatomic) void (^backgroundComplecationHandler)();

@property (copy, nonatomic) void (^notLoginGoogleAccountAction)();
@property (copy, nonatomic) void (^notAllowedAccessPhotoLibraryAction)();

@end
