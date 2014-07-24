//
//  PLDateFormatter.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLDateFormatter.h"

@interface PLDateFormatter ()

@end

@implementation PLDateFormatter

+ (NSDateFormatter *)formatter {
    static dispatch_once_t instance;
    static NSDateFormatter *dateFormatter;
    dispatch_once(&instance, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyyMMMd" options:0 locale:[NSLocale currentLocale]];
    });
    return dateFormatter;
}

+ (NSDateFormatter *)mmmddFormatter {
    static dispatch_once_t once;
    static NSDateFormatter *mmmddFormatter;
    dispatch_once(&once, ^{
        mmmddFormatter = [[NSDateFormatter alloc] init];
		mmmddFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMd" options:0 locale:[NSLocale currentLocale]];
    });
    return mmmddFormatter;
}

+ (NSCalendar *)calendar {
    static dispatch_once_t once;
    static NSCalendar *calendar;
    dispatch_once(&once, ^{
        calendar = [NSCalendar currentCalendar];
    });
    return calendar;
}

+ (NSDate *)adjustZeroClock:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    NSCalendar *calendar = [self calendar];
	NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                               fromDate:date];
	return [calendar dateFromComponents:components];
}

+ (NSDate *)adjustZeroYear:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    NSCalendar *calendar = [self calendar];
	NSDateComponents *components = [calendar components:NSYearCalendarUnit
                                               fromDate:date];
	return [calendar dateFromComponents:components];
}

+ (NSString *)arrangeDuration:(double)duration {
	NSInteger seconds = duration + 0.5;
    
    NSInteger min = seconds / 60;
	NSInteger sec = seconds % 60;
    
    return [NSString stringWithFormat:@"%ld:%02ld", (long)min, (long)sec];
}

@end
