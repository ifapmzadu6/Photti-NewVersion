//
//  PHScrollBannerView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PEScrollBannerView : UIView

@property (strong, nonatomic) NSArray *views;
@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic) BOOL shouldAnimate;
@property (nonatomic) CGFloat animateInterval;  // default: 10 sec

@end
