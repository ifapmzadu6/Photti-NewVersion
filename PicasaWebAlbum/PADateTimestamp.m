//
//  PWDateTimestamp.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PADateTimestamp.h"

static const long long kPWDateTimestampMillisecond = 1000;

@implementation PADateTimestamp

+ (NSString *)timestampForDate:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    NSNumber *timestamp = [PADateTimestamp timestampByNumberForDate:date];
    if (timestamp) {
        return timestamp.stringValue;
    }
    else {
        return nil;
    }
}

+ (NSNumber *)timestampByNumberForDate:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    long long timestamp = [date timeIntervalSince1970] * kPWDateTimestampMillisecond;
    return @(timestamp);
}

+ (NSDate *)dateForTimestamp:(NSString *)timestamp {
    if (!timestamp) {
        return nil;
    }
    
    double milliseconds = timestamp.doubleValue / (double)kPWDateTimestampMillisecond;
    return [NSDate dateWithTimeIntervalSince1970:milliseconds];
}

@end
