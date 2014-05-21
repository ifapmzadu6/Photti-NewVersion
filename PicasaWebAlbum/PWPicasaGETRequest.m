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
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:PWGETListURL param:@{@"thumbsize": @"320u"}];
    [PWPicasaGETRequest authorizedGETRequestWithURL:url completion:completion];
}

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@/albumid/%@", PWGETListURL, albumID];
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:urlString param:@{@"thumbsize": @"288u", @"imgmax": @"1024"}];
    [PWPicasaGETRequest authorizedGETRequestWithURL:url completion:completion];
}

+ (void)getPhotoWithAlbumID:(NSString *)albumID photoID:(NSString *)photoID completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@/albumid/%@/photoid/%@", PWGETListURL, albumID, photoID];
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:urlString param:nil];
    [PWPicasaGETRequest authorizedGETRequestWithURL:url completion:completion];
}

+ (void)getTestAccessURL:(NSString *)urlString completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:urlString param:nil];
    [PWPicasaGETRequest authorizedGETRequestWithURL:url completion:completion];
}

+ (void)getAuthorizedURLRequest:(NSURL *)url completion:(void (^)(NSMutableURLRequest *, NSError *))completion {
    [PWPicasaGETRequest getHttpHeaderFieldsWithCompletion:^(NSDictionary *headerFields, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
        }
        else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            request.allHTTPHeaderFields = headerFields;
            if (completion) {
                completion(request, nil);
            }
        }
    }];
}

+ (void)authorizedGETRequestWithURL:(NSURL *)url completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [PWPicasaGETRequest getHttpHeaderFieldsWithCompletion:^(NSDictionary *headerFields, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, nil, error);
            }
        }
        else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            request.allHTTPHeaderFields = headerFields;
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completion];
            [task resume];
        }
    }];
}

+ (NSURL *)urlWithUrlString:(NSString *)urlString param:(NSDictionary *)param {
    if (!param) {
        return [NSURL URLWithString:urlString];
    }
    
    NSString *tmpUrlString = urlString.copy;
    NSArray *keys = param.allKeys;
    for (NSInteger i = 0; i < keys.count; i++) {
        NSString *format = @"%@&%@=%@";
        if (i == 0) {
            format = @"%@?%@=%@";
        }
        tmpUrlString = [NSString stringWithFormat:format, tmpUrlString, keys[i], param[keys[i]]];
    }
    
    NSURL *url = [NSURL URLWithString:tmpUrlString];
    return url;
}

+ (void)getHttpHeaderFieldsWithCompletion:(void (^)(NSDictionary *headerFields, NSError *error))completion {
    [PWOAuthManager getAccessTokenWithCompletion:^(NSString *accessToken, NSError *error) {
        if (!accessToken) {
            if (completion) {
                completion(nil, error);
            }
        }
        else {
//            NSString *tokenHeaderFieldValue = [NSString stringWithFormat:@"Bearer %@", accessToken];
//            NSDictionary *headerFields = @{@"GData-Version": @"2", @"Authorization": tokenHeaderFieldValue};
            NSDictionary *headerFields = @{@"GData-Version": @"2", @"Authorization": accessToken};
            if (completion) {
                completion(headerFields, nil);
            }
        }
    }];
}

@end
