//
//  PLParallelNavigationTitleView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PLParallelNavigationTitleView : UIView

@property (copy, nonatomic) NSString *(^titleBeforeCurrentTitle)(NSString *currentTitle);
@property (copy, nonatomic) NSString *(^titleAfterCurrentTitle)(NSString *currentTitle);
@property (nonatomic) BOOL isDisableLayoutSubViews;
@property (strong, nonatomic) UIColor *titleTextColor;

- (void)setScrollRate:(CGFloat)rate;
- (void)setNumberOfPages:(NSUInteger)numberOfPages;
- (void)setCurrentIndex:(NSUInteger)index;
- (void)setCurrentTitle:(NSString *)title;

@end
