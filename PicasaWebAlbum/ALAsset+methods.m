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

#import "PAResizeData.h"


@implementation ALAsset (methods)

- (NSData *)resizedDataWithMaxPixelSize:(NSUInteger)maxPixelSize {
    NSData *resizedData = nil;
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
        resizedData = [PAResizeData resizedDataWithImageData:photoData maxPixelSize:maxPixelSize];
    }
    if (error) {
#ifdef DEBUG
        NSLog(@"error:%@", error);
#endif
        free(buff);
    }
    return resizedData;
}

@end
