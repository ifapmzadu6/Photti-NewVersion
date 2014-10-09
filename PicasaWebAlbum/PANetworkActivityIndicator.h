//
//  PWNetworkActivityIndicator.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PANetworkActivityIndicator : NSObject

@property (nonatomic) NSUInteger decrementTimeInterval; // default: 3 minutes
@property (nonatomic) NSUInteger numberOfConnection;

+ (PANetworkActivityIndicator *)sharedManager;

+ (void)increment;
+ (void)decrement;
+ (NSUInteger)numberOfConnection;

@end
