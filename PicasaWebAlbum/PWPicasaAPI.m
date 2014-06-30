//
//  PWPicasaAPI.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaAPI.h"

#import "PWPicasaGETRequest.h"
#import "PWPicasaPOSTRequest.h"
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
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaGETRequest getListOfAlbumsWithIndex:apiIndex completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            if (completion) {
                completion(nil, index, error);
            }
            return;
        }
        if (!data) {
            if (completion) {
                completion(nil, index, [PWPicasaAPI parserError]);
            }
            return;
        }
        
        //                NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
        //            NSLog(@"%@", json.description);
        
        [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
            NSDictionary *feed = NULL_TO_NIL(json[@"feed"]);
            NSDictionary *startIndexDic = NULL_TO_NIL(feed[@"openSearch:startIndex"]);
            NSDictionary *totalResultsDic = NULL_TO_NIL(feed[@"openSearch:totalResults"]);
            if (totalResultsDic && startIndexDic) {
                NSString *startIndex = NULL_TO_NIL(startIndexDic[@"text"]);
                if ([startIndex longLongValue] != apiIndex) {
                    if (completion) {
                        completion(nil, 0, [PWPicasaAPI parserError]);
                    }
                    return;
                }
                
                NSArray *albums = nil;
                NSString *totalResults = NULL_TO_NIL(totalResultsDic[@"text"]);
                if ([totalResults longLongValue] > 0) {
                    albums = [PWPicasaParser parseListOfAlbumFromJson:json context:context];
                    if (!albums) {
                        if (completion) {
                            completion(nil, 0, [PWPicasaAPI parserError]);
                        }
                        return;
                    }
                    
                    NSDate *date = [NSDate date];
                    for (PWAlbumObject *album in albums) {
                        album.sortIndex = @([startIndex integerValue] + [albums indexOfObject:album]);
                        album.tag_updated = date;
                    }
                    
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
                    request.predicate = [NSPredicate predicateWithFormat:@"tag_updated != %@", date];
                    NSError *error;
                    NSArray *deleteAlbums = [context executeFetchRequest:request error:&error];
                    for (PWAlbumObject *album in deleteAlbums) {
                        [context deleteObject:album];
                    }
                }
                
                if (completion) {
                    completion(albums, index + [totalResults integerValue], nil);
                }
                
                NSError *coreDataError = nil;
                [context save:&coreDataError];
            }
            else {
                if (completion) {
                    completion(nil, 0, [PWPicasaAPI parserError]);
                }
                return;
            }
        }];
    }];
}

+ (void)getListOfPhotosInAlbumWithAlbumID:(NSString *)albumID index:(NSUInteger)index completion:(void (^)(NSArray *, NSUInteger, NSError *))completion {
    if (index == NSUIntegerMax) {
        return;
    }
    NSInteger apiIndex = index + 1;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaGETRequest getListOfPhotosInAlbumWithAlbumID:albumID index:apiIndex completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            if (completion) {
                completion(nil, index, error);
            }
            return;
        }
        
        if (data) {
            NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
            //            NSLog(@"%@", json.description);
            
            [PWCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
                NSDictionary *feed = NULL_TO_NIL(json[@"feed"]);
                NSDictionary *startIndexDic = NULL_TO_NIL(feed[@"openSearch:startIndex"]);
                NSDictionary *totalResultsDic = NULL_TO_NIL(feed[@"openSearch:totalResults"]);
                if (totalResultsDic && startIndexDic) {
                    NSString *startIndex = NULL_TO_NIL(startIndexDic[@"text"]);
                    if ([startIndex longLongValue] != apiIndex) {
                        if (completion) {
                            completion(nil, 0, [PWPicasaAPI parserError]);
                        }
                        return;
                    }
                    
                    NSString *totalResults = NULL_TO_NIL(totalResultsDic[@"text"]);
                    NSArray *photos = nil;
                    if ([totalResults longLongValue] > 0) {
                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
                        request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
                        request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", albumID];
                        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
                        request.includesPropertyValues = NO;
                        NSError *error;
                        NSArray *deletePhotos = [context executeFetchRequest:request error:&error];
                        for (PWPhotoObject *photo in deletePhotos) {
                            [context deleteObject:photo];
                            [context refreshObject:photo mergeChanges:YES];
                        }
                        
                        photos = [PWPicasaParser parseListOfPhotoFromJson:json context:context];
                        if (!photos) {
                            if (completion) {
                                completion(nil, 0, [PWPicasaAPI parserError]);
                            }
                            return;
                        }
                        for (PWPhotoObject *photo in photos) {
                            photo.sortIndex = @([startIndex integerValue] + [photos indexOfObject:photo]);
                        }
                    }
                    
                    if (completion) {
                        completion(photos, index + [totalResults integerValue], nil);
                    }
                    
                    NSError *coreDataError = nil;
                    [context save:&coreDataError];
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

+ (void)postCreatingNewAlbumRequestWithTitle:(NSString *)title
                            summary:(NSString *)summary
                           location:(NSString *)location
                             access:(NSString *)access
                          timestamp:(NSString *)timestamp
                           keywords:(NSString *)keywords
                         completion:(void (^)(PWAlbumObject *album, NSError *error))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    void (^requestCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]);
            }
            return;
        }
        NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        if (statusCode != 201) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:PWParserErrorDomain code:statusCode userInfo:nil]);
            }
            return;
        }
        
        
