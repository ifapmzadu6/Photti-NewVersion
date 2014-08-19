//
//  PWNetworkActivityIndicator.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/19.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PWNetworkActivityIndicator : NSObject

@property (nonatomic) NSUInteger numberOfConnection;

+ (PWNetworkActivityIndicator *)sharedManager;

+ (void)increment;
+ (void)decrement;
+ (NSUInteger)numberOfConnection;

@end
