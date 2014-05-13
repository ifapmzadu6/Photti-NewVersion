//
//  PWAssetsLibrary.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAssetsLibrary.h"

@interface PWAssetsLibrary ()

@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;

@end

@implementation PWAssetsLibrary

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
