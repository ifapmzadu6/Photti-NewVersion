//
//  PWNetworkActivityIndicator.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWNetworkActivityIndicator.h"

@implementation PWNetworkActivityIndicator

+ (PWNetworkActivityIndicator *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = self.new;
    });
    return instance;
}

- (void)setNumberOfConnection:(NSUInteger)numberOfConnection {
    _numberOfConnection = numberOfConnection;
    
    NSLog(@"%ld", (long)numberOfConnection);
    
    void (^block)() = ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = (numberOfConnection > 0);
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (void)increment {
    [PWNetworkActivityIndicator sharedManager].numberOfConnection++;
}

+ (void)decrement {
    [PWNetworkActivityIndicator sharedManager].numberOfConnection--;
}

+ (NSUInteger)numberOfConnection {
    return [[PWNetworkActivityIndicator sharedManager] numberOfConnection];
}

@end
