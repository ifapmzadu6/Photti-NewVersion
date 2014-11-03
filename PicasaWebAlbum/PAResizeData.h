//
//  PAResizeData.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface PAResizeData : NSObject

+ (NSData *)resizedDataWithImageData:(NSData *)imageData maxPixelSize:(NSUInteger)maxPixelSize;

+ (UIImage *)imageFromFileUrl:(NSURL *)fileUrl maxPixelSize:(NSInteger)maxPixelSize;

@end
