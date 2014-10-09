//
//  PWNetworkActivityIndicator.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PANetworkActivityIndicator.h"

@interface PANetworkActivityIndicator ()

@property (nonatomic) NSUInteger timeInterval;

@end

@implementation PANetworkActivityIndicator

+ (PANetworkActivityIndicator *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = self.new;
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _decrementTimeInterval = 180;
        
        [self countTimeInterval];
    }
    return self;
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
    [PANetworkActivityIndicator sharedManager].timeInterval = 0;
}

+ (void)decrement {
    [PANetworkActivityIndicator sharedManager].numberOfConnection--;
}

+ (NSUInteger)numberOfConnection {
    return [[PANetworkActivityIndicator sharedManager] numberOfConnection];
}

- (void)countTimeInterval {
    _timeInterval += 10;
    
    if (_timeInterval > _decrementTimeInterval) {
        _timeInterval = 0;
        
        if (_numberOfConnection > 0) {
            _numberOfConnection--;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self countTimeInterval];
    });
}

@end
