//
//  PWString.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/12.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PAString : NSObject

+ (NSString *)itemNameFromPhotoCount:(NSUInteger)photoCount videoCount:(NSUInteger)videoCount;

+ (NSString *)photoAndVideoStringWithPhotoCount:(NSUInteger)photoCount videoCount:(NSUInteger)videoCount;
+ (NSString *)photoAndVideoStringWithPhotoCount:(NSUInteger)photoCount videoCount:(NSUInteger)videoCount isInitialUpperCase:(BOOL)isInitialUpperCase;

@end
