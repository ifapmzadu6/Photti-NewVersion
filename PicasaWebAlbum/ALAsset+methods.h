//
//  ALAsset+methods.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import AssetsLibrary;

@interface ALAsset (methods)

- (NSData *)resizedDataWithMaxPixelSize:(NSUInteger)maxPixelSize;

@end
