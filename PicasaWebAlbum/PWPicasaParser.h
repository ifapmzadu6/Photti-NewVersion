//
//  PWPicasaParser.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/05.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

#import "PWModelObject.h"

@interface PWPicasaParser : NSObject

+ (NSArray *)parseListOfAlbumFromJson:(NSDictionary *)json isDelete:(BOOL)isDelete context:(NSManagedObjectContext *)context;

+ (PWAlbumObject *)albumFromJson:(NSDictionary *)json existingAlbums:(NSMutableArray *)existingAlbums context:(NSManagedObjectContext *)context;

+ (NSArray *)parseListOfPhotoFromJson:(NSDictionary *)json albumID:(NSString *)albumID context:(NSManagedObjectContext *)context;

@end
