//
//  PWTabBarAdsController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PATabBarController.h"

static NSString * const kPWTabBarAdsControllerAdUnitID = @"ca-app-pub-9347360948699796/7365185266";

@interface PATabBarAdsController : PATabBarController

@property (nonatomic) BOOL isRemoveAdsAddonPurchased;
@property (nonatomic, readonly) BOOL isAdsHidden;
@property (nonatomic, readonly) CGFloat adViewHeight;

- (id)initWithIndex:(NSUInteger)index viewControllers:(NSArray *)viewControllers colors:(NSArray *)colors isRemoveAdsAddonPurchased:(BOOL)isRemoveAdsAddonPurchased;

- (void)setAdsHidden:(BOOL)hidden animated:(BOOL)animated;

@end
