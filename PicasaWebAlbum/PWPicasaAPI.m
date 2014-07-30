//
//  PWPicasaAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaAPI.h"

#import "NSURLResponse+methods.h"
#import "PWPicasaGETRequest.h"
#import "PWPicasaPOSTRequest.h"
#import "PWPicasaParser.h"
#import "XmlReader.h"

#define NtN(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

NSString * const PWParserErrorDomain = @"photti.PicasaWebAlbum.com.ErrorDomain";

@implementation PWPicasaAPI

static NSString * const PWXMLNode = @"text";

+ (void)getListOfAlbumsWithIndex:(NSUInteger)index completion:(void (^)(NSUInteger, NSError *))completion {
    if (index == NSUIntegerMax) {
        return;
    }
    NSInteger apiIndex = index + 1;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaGETRequest getListOfAlbumsWithIndex:apiIndex completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            completion ? completion(index, error) : 0;
            return;
        }
        if (!response.isSuccess) {
            completion ? completion(index, [PWPicasaAPI parserError]) : 0;
            return;
        }
        if (!data) {
            completion ? completion(index, [PWPicasaAPI parserError]) : 0;
            return;
        }
        
        NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
//        NSLog(@"%@", json.description);
        
        NSDictionary *feed = NtN(json[@"feed"]);
        NSDictionary *startIndexDic = NtN(feed[@"openSearch:startIndex"]);
        NSDictionary *totalResultsDic = NtN(feed[@"openSearch:totalResults"]);
        if (totalResultsDic && startIndexDic) {
            NSString *startIndex = NtN(startIndexDic[PWXMLNode]);
            if (startIndex.longLongValue != apiIndex) {
                completion ? completion(index, [PWPicasaAPI parserError]) : 0;
                return;
            }
            
            NSString *totalResults = NtN(totalResultsDic[PWXMLNode]);
            if (totalResults.longLongValue > 0) {
                [PWCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                    NSArray *albums = [PWPicasaParser parseListOfAlbumFromJson:json isDelete:YES context:context];
                    if (!albums) {
                        completion ? completion(index, [PWPicasaAPI parserError]) : 0;
                        return;
                    }
                    
                    NSDate *date = [NSDate date];
                    for (PWAlbumObject *album in albums) {
                        album.sortIndex = @(startIndex.integerValue + [albums indexOfObject:album]);
                        album.tag_updated = date;
                    }
                }];
                
                completion ? completion(index + totalResults.integerValue, nil) : 0;
            }
        }
        else {
            if (completion) {
                completion(index, [PWPicasaAPI parserError]);
            }
            return;
        }
    }];
}

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSUInteger, NSError *))completion {
    if (index == NSUIntegerMax) {
        return;
    }
    NSInteger apiIndex = index + 1;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaGETRequest getListOfPhotosInAlbumWithAlbumID:albumID index:apiIndex completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            completion ? completion(index, error) : 0;
            return;
        }
        if (!response.isSuccess) {
            completion ? completion(index, [PWPicasaAPI parserError]) : 0;
            return;
        }
        if (!data) {
            completion ? completion(index, [PWPicasaAPI parserError]) : 0;
            return;
        }
        
        NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
//        NSLog(@"%@", json.description);
        
        NSDictionary *feed = NtN(json[@"feed"]);
        NSDictionary *startIndexDic = NtN(feed[@"openSearch:startIndex"]);
        NSDictionary *totalResultsDic = NtN(feed[@"openSearch:totalResults"]);
        if (totalResultsDic && startIndexDic) {
            NSString *startIndex = NtN(startIndexDic[PWXMLNode]);
            if (startIndex.longLongValue != apiIndex) {
                completion ? completion(index, [PWPicasaAPI parserError]) : 0;
                return;
            }
            
            NSString *totalResults = NtN(totalResultsDic[PWXMLNode]);
            if (totalResults.longLongValue == 0) {
                completion ? completion(index, [PWPicasaAPI parserError]) : 0;
                return;
            }
            
            [PWCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
                NSArray *photos = [PWPicasaParser parseListOfPhotoFromJson:json albumID:albumID context:context];
                if (!photos) {
                    completion ? completion(index, [PWPicasaAPI parserError]) : 0;
                    return;
                }
                for (PWPhotoObject *photo in photos) {
                    photo.sortIndex = @(startIndex.integerValue + [photos indexOfObject:photo]);
                }
            }];
            
            completion ? completion(index + totalResults.integerValue, nil) : 0;
        }
    }];
}

