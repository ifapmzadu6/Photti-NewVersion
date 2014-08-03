//
//  PWTabBarController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PWTabBarController : UITabBarController

@property (nonatomic, readonly) BOOL isTabBarHidden;
@property (nonatomic, readonly) BOOL isToolbarHideen;
@property (nonatomic, readonly) BOOL isActionToolbarHidden;
@property (nonatomic, readonly) BOOL isAdsHidden;

- (UIEdgeInsets)viewInsets;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setToolbarFadeout:(BOOL)fadeout animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated;
- (void)setToolbarTintColor:(UIColor *)tintColor;
- (void)setActionToolbarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setActionToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated;
- (void)setActionToolbarTintColor:(UIColor *)tintColor;
- (void)setActionNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setActionNavigationItem:(UINavigationItem *)item animated:(BOOL)animated;
- (void)setActionNavigationTintColor:(UIColor *)tintColor;

- (void)setUserInteractionEnabled:(BOOL)enabled;

- (void)setAdsHidden:(BOOL)hidden animated:(BOOL)animated;

@end
