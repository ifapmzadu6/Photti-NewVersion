//
//  ALAsset+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import ImageIO;
@import MobileCoreServices;

#import "ALAsset+methods.h"


@implementation ALAsset (methods)

- (NSData *)resizedDataWithMaxPixelSize:(NSUInteger)maxPixelSize {
    NSMutableData *resizedData = nil;
    ALAssetRepresentation *representation = self.defaultRepresentation;
    
    NSUInteger size = (NSUInteger)representation.size;
    uint8_t *buff = (uint8_t *)malloc(sizeof(uint8_t)*size);
    if(buff == nil){
        return nil;
    }
    
    NSError *error = nil;
    NSUInteger bytesRead = [representation getBytes:buff fromOffset:0 length:size error:&error];
    if (bytesRead && !error) {
        NSData *photoData = [NSData dataWithBytesNoCopy:buff length:bytesRead freeWhenDone:YES];
        
        //metadataの取得
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)photoData, nil);
        NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
        
        //リサイズ
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CGFloat width = CGImageGetWidth(imageRef);
        CGFloat height = CGImageGetHeight(imageRef);
        if (MAX(width, height) > maxPixelSize) {
            CGFloat maxAspect = maxPixelSize / MAX(width, height);
            CGSize imageSize = CGSizeMake((int)(width * maxAspect), (int)height * maxAspect);
            CGContextRef ctx = createBitmapContext(width * maxAspect, height * maxAspect);
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
        resizedData = [[NSMutableData alloc] init];
        CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)resizedData, kUTTypeJPEG, 1, nil);
        CGImageDestinationAddImage(dest, imageRef, (__bridge CFDictionaryRef)metadata);
        CFRelease(imageRef);
        CGImageDestinationFinalize(dest);
        CFRelease(dest);
    }
    if (error) {
        NSLog(@"error:%@", error);
        free(buff);
    }
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
    }
    return bitmapContext;
}

@end