//        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
//        NSLog(@"%@", json.description);
        
        id entries = NULL_TO_NIL(json[@"entry"]);
        if (!entries) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]);
            }
            return;
        };
        
        [PWCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
        
            PWAlbumObject *album = [PWPicasaParser albumFromJson:entries context:context];
            
            if (completion) {
                completion(album, nil);
            }
            
            [context save:nil];
        }];
    };
    
    [PWPicasaPOSTRequest postCreatingNewAlbumRequestWithTitle:title
                                             summary:summary
                                            location:location
                                              access:access
                                           timestamp:timestamp
                                            keywords:keywords
                                          completion:requestCompletion];
}

+ (void)putModifyingAlbumWithID:(NSString *)albumID
                          title:(NSString *)title
                        summary:(NSString *)summary
                       location:(NSString *)location
                         access:(NSString *)access
                      timestamp:(NSString *)timestamp
                       keywords:(NSString *)keywords
                     completion:(void (^)(NSString *, NSSet *, NSError *))completion {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    void (^requestCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        if (error) {
            if (completion) {
                completion(nil, nil, [NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]);
            }
            return;
        }
        
        NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        if (statusCode != 200) {
            if (completion) {
                completion(nil, nil, [NSError errorWithDomain:PWParserErrorDomain code:statusCode userInfo:nil]);
            }
            return;
        }
        
        [PWCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
            NSDictionary *entries = NULL_TO_NIL(json[@"entry"]);
            if (!entries) {
                if (completion) {
                    completion(nil, nil, [NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]);
                }
            }
            NSString *retAccess = nil;
            NSDictionary *accessDic = NULL_TO_NIL(entries[@"gphoto:access"]);
            if (accessDic) {
                retAccess = NULL_TO_NIL(accessDic[@"text"]);
            }
            NSArray *linkArray = NULL_TO_NIL(entries[@"link"]);
            NSMutableSet *links = [[NSMutableSet alloc] init];
            for (NSDictionary *linkDic in linkArray) {
                PWPhotoLinkObject *link = [PWPicasaParser linkFromJson:linkDic context:context];
                [links addObject:link];
            }
            
            if (completion) {
                completion(retAccess, links, nil);
            }
        }];
    };
    
    [PWPicasaPOSTRequest putModifyingAlbumWithID:albumID
                                           title:title
                                         summary:summary
                                        location:location
                                          access:access
                                       timestamp:timestamp
                                        keywords:keywords
                                      completion:requestCompletion];
}

+ (void)deleteAlbum:(PWAlbumObject *)album completion:(void (^)(NSError *error))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaPOSTRequest deleteAlbumWithID:album.id_str completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            if (completion) {
                completion([NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]);
            }
            return;
        }
        
        NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        if (statusCode != 200) {
            if (completion) {
                completion([NSError errorWithDomain:PWParserErrorDomain code:statusCode userInfo:nil]);
            }
            return;
        }
        
        if (completion) {
            completion(nil);
        }
    }];
}


+ (void)deletePhoto:(PWPhotoObject *)photo completion:(void (^)(NSError *error))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaPOSTRequest deletePhotoWithAlbumID:photo.albumid photoID:photo.id_str completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            if (completion) {
                completion([NSError errorWithDomain:PWParserErrorDomain code:0 userInfo:nil]);
            }
            return;
        }
        
        NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        if (statusCode != 200) {
            if (completion) {
                completion([NSError errorWithDomain:PWParserErrorDomain code:statusCode userInfo:nil]);
            }
            return;
        }
        
        [PWCoreDataAPI syncBlock:^(NSManagedObjectContext *context) {
            [context deleteObject:photo];
            [context save:nil];
        }];
        
        if (completion) {
            completion(nil);
        }
    }];
}

+ (void)getAuthorizedURLRequest:(NSURL *)url completion:(void (^)(NSMutableURLRequest *, NSError *))completion {
    [PWPicasaGETRequest getAuthorizedURLRequest:url completion:completion];
}

+ (void)authorizedURLRequest:(NSURL *)url completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [PWPicasaGETRequest authorizedGETRequestWithURL:url completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (completion) {
            completion(data, response, error);
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
