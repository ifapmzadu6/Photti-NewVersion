//
//  PWPicasaAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaAPI.h"

#import "PWPicasaGETRequest.h"
#import "PWPicasaParser.h"
#import "XmlReader.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

NSString * const PWParserErrorDomain = @"photti.PicasaWebAlbum.com.ErrorDomain";

@implementation PWPicasaAPI

+ (void)getListOfAlbumsWithIndex:(NSUInteger)index completion:(void (^)(NSArray *, NSUInteger, NSError *))completion {
    if (index == NSUIntegerMax) {
        return;
    }
    NSInteger apiIndex = index + 1;
    
    [PWPicasaGETRequest getListOfAlbumsWithIndex:apiIndex completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, index, error);
            }
            return;
        }
        
        if (data) {
            NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
//            NSLog(@"%@", json.description);
            
            [PWCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSDictionary *feed = NULL_TO_NIL(json[@"feed"]);
                NSDictionary *startIndexDic = NULL_TO_NIL(feed[@"openSearch:startIndex"]);
                NSDictionary *totalResultsDic = NULL_TO_NIL(feed[@"openSearch:totalResults"]);
                if (totalResultsDic && startIndexDic) {
                    NSString *startIndex = NULL_TO_NIL(startIndexDic[@"text"]);
                    if ([startIndex longLongValue] != apiIndex) {
                        if (completion) {
                            completion(nil, 0, [PWPicasaAPI parserError]);
                        }
                    }
                    
                    NSString *totalResults = NULL_TO_NIL(totalResultsDic[@"text"]);
                    if ([totalResults longLongValue] > 0) {
                        NSArray *albums = [PWPicasaParser parseListOfAlbumFromJson:json context:context];
                        if (!albums) {
                            if (completion) {
                                completion(nil, 0, [PWPicasaAPI parserError]);
                            }
                            return;
                        }
                        for (PWAlbumObject *album in albums) {
                            album.sortIndex = @([startIndex integerValue] + [albums indexOfObject:album]);
                        }
                        
                        NSError *coreDataError = nil;
                        [context save:&coreDataError];
                        if (coreDataError) {
                            if (completion) {
                                completion(nil, 0, [PWPicasaAPI coreDataError]);
                            }
                        }
                        
                        if (completion) {
                            completion(albums, index + [totalResults integerValue], nil);
                        }
                    }
                }
                else {
                    if (completion) {
                        completion(nil, 0, [PWPicasaAPI parserError]);
                    }
                }
            }];
        }
    }];
}

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSArray *, NSUInteger, NSError *))completion {
    if (index == NSUIntegerMax) {
        return;
    }
    NSInteger apiIndex = index + 1;
    
    [PWPicasaGETRequest getListOfPhotosInAlbumWithAlbumID:albumID index:apiIndex completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, index, error);
            }
            return;
        }
        
        if (data) {
            NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
//            NSLog(@"%@", json.description);
            
            [PWCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSDictionary *feed = NULL_TO_NIL(json[@"feed"]);
                NSDictionary *startIndexDic = NULL_TO_NIL(feed[@"openSearch:startIndex"]);
                NSDictionary *totalResultsDic = NULL_TO_NIL(feed[@"openSearch:totalResults"]);
                if (totalResultsDic && startIndexDic) {
                    NSString *startIndex = NULL_TO_NIL(startIndexDic[@"text"]);
                    if ([startIndex longLongValue] != apiIndex) {
                        if (completion) {
                            completion(nil, 0, [PWPicasaAPI parserError]);
                        }
                    }
                    
                    NSString *totalResults = NULL_TO_NIL(totalResultsDic[@"text"]);
                    if ([totalResults longLongValue] > 0) {
                        NSArray *photos = [PWPicasaParser parseListOfPhotoFromJson:json context:context];
                        if (!photos) {
                            if (completion) {
                                completion(nil, 0, [PWPicasaAPI parserError]);
                            }
                            return;
                        }
                        for (PWPhotoObject *photo in photos) {
                            photo.sortIndex = @([startIndex integerValue] + [photos indexOfObject:photo]);
                        }
                        
                        NSError *coreDataError = nil;
                        [context save:&coreDataError];
                        if (coreDataError) {
                            if (completion) {
                                completion(nil, 0, [PWPicasaAPI coreDataError]);
                            }
                        }
                        
                        if (completion) {
                            completion(photos, index + [totalResults integerValue], nil);
                        }
                    }
                }
                else {
                    if (completion) {
                        completion(nil, 0, [PWPicasaAPI parserError]);
                    }
                }
            }];
        }
    }];
}


+ (NSError *)parserError {
    return [[NSError alloc] initWithDomain:PWParserErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"[ERROR] Parser Error from Picasa JSON!"}];
}

+ (NSError *)coreDataError {
    return [[NSError alloc] initWithDomain:PWParserErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"[ERROR] CoreData Context Error!"}];
}

@end
