//
//  PLDateFormatter.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PLDateFormatter : NSObject

+ (NSDateFormatter *)formatter;
+ (NSDateFormatter *)mmmddFormatter;
+ (NSDate *)adjustZeroClock:(NSDate *)date;
+ (NSDate *)adjustZeroYear:(NSDate *)date;
+ (NSString *)arrangeDuration:(double)duration;

@end
