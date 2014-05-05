//
//  PWPicasaAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaAPI.h"

#import "PWOAuthManager.h"

static NSString * const PWGETListURL = @"https://picasaweb.google.com/data/feed/api/user/default";
static NSString * const PWPhotoURL = @"https://picasaweb.google.com/data/feed/api/user/defalut/albumid/6008134399656118257/photoid/6008268666980154946";

@interface PWPicasaAPI ()

@end

@implementation PWPicasaAPI

+ (void)getListOfAlbumsWithCompletionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSURL *url = [PWPicasaAPI urlWithUrlString:PWGETListURL param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaAPI httpHeaderFields];
    
    [PWPicasaAPI authorizedGETRequest:request completionHandler:completionHandler];
}

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = [NSString stringWithFormat:@"%@/albumid/%@", PWGETListURL, albumID];
    NSURL *url = [PWPicasaAPI urlWithUrlString:urlString param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaAPI httpHeaderFields];
    
    [PWPicasaAPI authorizedGETRequest:request completionHandler:completionHandler];
}

+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = [NSString stringWithFormat:@"%@/albumid/%@/photoid/%@", PWGETListURL, albumID, photoID];
    NSURL *url = [PWPicasaAPI urlWithUrlString:urlString param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaAPI httpHeaderFields];
    
    [PWPicasaAPI authorizedGETRequest:request completionHandler:completionHandler];
}

+ (void)getTestAccessURL:(NSString *)urlString completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSURL *url = [PWPicasaAPI urlWithUrlString:urlString param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaAPI httpHeaderFields];
    
    [PWPicasaAPI authorizedGETRequest:request completionHandler:completionHandler];
}

+ (void)authorizedGETRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    
    GTMOAuth2Authentication *auth = [PWOAuthManager authentication];
    [auth authorizeRequest:request completionHandler:^(NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, nil, error);
            }
            return;
        }
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                if (completionHandler) {
                    completionHandler(nil, nil, error);
                }
                return;
            }
            
            completionHandler(data, response, nil);
        }];
        [task resume];
    }];
}

+ (NSURL *)urlWithUrlString:(NSString *)urlString param:(NSDictionary *)param {
    if (!param) {
        return [NSURL URLWithString:urlString];
    }
    
    NSString *tmpUrlString = urlString.copy;
    if (param.count > 0) {
        for (NSString *key in param.allKeys) {
            tmpUrlString = [NSString stringWithFormat:@"%@&%@=%@", tmpUrlString, key, param[key]];
        }
    }
    
    NSURL *url = [NSURL URLWithString:tmpUrlString];
    return url;
}

+ (NSDictionary *)httpHeaderFields {
    NSDictionary *headerFields = @{@"GData-Version": @"2"};
    
    return headerFields;
}

@end
