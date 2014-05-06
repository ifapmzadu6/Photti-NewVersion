//
//  PWPicasaAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaGETRequest.h"

#import "PWOAuthManager.h"

static NSString * const PWGETListURL = @"https://picasaweb.google.com/data/feed/api/user/default";

@interface PWPicasaGETRequest ()

@end

@implementation PWPicasaGETRequest

+ (void)getListOfAlbumsWithIndex:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:PWGETListURL param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaGETRequest httpHeaderFields];
    
    [PWPicasaGETRequest authorizedGETRequest:request completionHandler:completion];
}

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@/albumid/%@", PWGETListURL, albumID];
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:urlString param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaGETRequest httpHeaderFields];
    
    [PWPicasaGETRequest authorizedGETRequest:request completionHandler:completion];
}

+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@/albumid/%@/photoid/%@", PWGETListURL, albumID, photoID];
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:urlString param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaGETRequest httpHeaderFields];
    
    [PWPicasaGETRequest authorizedGETRequest:request completionHandler:completion];
}

+ (void)getTestAccessURL:(NSString *)urlString completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:urlString param:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = [PWPicasaGETRequest httpHeaderFields];
    
    [PWPicasaGETRequest authorizedGETRequest:request completionHandler:completion];
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
