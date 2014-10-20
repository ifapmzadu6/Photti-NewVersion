//
//  PAResizeData.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAResizeData.h"

@import ImageIO;
@import MobileCoreServices;

@implementation PAResizeData

+ (NSData *)resizedDataWithImageData:(NSData *)imageData maxPixelSize:(NSUInteger)maxPixelSize {
    //metadataの取得
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil);
    NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
    
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
            imageRef = CGBitmapContextCreateImage(ctx);
            void *bitmapData = CGBitmapContextGetData(ctx);
            if (bitmapData) {
                free(bitmapData);
            }
            CGContextRelease(ctx);
        }
    }
    CFRelease(imageSource);
    
    //metadataの埋め込み
    NSData *resizedData = [NSMutableData new];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)resizedData, kUTTypeJPEG, 1, nil);
    CGImageDestinationAddImage(dest, imageRef, (__bridge CFDictionaryRef)metadata);
    CFRelease(imageRef);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
    
    return resizedData;
}

CGContextRef createBitmapContext (int pixelsWide, int pixelsHigh) {
    CGContextRef bitmapContext = NULL;
    void *bitmapData = NULL;
    CGColorSpaceRef colorSpace = NULL;
    
    bitmapData = calloc(1, pixelsWide * pixelsHigh * 4);
    if (bitmapData) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapContext = CGBitmapContextCreate(bitmapData, pixelsWide, pixelsHigh, 8, pixelsWide * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        if (!bitmapContext) {
            free(bitmapData);
        }
        CGColorSpaceRelease(colorSpace);
    }
    return bitmapContext;
}

@end
