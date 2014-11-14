//
//  PAResizeData.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAImageResize.h"

@import ImageIO;
@import MobileCoreServices;

@implementation PAImageResize

+ (NSData *)resizedDataWithImageData:(NSData *)imageData maxPixelSize:(NSUInteger)maxPixelSize {
    if (!imageData) {
        return nil;
    }
    
    //metadataの取得
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil);
    NSDictionary *metadata = (__bridge_transfer  NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
    
    //リサイズ
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    if (MAX(width, height) > maxPixelSize) {
        CGFloat maxAspect = maxPixelSize / MAX(width, height);
        CGSize imageSize = CGSizeMake((int)(width * maxAspect), (int)height * maxAspect);
        CGContextRef ctx = createBitmapContext((int)(width*maxAspect), (int)(height*maxAspect));
        if (ctx) {
            CGImageRef sourceImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, 0);
            CGContextDrawImage(ctx, (CGRect){.origin = CGPointZero, .size = imageSize}, sourceImageRef);
            CGImageRelease(imageRef);
            imageRef = CGBitmapContextCreateImage(ctx);
            CGImageRelease(sourceImageRef);
            CGContextRelease(ctx);
        }
    }
    CFRelease(imageSource);
    
    //metadataの埋め込み
    NSData *resizedData = [NSMutableData new];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)resizedData, kUTTypeJPEG, 1, nil);
    CGImageDestinationAddImage(dest, imageRef, (__bridge CFDictionaryRef)metadata);
    CGImageRelease(imageRef);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
    
    return resizedData;
}

+ (UIImage *)imageFromFileUrl:(NSURL *)url maxPixelSize:(NSInteger)maxPixelSize {
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSourceRef, 0, (__bridge CFDictionaryRef) @{(NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES, (NSString *)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize), (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES});
    CFRelease(imageSourceRef);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

CGContextRef createBitmapContext(int pixelsWide, int pixelsHigh) {
    CGContextRef bitmapContext = NULL;
    
    void *bitmapData = calloc(1, pixelsWide * pixelsHigh * 4);
    if (bitmapData) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapContext = CGBitmapContextCreate(bitmapData, pixelsWide, pixelsHigh, 8, pixelsWide * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        if (!bitmapContext) {
            free(bitmapData);
        }
        CGColorSpaceRelease(colorSpace);
    }
    return bitmapContext;
}

+ (UIImage *)resizeImage:(UIImage *)image maxPixelSize:(NSUInteger)maxPixelSize {
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat scale = (imageWidth > imageHeight ? maxPixelSize/imageHeight : maxPixelSize/imageWidth);
    
    CGSize resizedSize = CGSizeMake(imageWidth * scale, imageHeight * scale);
    UIGraphicsBeginImageContext(resizedSize);
    [image drawInRect:CGRectMake(0, 0, resizedSize.width, resizedSize.height)];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

@end
