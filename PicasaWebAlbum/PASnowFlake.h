//
//  PWSnowFlake.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PASnowFlake : NSObject

+ (unsigned long long)generateUniqueID;
+ (NSString *)generateUniqueIDString;

@end
