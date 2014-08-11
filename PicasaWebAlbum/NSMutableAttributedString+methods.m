//
//  NSMutableAttributedString+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "NSMutableAttributedString+methods.h"

@implementation NSMutableAttributedString (methods)

- (void)addAttrubutes:(NSDictionary *)attributes string:(NSString *)string {
    if (!string) {
        return;
    }
    
    NSRange searchRange = NSMakeRange(0, [self length]);
    NSRange place;
    while (searchRange.location < [self length]) {
        place = [self.string rangeOfString:string options:(NSLiteralSearch | NSCaseInsensitiveSearch) range:searchRange];
        if (place.location != NSNotFound) {
            [self addAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0f]} range:place];
        }
        searchRange.location = place.location + place.length;
        searchRange.length = [self length] - searchRange.location;
    }
}

@end
