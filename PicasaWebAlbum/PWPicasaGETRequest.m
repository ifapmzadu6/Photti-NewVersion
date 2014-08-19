//
//  PWPicasaAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaGETRequest.h"

#import "PWOAuthManager.h"

@interface PWPicasaGETRequest ()

@end

@implementation PWPicasaGETRequest

static NSString * const PWGETListURL = @"https://picasaweb.google.com/data/feed/api/user/default";
static NSString * const PWPicasaGETRequestAlbumThumbnailSizeName = @"320u";
static NSString * const PWPicasaGETRequestPhotoThumbnailSizeName = @"288u";
static NSString * const PWPicasaGETRequestPhotoThumbnailMaxSizeName = @"1024";

+ (void)getListOfAlbumsWithIndex:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:PWGETListURL param:@{@"thumbsize": PWPicasaGETRequestAlbumThumbnailSizeName}];
    [PWPicasaGETRequest authorizedGETRequestWithURL:url completion:completion];
}

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@/albumid/%@", PWGETListURL, albumID];
    NSURL *url = [PWPicasaGETRequest urlWithUrlString:urlString param:@{@"thumbsize": PWPicasaGETRequestPhotoThumbnailSizeName, @"imgmax": PWPicasaGETRequestPhotoThumbnailMaxSizeName}];
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
    [PWOAuthManager getAuthorizeHTTPHeaderFields:^(NSDictionary *headerFields, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
        }
        else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            request.allHTTPHeaderFields = headerFields;
            [request addValue:@"2" forHTTPHeaderField:@"GData-Version"];
            if (completion) {
                completion(request, nil);
            }
        }
    }];
}

+ (void)authorizedGETRequestWithURL:(NSURL *)url completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [PWOAuthManager getAuthorizeHTTPHeaderFields:^(NSDictionary *headerFields, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, nil, error);
            }
        }
        else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            request.allHTTPHeaderFields = headerFields;
            [request addValue:@"2" forHTTPHeaderField:@"GData-Version"];
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

@end
