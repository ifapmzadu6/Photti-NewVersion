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
    
    NSDictionary *feed = NULL_TO_NIL(json[@"feed"]);
    if (!feed) return nil;
    id entries = NULL_TO_NIL(feed[@"entry"]);
    if (!entries) return nil;
    
    NSMutableArray *albums = [NSMutableArray array];
    if ([entries isKindOfClass:[NSArray class]]) {
        for (NSDictionary *entry in entries) {
            PWAlbumObject *album = [PWPicasaParser albumFromJson:entry context:context];
            [albums addObject:album];
        }
    }
    else if ([entries isKindOfClass:[NSDictionary class]]) {
        PWAlbumObject *album = [PWPicasaParser albumFromJson:entries context:context];
        [albums addObject:album];
    }
    
    return albums;
}

+ (PWAlbumObject *)albumFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    NSDictionary *gphotoid = NULL_TO_NIL(json[@"gphoto:id"]);
    if (!gphotoid) return nil;
    NSString *id_str = NULL_TO_NIL(gphotoid[@"text"]);
    if (!id_str) return nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
    NSError *error;
    NSArray *albums = [context executeFetchRequest:request error:&error];
    for (PWAlbumObject *object in albums) {
        [context deleteObject:object];
    }
    PWAlbumObject *album = [NSEntityDescription insertNewObjectForEntityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
    
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
    NSDictionary *media = NULL_TO_NIL(json[@"media:group"]);
    if (media) {
        album.media = [PWPicasaParser mediaFromJson:media context:context];
    }
    
    return album;
}

+ (NSArray *)parseListOfPhotoFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    NSDictionary *feed = NULL_TO_NIL(json[@"feed"]);
    if (!feed) return nil;
    id entries = NULL_TO_NIL(feed[@"entry"]);
    if (!entries) return nil;
    
    NSMutableArray *photos = [NSMutableArray array];
    if ([entries isKindOfClass:[NSArray class]]) {
        for (NSDictionary *entry in entries) {
            PWPhotoObject *album = [PWPicasaParser photoFromJson:entry context:context];
            [photos addObject:album];
        }
    }
    else if ([entries isKindOfClass:[NSDictionary class]]) {
        PWPhotoObject *album = [PWPicasaParser photoFromJson:entries context:context];
        [photos addObject:album];
    }
    
    return photos;
}

