//
//  NSURLResponse+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/30.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "NSURLResponse+methods.h"

@implementation NSURLResponse (methods)

- (NSUInteger)statusCode {
    return ((NSHTTPURLResponse *)self).statusCode;
}

- (NSString *)localizedStringForStatusCode {
    return [NSHTTPURLResponse localizedStringForStatusCode:self.statusCode];
}

- (BOOL)isSuccess {
    if (![self isStasusCode2xxSuccess]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isStasusCode2xxSuccess {
    NSUInteger statusCode = ((NSHTTPURLResponse *)self).statusCode;
    NSIndexSet *statusCode1xxInformational = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode1xx];
    NSIndexSet *statusCode2xxSuccess = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode2xx];
    NSIndexSet *statusCode3xxRedirectin = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode3xx];
    NSIndexSet *statusCode4xxClientError = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode4xx];
    NSIndexSet *statusCode5xxServerError = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode5xx];
    
//#ifdef DEBUG
//    NSLog(@"%ld", (long)statusCode);
//    NSLog(@"%@", [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
//#endif
    
    if ([statusCode1xxInformational containsIndex:statusCode]) {
        return NO;
    }
    else if ([statusCode2xxSuccess containsIndex:statusCode]) {
        return YES;
    }
    else if ([statusCode3xxRedirectin containsIndex:statusCode]) {
        return NO;
    }
    else if ([statusCode4xxClientError containsIndex:statusCode]) {
        return NO;
    }
    else if ([statusCode5xxServerError containsIndex:statusCode]) {
        return NO;
    }
    
    return YES;
}

@end
