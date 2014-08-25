//
//  PWDateTimestamp.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PWDateTimestamp : NSObject

+ (NSString *)timestampForDate:(NSDate *)date;
+ (NSNumber *)timestampByNumberForDate:(NSDate *)date;
+ (NSDate *)dateForTimestamp:(NSString *)timestamp;

@end