+ (PWPhotoObject *)photoFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    NSDictionary *gphotoid = NULL_TO_NIL(json[@"gphoto:id"]);
    if (!gphotoid) return nil;
    NSString *id_str = NULL_TO_NIL(gphotoid[@"text"]);
    if (!id_str) return nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
    NSError *error;
    NSArray *photos = [context executeFetchRequest:request error:&error];
    for (PWPhotoObject *object in photos) {
        [context deleteObject:object];
    }
    PWPhotoObject *photo = [NSEntityDescription insertNewObjectForEntityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    
    NSDictionary *albumid = NULL_TO_NIL(json[@"gphoto:albumid"]);
    if (albumid) {
        photo.albumid = NULL_TO_NIL(albumid[@"text"]);
    }
    NSDictionary *appEdited = NULL_TO_NIL(json[@"app:edited"]);
    if (appEdited) {
        photo.app_edited = NULL_TO_NIL(appEdited[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"photo.app_edited = %@", photo.app_edited);
#endif
    }
    NSDictionary *category = NULL_TO_NIL(json[@"category"]);
    if (category) {
        photo.category_cheme = NULL_TO_NIL(category[@"scheme"]);
        photo.category_term = NULL_TO_NIL(category[@"term"]);
#ifdef DEBUG_LOCAL
        NSLog(@"photo.category_cheme = %@", photo.category_cheme);
        NSLog(@"photo.category_term = %@", photo.category_term);
#endif
    }
    NSDictionary *content = NULL_TO_NIL(json[@"content"]);
    if (context) {
        photo.content_src = NULL_TO_NIL(content[@"src"]);
        photo.content_type = NULL_TO_NIL(content[@"type"]);
#ifdef DEBUG_LOCAL
        NSLog(@"photo.content_src = %@", photo.content_src);
        NSLog(@"photo.content_type = %@", photo.content_type);
#endif
    }
    NSDictionary *exifTags = NULL_TO_NIL(json[@"exif:tags"]);
    if (exifTags) {
        photo.exif = [PWPicasaParser exifFromJson:exifTags context:context];
    }
    NSDictionary *georssWhere = NULL_TO_NIL(json[@"georss:where"]);
    if (georssWhere) {
        NSDictionary *gmlPoint = NULL_TO_NIL(georssWhere[@"gml:Point"]);
        if (gmlPoint) {
            NSDictionary *gmlPos = NULL_TO_NIL(gmlPoint[@"gml:pos"]);
            if (gmlPos) {
                photo.pos = NULL_TO_NIL(gmlPos[@"text"]);
#ifdef DEBUG_LOCAL
                NSLog(@"photo.pos = %@", photo.pos);
#endif
            }
        }
    }
    if (id_str) {
        photo.id_str = id_str;
#ifdef DEBUG_LOCAL
        NSLog(@"photo.id_str = %@", photo.id_str);
#endif
    }
    id links = NULL_TO_NIL(json[@"link"]);
    if ([links isKindOfClass:[NSArray class]]) {
        for (NSDictionary *linkJson in links) {
            PWPhotoLinkObject *link = [PWPicasaParser linkFromJson:linkJson context:context];
            [photo addLinkObject:link];
        }
    }
    else if ([links isKindOfClass:[NSDictionary class]]) {
        PWPhotoLinkObject *link = [PWPicasaParser linkFromJson:links context:context];
        [photo addLinkObject:link];
    }
    NSDictionary *media = NULL_TO_NIL(json[@"media:group"]);
    if (media) {
        photo.media = [PWPicasaParser mediaFromJson:media context:context];
    }
    NSDictionary *published = NULL_TO_NIL(json[@"published"]);
    if (published) {
        photo.published = NULL_TO_NIL(published[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"photo.published = %@", photo.published);
#endif
    }
    NSDictionary *summary = NULL_TO_NIL(json[@"summary"]);
    if (summary) {
        photo.summary = NULL_TO_NIL(summary[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"photo.summary = %@", photo.summary);
#endif
    }
    NSDictionary *title = NULL_TO_NIL(json[@"title"]);
    if (title) {
        photo.title = NULL_TO_NIL(title[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"photo.title = %@", photo.title);
#endif
    }
    NSDictionary *updated = NULL_TO_NIL(json[@"updated"]);
    if (updated) {
        photo.updated = NULL_TO_NIL(updated[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"photo.updated = %@", photo.updated);
#endif
    }
    
    return photo;
}

+ (PWPhotoLinkObject *)linkFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoLinkObject *link = [NSEntityDescription insertNewObjectForEntityForName:kPWLinkManagedObjectName inManagedObjectContext:context];
    
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
    
    PWGPhotoObject *gphoto = [NSEntityDescription insertNewObjectForEntityForName:kPWGPhotoManagedObjectName inManagedObjectContext:context];
    
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

+ (PWPhotoMediaObject *)mediaFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoMediaObject *media = [NSEntityDescription insertNewObjectForEntityForName:kPWMediaManagedObjectName inManagedObjectContext:context];
    
    id contents = NULL_TO_NIL(json[@"media:content"]);
    if ([contents isKindOfClass:[NSArray class]]) {
        for (NSDictionary *contentJson in contents) {
            PWPhotoMediaContentObject *content = [PWPicasaParser mediaContentFromJson:contentJson context:context];
            [media addContentObject:content];
        }
    }
    else if ([contents isKindOfClass:[NSDictionary class]]) {
        PWPhotoMediaContentObject *content = [PWPicasaParser mediaContentFromJson:contents context:context];
        [media addContentObject:content];
    }
    NSDictionary *credit = NULL_TO_NIL(json[@"media:credit"]);
    if (credit) {
        media.credit = NULL_TO_NIL(credit[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"media.credit = %@", media.credit);
#endif
    }
    NSDictionary *description = NULL_TO_NIL(json[@"media:description"]);
    if (description) {
        media.description_text = NULL_TO_NIL(description[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"media.description_text = %@", media.description_text);
#endif
    }
    NSDictionary *keywords = NULL_TO_NIL(json[@"media:keywords"]);
    if (keywords) {
        media.keywords = NULL_TO_NIL(keywords[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"media.keywords = %@", media.keywords);
#endif
    }
    id thumbnails = NULL_TO_NIL(json[@"media:thumbnail"]);
    if ([thumbnails isKindOfClass:[NSArray class]]) {
        for (NSDictionary *thumbnailJson in thumbnails) {
            PWPhotoMediaThumbnailObject *thumbnail = [PWPicasaParser mediaThumbnailFromJson:thumbnailJson context:context];
            [media addThumbnailObject:thumbnail];
        }
    }
    else if ([thumbnails isKindOfClass:[NSDictionary class]]) {
        PWPhotoMediaThumbnailObject *thumbnail = [PWPicasaParser mediaThumbnailFromJson:thumbnails context:context];
        [media addThumbnailObject:thumbnail];
    }
    NSDictionary *title = NULL_TO_NIL(json[@"media:title"]);
    if (title) {
        media.title = NULL_TO_NIL(title[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"media.title = %@", media.title);
#endif
    }
    
    return media;
}

+ (PWPhotoMediaContentObject *)mediaContentFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoMediaContentObject *content = [NSEntityDescription insertNewObjectForEntityForName:kPWMediaContentManagedObjectName inManagedObjectContext:context];
    
    NSString *height = NULL_TO_NIL(json[@"height"]);
    content.height = [NSNumber numberWithInteger:[height integerValue]];
    content.medium = NULL_TO_NIL(json[@"medium"]);
    content.type = NULL_TO_NIL(json[@"type"]);
    content.url = NULL_TO_NIL(json[@"url"]);
    NSString *width = NULL_TO_NIL(json[@"width"]);
    content.width = [NSNumber numberWithInteger:[width integerValue]];
    
#ifdef DEBUG_LOCAL
    NSLog(@"content.height = %@", content.height);
    NSLog(@"content.medium = %@", content.medium);
    NSLog(@"content.type = %@", content.type);
    NSLog(@"content.url = %@", content.url);
    NSLog(@"content.width = %@", content.width);
#endif
    
    return content;
}

+ (PWPhotoMediaThumbnailObject *)mediaThumbnailFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoMediaThumbnailObject *thumbnail = [NSEntityDescription insertNewObjectForEntityForName:kPWMediaThumbnailManagedObjectName inManagedObjectContext:context];
    
    NSString *height = NULL_TO_NIL(json[@"height"]);
    thumbnail.height = [NSNumber numberWithInteger:[height integerValue]];
    NSString *width = NULL_TO_NIL(json[@"width"]);
    thumbnail.width = [NSNumber numberWithInteger:[width integerValue]];
    thumbnail.url = NULL_TO_NIL(json[@"url"]);
    
#ifdef DEBUG_LOCAL
    NSLog(@"thumbnail.height = %@", thumbnail.height);
    NSLog(@"thumbnail.width = %@", thumbnail.width);
    NSLog(@"thumbnail.url = %@", thumbnail.url);
#endif
    
    return thumbnail;
}

+ (PWPhotoExitObject *)exifFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoExitObject *exif = [NSEntityDescription insertNewObjectForEntityForName:kPWPhotoExitManagedObjectName inManagedObjectContext:context];
    
    NSDictionary *distance = NULL_TO_NIL(json[@"exif:distance"]);
    if (distance) {
        exif.distance = NULL_TO_NIL(distance[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.distance = %@", exif.distance);
#endif
    }
    NSDictionary *exposure = NULL_TO_NIL(json[@"exif:exposure"]);
    if (exposure) {
        exif.exposure = NULL_TO_NIL(exposure[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.exposure = %@", exif.exposure);
#endif
    }
    NSDictionary *flash = NULL_TO_NIL(json[@"exif:flash"]);
    if (flash) {
        exif.flash = NULL_TO_NIL(flash[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.flash = %@", exif.flash);
#endif
    }
    NSDictionary *focallength = NULL_TO_NIL(json[@"exif:focallength"]);
    if (focallength) {
        exif.focallength = NULL_TO_NIL(focallength[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.focallength = %@", exif.focallength);
#endif
    }
    NSDictionary *fstop = NULL_TO_NIL(json[@"exif:fstop"]);
    if (fstop) {
        exif.fstop = NULL_TO_NIL(fstop[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.fstop = %@", exif.fstop);
#endif
    }
    NSDictionary *imageUniqueID = NULL_TO_NIL(json[@"exif:imageUniqueID"]);
    if (imageUniqueID) {
        exif.imageUniqueID = NULL_TO_NIL(imageUniqueID[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.imageUniqueID = %@", exif.imageUniqueID);
#endif
    }
    NSDictionary *iso = NULL_TO_NIL(json[@"exif:iso"]);
    if (iso) {
        exif.iso = NULL_TO_NIL(iso[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.iso = %@", exif.iso);
#endif
    }
    NSDictionary *make = NULL_TO_NIL(json[@"exif:make"]);
    if (make) {
        exif.make = NULL_TO_NIL(make[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.make = %@", exif.make);
#endif
    }
    NSDictionary *model = NULL_TO_NIL(json[@"exif:model"]);
    if (model) {
        exif.model = NULL_TO_NIL(model[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.model = %@", exif.model);
#endif
    }
    NSDictionary *time = NULL_TO_NIL(json[@"exif:time"]);
    if (time) {
        exif.time = NULL_TO_NIL(time[@"text"]);
#ifdef DEBUG_LOCAL
        NSLog(@"exif.time = %@", exif.time);
#endif
    }
    
    return exif;
}

@end
