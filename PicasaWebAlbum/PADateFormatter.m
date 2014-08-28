//
//  PLDateFormatter.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PADateFormatter.h"

@interface PADateFormatter ()

@end

@implementation PADateFormatter

+ (NSDateFormatter *)formatter {
    static dispatch_once_t instance;
    static NSDateFormatter *dateFormatter;
    dispatch_once(&instance, ^{
        dateFormatter = [NSDateFormatter new];
		dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyyMMMd" options:0 locale:[NSLocale currentLocale]];
    });
    return dateFormatter;
}

+ (NSDateFormatter *)mmmddFormatter {
    static dispatch_once_t once;
    static NSDateFormatter *mmmddFormatter;
    dispatch_once(&once, ^{
        mmmddFormatter = [NSDateFormatter new];
		mmmddFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMd" options:0 locale:[NSLocale currentLocale]];
    });
    return mmmddFormatter;
}

+ (NSDateFormatter *)fullStringFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *fullStringFormatter;
    dispatch_once(&onceToken, ^{
        fullStringFormatter = [NSDateFormatter new];
        fullStringFormatter.dateStyle = NSDateFormatterLongStyle;
        fullStringFormatter.timeStyle = NSDateFormatterMediumStyle;
        fullStringFormatter.locale = [NSLocale currentLocale];
    });
    return fullStringFormatter;
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
