//
//  PWTabBarController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

static const CGFloat animationDuration = 0.25f;

@interface PATabBarController : UITabBarController

@property (nonatomic, readonly) BOOL isTabBarHidden;
@property (nonatomic, readonly) BOOL isToolbarHideen;
@property (nonatomic, readonly) BOOL isActionToolbarHidden;
@property (nonatomic, readonly) BOOL isActionNavigationBarHidden;
@property (nonatomic, readonly) UIEdgeInsets viewInsets;
@property (nonatomic, readonly) CGFloat tabBarHeight;
@property (nonatomic, readonly) CGFloat navigationBarHeight;
@property (nonatomic, readonly) BOOL isPhone;
@property (nonatomic, readonly) BOOL isLandscape;

- (id)initWithIndex:(NSUInteger)index viewControllers:(NSArray *)viewControllers colors:(NSArray *)colors;
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

@end
