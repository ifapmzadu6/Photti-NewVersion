//
//  PWTabBarController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PWTabBarController : UITabBarController <UITabBarControllerDelegate>

- (UIEdgeInsets)viewInsets;
- (BOOL)isTabBarHidden;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (BOOL)isToolbarHideen;
- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated;
- (void)setActionToolbarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (BOOL)isActionToolbarHidden;
- (void)setActionToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated;
- (void)setActionNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setActionNavigationItem:(UINavigationItem *)item animated:(BOOL)animated;

@end
