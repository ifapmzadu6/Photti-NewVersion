//
//  PWPicasaPOSTRequest.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaPOSTRequest.h"

#import "PWOAuthManager.h"

static NSString * const PWPostURL = @"https://picasaweb.google.com/data/feed/api/user/default";
static NSString * const PWPutAlbumURL = @"https://picasaweb.google.com/data/entry/api/user/default/albumid";
static NSString * const PWDeleteAlbumURL = @"https://picasaweb.google.com/data/entry/api/user/default/albumid";

@interface PWPicasaPOSTRequest ()

@end

@implementation PWPicasaPOSTRequest

+ (void)postCreatingNewAlbumRequestWithTitle:(NSString *)title
                            summary:(NSString *)summary
                           location:(NSString *)location
                             access:(NSString *)access
                          timestamp:(NSString *)timestamp
                           keywords:(NSString *)keywords
                         completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [PWPicasaPOSTRequest getHttpHeaderFieldsWithCompletion:^(NSDictionary *headerFields) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:PWPostURL]];
        request.HTTPMethod = @"POST";
        NSString *body = [PWPicasaPOSTRequest makeBodyWithGPhotoID:nil Title:title summary:summary location:location access:access timestamp:timestamp keywords:keywords];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = bodyData;
        request.allHTTPHeaderFields = headerFields;
        [request addValue:[NSString stringWithFormat:@"%lud", (unsigned long)bodyData.length] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"application/atom+xml" forHTTPHeaderField:@"Content-Type"];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completion];
        [task resume];
    }];
}

+ (void)putModifyingAlbumWithID:(NSString *)albumID
                          title:(NSString *)title
                        summary:(NSString *)summary
                       location:(NSString *)location
                         access:(NSString *)access
                      timestamp:(NSString *)timestamp
                       keywords:(NSString *)keywords
                     completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [PWPicasaPOSTRequest getHttpHeaderFieldsWithCompletion:^(NSDictionary *headerFields) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", PWPutAlbumURL, albumID]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"PATCH";
        NSString *body = [PWPicasaPOSTRequest makeBodyWithGPhotoID:albumID Title:title summary:summary location:location access:access timestamp:timestamp keywords:keywords];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = bodyData;
        request.allHTTPHeaderFields = headerFields;
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
        [request addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
        [request addValue:@"*" forHTTPHeaderField:@"If-Match"];
        [request addValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completion];
        [task resume];
    }];
}

+ (void)deleteAlbumWithID:(NSString *)albumID completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [PWPicasaPOSTRequest getHttpHeaderFieldsWithCompletion:^(NSDictionary *headerFields) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", PWDeleteAlbumURL, albumID]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"DELETE";
        request.allHTTPHeaderFields = headerFields;
        [request addValue:@"*" forHTTPHeaderField:@"If-Match"];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completion];
        [task resume];
    }];
}

+ (void)getHttpHeaderFieldsWithCompletion:(void (^)(NSDictionary *headerFields))completion {
    [PWOAuthManager getAccessTokenWithCompletion:^(NSString *accessToken) {
        if (!accessToken) {
            if (completion) {
                completion(nil);
            }
        }
        else {
            NSString *tokenHeaderFieldValue = [NSString stringWithFormat:@"OAuth %@", accessToken];
            NSDictionary *headerFields = @{@"GData-Version": @"2",
                                           @"Authorization": tokenHeaderFieldValue};
            if (completion) {
                completion(headerFields);
            }
        }
    }];
}

static NSString * const PWCreatingAlbumBody = @"<?xml version='1.0' encoding='UTF-8'?>";
static NSString * const PWCreatingAlbumEntry = @"<entry xmlns='http://www.w3.org/2005/Atom' xmlns:gphoto='http://schemas.google.com/photos/2007' xmlns:media='http://search.yahoo.com/mrss/'>";
static NSString * const PWCreatingAlbumCategory = @"<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#album'/>";
static NSString * const PWCreatingAlbumEndEntry = @"</entry>";

+ (NSString *)makeBodyWithGPhotoID:(NSString *)gphotoID
                             Title:(NSString *)title
                           summary:(NSString *)summary
                          location:(NSString *)location
                            access:(NSString *)access
                         timestamp:(NSString *)timestamp
                          keywords:(NSString *)keywords {
    NSMutableString *body = [[NSMutableString alloc] init];
    [body appendString:PWCreatingAlbumBody];
    [body appendString:PWCreatingAlbumEntry];
    [body appendString:PWCreatingAlbumCategory];
    if (title) {
        [body appendFormat:@"<title>%@</title>", title];
    }
    if (summary) {
        [body appendFormat:@"<summary>%@</summary>", summary];
    }
    if (access) {
        [body appendFormat:@"<gphoto:access>%@</gphoto:access>", access];
    }
    if (location) {
        [body appendFormat:@"<gphoto:location>%@</gphoto:location>", location];
    }
    if (timestamp) {
        [body appendFormat:@"<gphoto:timestamp>%@</gphoto:timestamp>", timestamp];
    }
    if (keywords) {
        [body appendFormat:@"<media:group><media:keywords>%@</media:keywords></media:group>", keywords];
    }
    [body appendString:PWCreatingAlbumEndEntry];
    
    return body;
}

@end
