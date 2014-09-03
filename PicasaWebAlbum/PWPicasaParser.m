//
//  PWPicasaParser.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPicasaParser.h"

#define NtN(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface PWPicasaParser ()

@end

@implementation PWPicasaParser

static NSString * const PWXMLNode = @"text";

+ (NSArray *)parseListOfAlbumFromJson:(NSDictionary *)json isDelete:(BOOL)isDelete context:(NSManagedObjectContext *)context {
    if (!json) return nil;
    //    NSLog(@"%@", json);
    
    NSDictionary *feed = NtN(json[@"feed"]);
    id entries = nil;
    if (feed) {
        entries = NtN(feed[@"entry"]);
    }
    if (!entries) {
        entries = NtN(json[@"entry"]);
    }
    if (!entries) return nil;
    
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
    NSError *error = nil;
    NSMutableArray *existingAlbums = [context executeFetchRequest:request error:&error].mutableCopy;
    
    NSMutableArray *albums = @[].mutableCopy;
    if ([entries isKindOfClass:[NSArray class]]) {
        for (NSDictionary *entry in entries) {
            PWAlbumObject *album = [PWPicasaParser albumFromJson:entry existingAlbums:existingAlbums context:context];
            [albums addObject:album];
            if ([existingAlbums containsObject:album]) {
                [existingAlbums removeObject:album];
            }
        }
    }
    else if ([entries isKindOfClass:[NSDictionary class]]) {
        PWAlbumObject *album = [PWPicasaParser albumFromJson:entries existingAlbums:existingAlbums context:context];
        [albums addObject:album];
        if ([existingAlbums containsObject:album]) {
            [existingAlbums removeObject:album];
        }
    }
    
    if (isDelete) {
        for (PWAlbumObject *albumObject in existingAlbums) {
            [context deleteObject:albumObject];
        }
    }
    
    return albums;
}