+ (void)postCreatingNewAlbumRequestWithTitle:(NSString *)title summary:(NSString *)summary location:(NSString *)location access:(NSString *)access timestamp:(NSString *)timestamp keywords:(NSString *)keywords completion:(void (^)(PWAlbumObject *album, NSError *error))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    void (^requestCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            completion ? completion(nil, [NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        if (!response.isSuccess) {
            completion ? completion(nil, [NSError errorWithDomain:PWParserErrorDomain code:response.statusCode userInfo:nil]) : 0;
            return;
        }
        
        NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
//        NSLog(@"%@", json.description);
        
        id entries = NtN(json[@"entry"]);
        if (!entries) {
            completion ? completion(nil, [NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]) : 0;
            return;
        };
        
        [PWCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
            PWAlbumObject *album = [PWPicasaParser albumFromJson:entries existingAlbums:nil context:context];
            
            NSError *error = nil;
            if (![context save:&error]) {
                abort();
            }
            
            completion ? completion(album, nil) : 0;
        }];
    };
    
    [PWPicasaPOSTRequest postCreatingNewAlbumRequestWithTitle:title summary:summary location:location access:access timestamp:timestamp keywords:keywords completion:requestCompletion];
}

+ (void)putModifyingAlbumWithID:(NSString *)albumID title:(NSString *)title summary:(NSString *)summary location:(NSString *)location access:(NSString *)access timestamp:(NSString *)timestamp keywords:(NSString *)keywords completion:(void (^)(NSError *))completion {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    void (^requestCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        if (error) {
            completion ? completion([NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        if (!response.isSuccess) {
            completion ? completion([NSError errorWithDomain:PWParserErrorDomain code:response.statusCode userInfo:nil]) : 0;
            return;
        }
        
        NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
        if (!json) {
            completion ? completion([NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        
        [PWCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            [PWPicasaParser parseListOfAlbumFromJson:json isDelete:NO context:context];
        }];
        
        completion ? completion(nil) : 0;
    };
    
    [PWPicasaPOSTRequest putModifyingAlbumWithID:albumID title:title summary:summary location:location access:access timestamp:timestamp keywords:keywords completion:requestCompletion];
}

+ (void)deleteAlbum:(PWAlbumObject *)album completion:(void (^)(NSError *error))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaPOSTRequest deleteAlbumWithID:album.id_str completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            completion ? completion([NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        if (!response.isSuccess) {
            completion ? completion([NSError errorWithDomain:PWParserErrorDomain code:response.statusCode userInfo:nil]) : 0;
            return;
        }
        
        completion ? completion(nil) : 0;
    }];
}


+ (void)deletePhoto:(PWPhotoObject *)photo completion:(void (^)(NSError *error))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSManagedObjectID *photoObjectID = photo.objectID;
    [PWPicasaPOSTRequest deletePhotoWithAlbumID:photo.albumid photoID:photo.id_str completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            completion ? completion([NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]) : 0;
            return;
        }
        if (!response.isSuccess) {
            completion ? completion([NSError errorWithDomain:PWParserErrorDomain code:response.statusCode userInfo:nil]) : 0;
            return;
        }
        
        [PWCoreDataAPI writeWithBlockAndWait:^(NSManagedObjectContext *context) {
            PWPhotoObject *photoObject = (PWPhotoObject *)[context objectWithID:photoObjectID];
            [context deleteObject:photoObject];
        }];
        
        completion ? completion(nil) : 0;
    }];
}

+ (void)getAuthorizedURLRequest:(NSURL *)url completion:(void (^)(NSMutableURLRequest *, NSError *))completion {
    [PWPicasaGETRequest getAuthorizedURLRequest:url completion:completion];
}

+ (void)authorizedURLRequest:(NSURL *)url completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaGETRequest authorizedGETRequestWithURL:url completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        completion ? completion(data, response, error) : 0;
    }];
}

+ (NSError *)parserError {
    return [[NSError alloc] initWithDomain:PWParserErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"[ERROR] Parser Error from Picasa JSON!"}];
}

+ (NSError *)coreDataError {
    return [[NSError alloc] initWithDomain:PWParserErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"[ERROR] CoreData Context Error!"}];
}

@end
