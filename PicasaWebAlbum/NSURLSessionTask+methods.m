//
//  NSURLSessionTask+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/30.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "NSURLSessionTask+methods.h"

static NSString * const kNSURLSessionTaskHTTPHeaderContentTypeName = @"Content-Type";

@implementation NSURLSessionTask (methods)

- (BOOL)isSuccess {
    if (self.error) {
        NSLog(@"%s%@", __func__, self.error);
        return NO;
    }
    
    
    return YES;
}

- (BOOL)isStasusCode2xxSuccess {
    NSURLResponse *response = self.response;
    NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    NSIndexSet *statusCode1xxInformational = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode1xx];
    NSIndexSet *statusCode2xxSuccess = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode2xx];
    NSIndexSet *statusCode3xxRedirectin = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode3xx];
    NSIndexSet *statusCode4xxClientError = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode4xx];
    NSIndexSet *statusCode5xxServerError = [NSIndexSet indexSetWithIndexesInRange:kNSURLSessionTaskStatusCode5xx];
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
    
    NSLog(@"%ld", (long)statusCode);
    NSLog(@"%@", [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
    
    return YES;
}

//- (BOOL)isResponseHeadersMatchRequestHeaders {
//    NSDictionary *requestHeaders = self.originalRequest.allHTTPHeaderFields;
//    NSDictionary *responseHeaders = [(NSHTTPURLResponse *)self.response allHeaderFields];
//    
//    
//}
//
//- (BOOL)isContentTypeMatch:(NSDictionary *)headers {
//    
//}

@end
