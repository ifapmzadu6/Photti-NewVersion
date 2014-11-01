//
//  PAPhotoKit.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

@interface PAPhotoKit : NSObject

+ (PHAssetCollection *)getAssetCollectionWithIdentifier:(NSString *)identifier;

+ (PHAsset *)getAssetWithIdentifier:(NSString *)identifier;

@end
