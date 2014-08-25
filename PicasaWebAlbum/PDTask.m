//
//  PWTask.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTask.h"

#import "PDModelObject.h"
#import "PDCoreDataAPI.h"
#import "PDTaskManager.h"
#import "PLCoreDataAPI.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"
#import "PWSnowFlake.h"
#import "PWPicasaAPI.h"

@interface PDTask ()

@end

@implementation PDTask

static NSString * const kPDTaskErrorDomain = @"PDTaskErrorDomain";

- (id)initWithTaskObject:(PDTaskObject *)taskObject {
    self = [super init];
    if (self) {
    }
    return self;
}


@end
