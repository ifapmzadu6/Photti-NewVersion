//
//  PWURLSession.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PWURLSession : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (NSURLSession *)sharedSession;

@end
