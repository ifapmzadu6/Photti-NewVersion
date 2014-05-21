//
//  PLAssetsManager.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import AssetsLibrary;
@import MapKit;

@interface PLAssetsManager : NSObject

+ (id)sharedManager;

+ (ALAssetsLibrary *)sharedLibrary;

- (void)enumurateAssetsWithCompletion:(void (^)(NSArray *albums))completion;

@end
