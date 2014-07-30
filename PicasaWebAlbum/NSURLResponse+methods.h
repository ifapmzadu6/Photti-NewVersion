//
//  NSURLResponse+methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/30.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

static const NSRange kNSURLSessionTaskStatusCode0xx = (NSRange){.location = 000, .length = 100};
static const NSRange kNSURLSessionTaskStatusCode1xx = (NSRange){.location = 100, .length = 100};
static const NSRange kNSURLSessionTaskStatusCode2xx = (NSRange){.location = 200, .length = 100};
static const NSRange kNSURLSessionTaskStatusCode3xx = (NSRange){.location = 300, .length = 100};
static const NSRange kNSURLSessionTaskStatusCode4xx = (NSRange){.location = 400, .length = 100};
static const NSRange kNSURLSessionTaskStatusCode5xx = (NSRange){.location = 500, .length = 100};

@interface NSURLResponse (methods)

- (NSUInteger)statusCode;
- (NSString *)localizedStringForStatusCode;
- (BOOL)isSuccess;

@end
