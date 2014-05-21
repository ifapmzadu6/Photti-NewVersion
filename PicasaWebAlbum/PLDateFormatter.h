//
//  PLDateFormatter.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PLDateFormatter : NSObject

+ (id)sharedManager;

+ (NSDateFormatter *)formatter;

+ (NSDateFormatter *)mmmddFormatter;

+ (NSDateFormatter *)fullStringFormatter;

+ (NSDate *)adjustZeroClock:(NSDate *)date;

+ (NSDate *)adjustZeroYear:(NSDate *)date;

@end