+ (PWAlbumObject *)albumFromJson:(NSDictionary *)json existingAlbums:(NSMutableArray *)existingAlbums context:(NSManagedObjectContext *)context {
    if (!json) return nil;
    //    NSLog(@"%@", json);
    
    NSDictionary *gphotoid = NtN(json[@"gphoto:id"]);
    if (!gphotoid) return nil;
    NSString *id_str = NtN(gphotoid[PWXMLNode]);
    if (!id_str) return nil;
    NSString *updated = NtN(NtN(json[@"updated"])[PWXMLNode]);
    if (!updated) return nil;
    
    NSArray *tmpExistingAlbums = [existingAlbums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
    PWAlbumObject *album = nil;
    if (tmpExistingAlbums.count > 0) {
        PWAlbumObject *existingAlbum = tmpExistingAlbums.firstObject;
        if ([updated isEqualToString:existingAlbum.updated_str]) {
            return existingAlbum;
        }
        else {
            album = existingAlbum;
        }
    }
    else {
        album = [NSEntityDescription insertNewObjectForEntityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
    }
    
    album.id_str = id_str;
    NSDictionary *author = NtN(json[@"author"]);
    if (author) {
        NSString *name = NtN(NtN(author[@"name"])[PWXMLNode]);
        if (name && ![name isEqualToString:album.author_name]) {
            album.author_name = name;
        }
        NSString *uri = NtN(NtN(author[@"uri"])[PWXMLNode]);
        if (uri && ![uri isEqualToString:album.author_url]) {
            album.author_url = uri;
        }
    }
    NSDictionary *category = NtN(json[@"category"]);
    if (category) {
        NSString *scheme = NtN(category[@"scheme"]);
        if (scheme && ![scheme isEqualToString:album.category_scheme]) {
            album.category_scheme = scheme;
        }
        NSString *term = NtN(category[@"term"]);
        if (term && ![term isEqualToString:album.category_term]) {
            album.category_term = term;
        }
    }
    NSString *published = NtN(NtN(json[@"published"])[PWXMLNode]);
    if (published && ![published isEqualToString:album.published]) {
        album.published = published;
    }
    NSString *rights = NtN(NtN(json[@"rights"])[PWXMLNode]);
    if (rights && ![rights isEqualToString:album.rights]) {
        album.rights = rights;
    }
    NSString *summary = NtN(NtN(json[@"summary"])[PWXMLNode]);
    if (summary && ![summary isEqualToString:album.summary]) {
        album.summary = summary;
    }
    NSString *title = NtN(NtN(json[@"title"])[PWXMLNode]);
    if (title && ![title isEqualToString:album.title]) {
        album.title = title;
    }
    NSArray *links = NtN(json[@"link"]);
    album.link = [NSSet set];
    for (NSDictionary *linkJson in links) {
        PWPhotoLinkObject *link = [PWPicasaParser linkFromJson:linkJson context:context];
        [album addLinkObject:link];
    }
    album.gphoto = [PWPicasaParser gphotoFromJson:json context:context];
    album.media = [PWPicasaParser mediaFromJson:NtN(json[@"media:group"]) context:context];
    
    if (album.media) {
        PWPhotoMediaThumbnailObject *thumbnail = album.media.thumbnail.firstObject;
        album.tag_thumbnail_url = thumbnail.url;
    }
    
    return album;
}

+ (NSArray *)parseListOfPhotoFromJson:(NSDictionary *)json albumID:(NSString *)albumID context:(NSManagedObjectContext *)context {
    NSDictionary *feed = NtN(json[@"feed"]);
    if (!feed) return nil;
    id entries = NtN(feed[@"entry"]);
    if (!entries) {
        entries = NtN(json[@"entry"]);
    }
    if (!entries) return nil;
    
    NSMutableArray *existingPhotos = @[].mutableCopy;
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"albumid = %@", albumID];
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    [existingPhotos addObjectsFromArray:objects];
    
    NSMutableArray *photos = [NSMutableArray array];
    if ([entries isKindOfClass:[NSArray class]]) {
        for (NSDictionary *entry in entries) {
            PWPhotoObject *photo = [PWPicasaParser photoFromJson:entry existingPhotos:existingPhotos context:context];
            if (photo) {
                [photos addObject:photo];
                if ([existingPhotos containsObject:photo]) {
                    [existingPhotos removeObject:photo];
                }
            }
        }
    }
    else if ([entries isKindOfClass:[NSDictionary class]]) {
        PWPhotoObject *photo = [PWPicasaParser photoFromJson:entries existingPhotos:existingPhotos context:context];
        if (photo) {
            [photos addObject:photo];
            if ([existingPhotos containsObject:photo]) {
                [existingPhotos removeObject:photo];
            }
        }
    }
    
    if (existingPhotos.count > 0) {
        for (PWPhotoObject *photoObject in existingPhotos) {
            [context deleteObject:photoObject];
        }
    }
    
    return photos;
}

+ (PWPhotoObject *)photoFromJson:(NSDictionary *)json existingPhotos:(NSMutableArray *)existingPhotos context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    NSDictionary *gphotoid = NtN(json[@"gphoto:id"]);
    if (!gphotoid) return nil;
    NSString *id_str = NtN(gphotoid[PWXMLNode]);
    if (!id_str) return nil;
    NSString *updated = NtN(NtN(json[@"updated"])[PWXMLNode]);
    if (!updated) return nil;
    
    PWPhotoObject *photo = nil;
    NSArray *tmpExistingPhotos = [existingPhotos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
    if (tmpExistingPhotos.count > 0) {
        PWPhotoObject *existingPhoto = tmpExistingPhotos.firstObject;
        if ([updated isEqualToString:existingPhoto.updated_str]) {
            return existingPhoto;
        }
        else {
            photo = existingPhoto;
        }
    }
    else {
        photo = [NSEntityDescription insertNewObjectForEntityForName:kPWPhotoManagedObjectName inManagedObjectContext:context];
    }
    
    NSString *albumid = NtN(NtN(json[@"gphoto:albumid"])[PWXMLNode]);
    if (albumid && ![albumid isEqualToString:photo.albumid]) {
        photo.albumid = albumid;
    }
    NSString *appEdited = NtN(NtN(json[@"app:edited"])[PWXMLNode]);
    if (appEdited && ![appEdited isEqualToString:photo.app_edited]) {
        photo.app_edited = appEdited;
    }
    NSDictionary *category = NtN(json[@"category"]);
    if (category) {
        NSString *cheme = NtN(category[@"scheme"]);
        if (cheme && ![cheme isEqualToString:photo.category_cheme]) {
            photo.category_cheme = cheme;
        }
        NSString *term = NtN(category[@"term"]);
        if (term && ![term isEqualToString:photo.category_term]) {
            photo.category_term = term;
        }
    }
    NSDictionary *content = NtN(json[@"content"]);
    if (context) {
        NSString *src = NtN(content[@"src"]);
        if (src && ![src isEqualToString:photo.content_src]) {
            photo.content_src = src;
        }
        NSString *type = NtN(content[@"type"]);
        if (type && ![type isEqualToString:photo.content_type]) {
            photo.content_type = type;
        }
    }
    photo.exif = [PWPicasaParser exifFromJson:NtN(json[@"exif:tags"]) context:context];
    
    NSString *pos = NtN(NtN(NtN(NtN(json[@"georss:where"])[@"gml:Point"])[@"gml:pos"])[PWXMLNode]);
    if (pos && ![pos isEqualToString:photo.pos]) {
        photo.pos = pos;
    }
    if (id_str && ![id_str isEqualToString:photo.id_str]) {
        photo.id_str = id_str;
    }
    id links = NtN(json[@"link"]);
    photo.link = [NSOrderedSet orderedSet];
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
    photo.media = [PWPicasaParser mediaFromJson:NtN(json[@"media:group"]) context:context];
    NSString *published = NtN(NtN(json[@"published"])[PWXMLNode]);
    if (published && ![published isEqualToString:photo.published]) {
        photo.published = published;
    }
    NSString *summary = NtN(NtN(json[@"summary"])[PWXMLNode]);
    if (summary && ![summary isEqualToString:photo.summary]) {
        photo.summary = summary;
    }
    NSString *title = NtN(NtN(json[@"title"])[PWXMLNode]);
    if (title && ![title isEqualToString:photo.title]) {
        photo.title = title;
    }
    photo.updated_str = updated;
    photo.gphoto = [PWPicasaParser gphotoFromJson:json context:context];
    
    if (photo.gphoto) {
        if (photo.gphoto.originalvideo_duration) {
            photo.tag_type = @(PWPhotoManagedObjectTypeVideo);
        }
        else {
            photo.tag_type = @(PWPhotoManagedObjectTypePhoto);
        }
    }
    
    if (photo.media) {
        PWPhotoMediaContentObject *content = photo.media.content.firstObject;
        photo.tag_screenimage_url = content.url;
        photo.tag_originalimage_url = content.url;
        
        if ([content.type isEqualToString:@"image/gif"]) {
            photo.tag_thumbnail_url = content.url;
        }
        else {
            PWPhotoMediaThumbnailObject *thumbnailObject = photo.media.thumbnail.firstObject;
            photo.tag_thumbnail_url = thumbnailObject.url;
        }
    }
    
    return photo;
}

+ (PWPhotoLinkObject *)linkFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoLinkObject *link = [NSEntityDescription insertNewObjectForEntityForName:kPWLinkManagedObjectName inManagedObjectContext:context];
    
    link.href = NtN(json[@"href"]);
    link.rel = NtN(json[@"rel"]);
    link.type = NtN(json[@"type"]);
    
    return link;
}

