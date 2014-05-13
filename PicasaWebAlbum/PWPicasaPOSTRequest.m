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
static NSString * const PWPutAndDeleteAlbumURL = @"https://picasaweb.google.com/data/entry/api/user/default/albumid";

@interface PWPicasaPOSTRequest ()

@end

@implementation PWPicasaPOSTRequest

+ (void)postCreatingNewAlbumRequest:(NSString *)title
                            summary:(NSString *)summary
                           location:(NSString *)location
                             access:(NSString *)access
                          timestamp:(NSString *)timestamp
                           keywords:(NSString *)keywords
                         completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [PWPicasaPOSTRequest getHttpHeaderFieldsWithCompletion:^(NSDictionary *headerFields) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:PWPostURL]];
        request.HTTPMethod = @"POST";
        NSString *body = [PWPicasaPOSTRequest makeBodyWithTitle:title
                                                        summary:summary
                                                       location:location
                                                         access:access
                                                      timestamp:timestamp
                                                       keywords:keywords];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = bodyData;
        request.allHTTPHeaderFields = headerFields;
        [request addValue:[NSString stringWithFormat:@"%ud", bodyData.length] forHTTPHeaderField:@"Content-Length"];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completion];
        [task resume];
    }];
}

+ (void)deleteAlbumWithID:(NSString *)albumID completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [PWPicasaPOSTRequest getHttpHeaderFieldsWithCompletion:^(NSDictionary *headerFields) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", PWPutAndDeleteAlbumURL, albumID]];
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
                                           @"Authorization": tokenHeaderFieldValue,
                                           @"Content-Type": @"application/atom+xml"};
            if (completion) {
                completion(headerFields);
            }
        }
    }];
}



static NSString * const PWCreatingAlbumEntry = @"<entry xmlns='http://www.w3.org/2005/Atom'\nxmlns:media='http://search.yahoo.com/mrss/'\nxmlns:gphoto='http://schemas.google.com/photos/2007'>\n";
static NSString * const PWCreatingAlbumCategory = @"<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#album'></category>\n";

+ (NSString *)makeBodyWithTitle:(NSString *)title
                        summary:(NSString *)summary
                       location:(NSString *)location
                         access:(NSString *)access
                      timestamp:(NSString *)timestamp
                       keywords:(NSString *)keywords {
    NSMutableString *body = [[NSMutableString alloc] initWithString:PWCreatingAlbumEntry];
    if (title) {
        [body appendFormat:@"<title type='text'>%@</title>\n", title];
    }
    if (summary) {
        [body appendFormat:@"<summary type='text'>%@</summary>\n", summary];
    }
    if (location) {
        [body appendFormat:@"<gphoto:location>%@</gphoto:location>\n", location];
    }
    if (access) {
        [body appendFormat:@"<gphoto:access>%@</gphoto:access>\n", access];
    }
    if (timestamp) {
        [body appendFormat:@"<gphoto:timestamp>%@</gphoto:timestamp>\n", timestamp];
    }
    if (keywords) {
        [body appendFormat:@"<media:group>\n<media:keywords>%@</media:keywords>\n</media:group>\n", keywords];
    }
    [body appendString:PWCreatingAlbumCategory];
    [body appendString:@"</entry>"];
    
    return body;
}

@end
