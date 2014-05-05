//
//  PWGPhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, PWPhotoObject;

@interface PWGPhotoObject : NSManagedObject

@property (nonatomic, retain) NSString * access;
@property (nonatomic, retain) NSString * albumid;
@property (nonatomic, retain) NSString * albumType;
@property (nonatomic, retain) NSNumber * allowDownloads;
@property (nonatomic, retain) NSNumber * allowPrints;
@property (nonatomic, retain) NSNumber * bytesUsed;
@property (nonatomic, retain) NSString * checksum;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSNumber * commentingEnabled;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSNumber * imageVersion;
@property (nonatomic, retain) NSString * license_id;
@property (nonatomic, retain) NSString * license_name;
@property (nonatomic, retain) NSString * license_text;
@property (nonatomic, retain) NSString * license_url;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * numphotos;
@property (nonatomic, retain) NSNumber * numphotosremaining;
@property (nonatomic, retain) NSString * originalvideo_audioCodec;
@property (nonatomic, retain) NSNumber * originalvideo_channels;
@property (nonatomic, retain) NSNumber * originalvideo_duration;
@property (nonatomic, retain) NSNumber * originalvideo_fps;
@property (nonatomic, retain) NSNumber * originalvideo_height;
@property (nonatomic, retain) NSNumber * originalvideo_samplingrate;
@property (nonatomic, retain) NSString * originalvideo_type;
@property (nonatomic, retain) NSString * originalvideo_videoCodec;
@property (nonatomic, retain) NSNumber * originalvideo_width;
@property (nonatomic, retain) NSString * shapes;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * streamId;
@property (nonatomic, retain) NSString * timestamp;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * videostatus;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) Album *album;
@property (nonatomic, retain) PWPhotoObject *photo;

@end
