//
//  PWNetworkActivityIndicator.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PANetworkActivityIndicator.h"

@implementation PANetworkActivityIndicator

+ (PANetworkActivityIndicator *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = self.new;
    });
    return instance;
}

- (void)setNumberOfConnection:(NSUInteger)numberOfConnection {
    _numberOfConnection = numberOfConnection;
    
    void (^block)() = ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = (numberOfConnection > 0);
    };
    
    if ([NSThread isMainThread]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
    }
    else {
        block();
    }
}

+ (void)increment {
    [PANetworkActivityIndicator sharedManager].numberOfConnection++;
}

+ (void)decrement {
    [PANetworkActivityIndicator sharedManager].numberOfConnection--;
}

+ (NSUInteger)numberOfConnection {
    return [[PANetworkActivityIndicator sharedManager] numberOfConnection];
}

@end
