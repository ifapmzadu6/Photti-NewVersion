//
//  PWPicasaParser.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaParser.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

//#define DEBUG_LOCAL

@interface PWPicasaParser ()

@end

@implementation PWPicasaParser

+ (NSArray *)parseListOfAlbumFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    NSDictionary *feed = json[@"feed"];
    if (!feed) return nil;
    NSArray *entries = feed[@"entry"];
    if (!entries) return nil;
//    NSLog(@"%@", entries);
    
    NSMutableArray *albums = [NSMutableArray array];
    for (NSDictionary *entry in entries) {
        PWAlbumObject *album = [PWPicasaParser albumFromJson:entry context:context];
        [albums addObject:album];
    }
    
    return albums;
}

+ (PWAlbumObject *)albumFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    NSDictionary *gphotoid = NULL_TO_NIL(json[@"gphoto:id"]);
    NSString *id_str = NULL_TO_NIL(gphotoid[@"text"]);
    if (!id_str) return nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"PWAlbumManagedObject" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id_str", gphotoid];
    NSError *error;
    NSArray *albums = [context executeFetchRequest:request error:&error];
    for (PWAlbumObject *object in albums) {
        [context deleteObject:object];
    }
    PWAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:@"PWAlbumManagedObject" inManagedObjectContext:context];
    
    album.id_str = id_str;
#ifdef DEBUG_LOCAL
    NSLog(@"album.id_str = %@", album.id_str);
#endif
    NSDictionary *author = NULL_TO_NIL(json[@"author"]);
    if (author) {
        NSDictionary *name = NULL_TO_NIL(author[@"name"]);
        album.author_name = NULL_TO_NIL(name[@"text"]);
        NSDictionary *uri = NULL_TO_NIL(author[@"uri"]);
        album.author_url = NULL_TO_NIL(uri[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"album.author_name = %@", album.author_name);
        NSLog(@"album.author_url = %@", album.author_url);
#endif
    }
    NSDictionary *category = NULL_TO_NIL(json[@"category"]);
    if (category) {
        album.category_scheme = NULL_TO_NIL(category[@"scheme"]);
        album.category_term = NULL_TO_NIL(category[@"term"]);
#ifdef DEBUG_LOCAL
        NSLog(@"album.category_scheme = %@", album.category_scheme);
        NSLog(@"album.category_term = %@", album.category_term);
#endif
    }
    NSDictionary *published = NULL_TO_NIL(json[@"published"]);
    if (published) {
        album.published = NULL_TO_NIL(published[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"album.published = %@", album.published);
#endif
    }
    NSDictionary *rights = NULL_TO_NIL(json[@"rights"]);
    if (rights) {
        album.rights = NULL_TO_NIL(rights[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"album.rights = %@", album.rights);
#endif
    }
    NSDictionary *summary = NULL_TO_NIL(json[@"summary"]);
    if (summary) {
        album.summary = NULL_TO_NIL(summary[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"album.summary = %@", album.summary);
#endif
    }
    NSDictionary *title = NULL_TO_NIL(json[@"title"]);
    if (title) {
        album.title = NULL_TO_NIL(title[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"album.title = %@", album.title);
#endif
    }
    NSDictionary *updated = NULL_TO_NIL(json[@"updated"]);
    if (updated) {
        album.updated = NULL_TO_NIL(updated[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"album.updated = %@", album.updated);
#endif
    }
    NSArray *links = NULL_TO_NIL(json[@"link"]);
    for (NSDictionary *linkJson in links) {
        PWPhotoLinkObject *link = [PWPicasaParser linkFromJson:linkJson context:context];
        [album addLinkObject:link];
    }
    album.gphoto = [PWPicasaParser gphotoFromJson:json context:context];
    
    return album;
}

+ (PWPhotoLinkObject *)linkFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoLinkObject *link = [NSEntityDescription insertNewObjectForEntityForName:@"PWLinkManagedObject" inManagedObjectContext:context];
    
    link.href = NULL_TO_NIL(json[@"href"]);
    link.rel = NULL_TO_NIL(json[@"rel"]);
    link.type = NULL_TO_NIL(json[@"type"]);
    
#ifdef DEBUG_LOCAL
    NSLog(@"link.href = %@", link.href);
    NSLog(@"link.rel = %@", link.rel);
    NSLog(@"link.type = %@", link.type);
#endif
    
    return link;
}

+ (PWGPhotoObject *)gphotoFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWGPhotoObject *gphoto = [NSEntityDescription insertNewObjectForEntityForName:@"PWGPhotoManagedObject" inManagedObjectContext:context];
    
    NSDictionary *access = NULL_TO_NIL(json[@"gphoto:access"]);
    if (access) {
        gphoto.access = NULL_TO_NIL(access[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.access = %@", gphoto.access);
#endif
    }
    NSDictionary *albumType = NULL_TO_NIL(json[@"gphoto:albumType"]);
    if (albumType) {
        gphoto.albumType = NULL_TO_NIL(albumType[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.albumType = %@", gphoto.albumType);
#endif
    }
    NSDictionary *id_str = NULL_TO_NIL(json[@"gphoto:id"]);
    if (id_str) {
        gphoto.id_str = NULL_TO_NIL(id_str[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.id_str = %@", gphoto.id_str);
#endif
    }
    NSDictionary *name = NULL_TO_NIL(json[@"gphoto:name"]);
    if (name) {
        gphoto.name = NULL_TO_NIL(name[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.name = %@", gphoto.name);
#endif
    }
    NSDictionary *nickname = NULL_TO_NIL(json[@"gphoto:nickname"]);
    if (nickname) {
        gphoto.nickname = NULL_TO_NIL(nickname[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.nickname = %@", gphoto.nickname);
#endif
    }
    NSDictionary *numphotos = NULL_TO_NIL(json[@"gphoto:numphotos"]);
    if (numphotos) {
        gphoto.numphotos = NULL_TO_NIL(numphotos[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.numphotos = %@", gphoto.numphotos);
#endif
    }
    NSDictionary *timestamp = NULL_TO_NIL(json[@"gphoto:timestamp"]);
    if (timestamp) {
        gphoto.timestamp = NULL_TO_NIL(timestamp[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.timestamp = %@", gphoto.timestamp);
#endif
    }
    NSDictionary *user = NULL_TO_NIL(json[@"gphoto:user"]);
    if (user) {
        gphoto.user = NULL_TO_NIL(user[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"gphoto.user = %@", gphoto.user);
#endif
    }
    
    return gphoto;
}

@end
