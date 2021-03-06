//
//  PABaseViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/27.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import <GAITrackedViewController.h>

@interface PABaseViewController : GAITrackedViewController

@property (nonatomic, readonly) BOOL isPhone;
@property (nonatomic, readonly) BOOL isLandscape;

- (void)refreshNoItemWithNumberOfItem:(NSUInteger)numberOfItem;
- (void)showNoItem;
- (void)hideNoItem;
- (void)layoutNoItem;

@property (strong, nonatomic) NSObject<UINavigationControllerDelegate> *navigationControllerTransition;

@end