+ (PWGPhotoObject *)gphotoFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWGPhotoObject *gphoto = [NSEntityDescription insertNewObjectForEntityForName:kPWGPhotoManagedObjectName inManagedObjectContext:context];
    
    NSString *access = NtN(NtN(json[@"gphoto:access"])[PWXMLNode]);
    if (access && ![access isEqualToString:gphoto.access]) {
        gphoto.access = access;
    }
    NSString *albumType = NtN(NtN(json[@"gphoto:albumType"])[PWXMLNode]);
    if (albumType && ![albumType isEqualToString:gphoto.albumType]) {
        gphoto.albumType = albumType;
    }
    NSString *id_str = NtN(NtN(json[@"gphoto:id"])[PWXMLNode]);
    if (id_str && ![id_str isEqualToString:gphoto.name]) {
        gphoto.id_str = id_str;
    }
    NSString *name = NtN(NtN(json[@"gphoto:name"])[PWXMLNode]);
    if (name && ![name isEqualToString:gphoto.name]) {
        gphoto.name = name;
    }
    NSString *nickname = NtN(NtN(json[@"gphoto:nickname"])[PWXMLNode]);
    if (nickname && ![nickname isEqualToString:gphoto.nickname]) {
        gphoto.nickname = nickname;
    }
    NSString *numphotos = NtN(NtN(json[@"gphoto:numphotos"])[PWXMLNode]);
    if (numphotos && ![numphotos isEqualToString:gphoto.numphotos]) {
        gphoto.numphotos = numphotos;
    }
    NSString *timestamp = NtN(NtN(json[@"gphoto:timestamp"])[PWXMLNode]);
    if (timestamp && ![timestamp isEqualToString:gphoto.timestamp]) {
        gphoto.timestamp = timestamp;
    }
    NSString *user = NtN(NtN(json[@"gphoto:user"])[PWXMLNode]);
    if (user && ![user isEqualToString:user]) {
        gphoto.user = user;
    }
    NSDictionary *originalvideo = NtN(json[@"gphoto:originalvideo"]);
    if (originalvideo) {
        gphoto.originalvideo_audioCodec = NtN(originalvideo[@"audioCodec"]);
        gphoto.originalvideo_channels = NtN(originalvideo[@"channels"]);
        gphoto.originalvideo_duration = NtN(originalvideo[@"duration"]);
        gphoto.originalvideo_fps = NtN(originalvideo[@"fps"]);
        gphoto.originalvideo_height = NtN(originalvideo[@"height"]);
        gphoto.originalvideo_samplingrate = NtN(originalvideo[@"samplingrate"]);
        gphoto.originalvideo_type = NtN(originalvideo[@"type"]);
        gphoto.originalvideo_videoCodec = NtN(originalvideo[@"videoCodec"]);
        gphoto.originalvideo_width = NtN(originalvideo[@"width"]);
    }
    NSString *size = NtN(NtN(json[@"gphoto:size"])[PWXMLNode]);
    if (size) {
        gphoto.size = @(size.integerValue);
    }
    NSString *width = NtN(NtN(json[@"gphoto:width"])[PWXMLNode]);
    if (width) {
        gphoto.width = @(width.integerValue);
    }
    NSString *height = NtN(NtN(json[@"gphoto:height"])[PWXMLNode]);
    if (height) {
        gphoto.height = @(height.integerValue);
    }
    
    return gphoto;
}

