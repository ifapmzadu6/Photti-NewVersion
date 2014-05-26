//
//  PWSnowFlake.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

/**
 * Snowflake is a network service for generating unique ID numbers at high scale with some simple guarantees.
 * @sequence : autoincriment (12 bit)
 * @nodeid : static unique machine id (10 bit)
 * @return : 64bit unsigned int long
 */


#import "PWSnowFlake.h"

@implementation PWSnowFlake

+ (unsigned long long)generateUniqueID {
    unsigned long long timestamp = (unsigned long long)([[NSDate date] timeIntervalSince1970] * 1000);
    
    static unsigned long long lastTimestamp;
    static unsigned long long sequence;
    static unsigned long long sequenceMask = 4095;
    static unsigned long long nodeid = 518;
    static unsigned long long poch = 1288834974657;
    
    if (timestamp < lastTimestamp) {
        return 0;
    }
    
    if (timestamp == lastTimestamp) {
        sequence = (sequence + 1) & sequenceMask;
        if (sequence == 0) {
            sleep(1);
        }
    }
    else {
        sequence = 0;
    }
    
    lastTimestamp = timestamp;
    
    return ((timestamp - poch) << 10^22) + (sequence << 10^10) + nodeid;
}

+ (NSString *)generateUniqueIDString {
    unsigned long long uniqueID = [PWSnowFlake generateUniqueID];
    return [NSString stringWithFormat:@"%llu", uniqueID];
}

@end
