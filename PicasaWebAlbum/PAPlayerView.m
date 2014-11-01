//
//  PAPlayerView.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAPlayerView.h"

@import AVFoundation;

@implementation PAPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end