+ (PWPhotoMediaObject *)mediaFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
    //    NSLog(@"%@", json);
    
    PWPhotoMediaObject *media = [NSEntityDescription insertNewObjectForEntityForName:kPWMediaManagedObjectName inManagedObjectContext:context];
    
    id contents = NtN(json[@"media:content"]);
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
    NSString *credit = NtN(NtN(json[@"media:credit"])[PWXMLNode]);
    if (credit && ![credit isEqualToString:media.credit]) {
        media.credit = credit;
    }
    NSString *description = NtN(NtN(json[@"media:description"])[PWXMLNode]);
    if (description && ![description isEqualToString:media.description]) {
        media.description_text = description;
    }
    NSString *keywords = NtN(NtN(json[@"media:keywords"])[PWXMLNode]);
    if (keywords && ![keywords isEqualToString:media.keywords]) {
        media.keywords = keywords;
    }
    id thumbnails = NtN(json[@"media:thumbnail"]);
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
    NSString *title = NtN(NtN(json[@"media:title"])[PWXMLNode]);
    if (title && ![title isEqualToString:media.title]) {
        media.title = title;
    }
    
    return media;
}

+ (PWPhotoMediaContentObject *)mediaContentFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoMediaContentObject *content = [NSEntityDescription insertNewObjectForEntityForName:kPWMediaContentManagedObjectName inManagedObjectContext:context];
    
    NSString *height = NtN(json[@"height"]);
    if (height) {
        content.height = @(height.integerValue);
    }
    content.medium = NtN(json[@"medium"]);
    content.type = NtN(json[@"type"]);
    content.url = NtN(json[@"url"]);
    NSString *width = NtN(json[@"width"]);
    if (width) {
        content.width = @(width.integerValue);
    }
    
    return content;
}

