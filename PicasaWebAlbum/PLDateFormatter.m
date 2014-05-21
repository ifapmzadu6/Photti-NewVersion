//
//  PLDateFormatter.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLDateFormatter.h"

@interface PLDateFormatter ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDateFormatter *mmmddFormatter;
@property (strong, nonatomic) NSCalendar *calendar;

@end

@implementation PLDateFormatter

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
		_mmmddFormatter = [[NSDateFormatter alloc] init];
		_calendar = [NSCalendar currentCalendar];
		_dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyyMMMd" options:0 locale:[NSLocale currentLocale]];
		_mmmddFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMd" options:0 locale:[NSLocale currentLocale]];
    }
    return self;
}

+ (NSDateFormatter *)formatter {
	return [[PLDateFormatter sharedManager] dateFormatter];
}

+ (NSDateFormatter *)mmmddFormatter {
	return [[PLDateFormatter sharedManager] mmmddFormatter];;
}

+ (NSDateFormatter *)fullStringFormatter {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyyMMMdHHmm" options:0 locale:[NSLocale currentLocale]];
	
	return formatter;
}

+ (NSDate *)adjustZeroClock:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    NSCalendar *calendar = [[PLDateFormatter sharedManager] calendar];
	NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
												fromDate:date];
	return [calendar dateFromComponents:components];
}

+ (NSDate *)adjustZeroYear:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    NSCalendar *calendar = [[PLDateFormatter sharedManager] calendar];
	NSDateComponents *components = [calendar components:NSYearCalendarUnit
												fromDate:date];
	return [calendar dateFromComponents:components];
}

@end