+ (PWPhotoMediaThumbnailObject *)mediaThumbnailFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
//    NSLog(@"%@", json);
    
    PWPhotoMediaThumbnailObject *thumbnail = [NSEntityDescription insertNewObjectForEntityForName:kPWMediaThumbnailManagedObjectName inManagedObjectContext:context];
    
    NSString *height = NtN(json[@"height"]);
    if (height) {
        thumbnail.height = [NSNumber numberWithInteger:height.integerValue];
    }
    NSString *width = NtN(json[@"width"]);
    if (width) {
        thumbnail.width = [NSNumber numberWithInteger:width.integerValue];
    }
    thumbnail.url = NtN(json[@"url"]);
    
    return thumbnail;
}

+ (PWPhotoExitObject *)exifFromJson:(NSDictionary *)json context:(NSManagedObjectContext *)context {
    if (!json) return nil;
    //    NSLog(@"%@", json);
    
    PWPhotoExitObject *exif = [NSEntityDescription insertNewObjectForEntityForName:kPWPhotoExitManagedObjectName inManagedObjectContext:context];
    
    NSString *distance = NtN(NtN(json[@"exif:distance"])[PWXMLNode]);
    if (distance && ![distance isEqualToString:exif.distance]) {
        exif.distance = distance;
    }
    NSString *exposure = NtN(NtN(json[@"exif:exposure"])[PWXMLNode]);
    if (exposure && ![exposure isEqualToString:exif.exposure]) {
        exif.exposure = exposure;
    }
    NSString *flash = NtN(NtN(json[@"exif:flash"])[PWXMLNode]);
    if (flash && ![flash isEqualToString:exif.flash]) {
        exif.flash = flash;
    }
    NSString *focallength = NtN(NtN(json[@"exif:focallength"])[PWXMLNode]);
    if (focallength && ![focallength isEqualToString:exif.focallength]) {
        exif.focallength = focallength;
    }
    NSString *fstop = NtN(NtN(json[@"exif:fstop"])[PWXMLNode]);
    if (fstop && ![fstop isEqualToString:exif.fstop]) {
        exif.fstop = fstop;
    }
    NSString *imageUniqueID = NtN(NtN(json[@"exif:imageUniqueID"])[PWXMLNode]);
    if (imageUniqueID && ![imageUniqueID isEqualToString:exif.imageUniqueID]) {
        exif.imageUniqueID = imageUniqueID;
    }
    NSString *iso = NtN(NtN(json[@"exif:iso"])[PWXMLNode]);
    if (iso && ![iso isEqualToString:exif.iso]) {
        exif.iso = iso;
    }
    NSString *make = NtN(NtN(json[@"exif:make"])[PWXMLNode]);
    if (make && ![make isEqualToString:exif.make]) {
        exif.make = make;
    }
    NSString *model = NtN(NtN(json[@"exif:model"])[PWXMLNode]);
    if (model && ![model isEqualToString:exif.model]) {
        exif.model = model;
    }
    NSString *time = NtN(NtN(json[@"exif:time"])[PWXMLNode]);
    if (time && ![time isEqualToString:exif.time]) {
        exif.time = time;
    }
    
    return exif;
}

@end
