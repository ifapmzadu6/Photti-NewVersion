//
//  PLParallelNavigationTitleView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PLParallelNavigationTitleView : UIView

@property (strong, nonatomic) NSString *(^titleBeforeCurrentTitle)(NSString *currentTitle);
@property (strong, nonatomic) NSString *(^titleAfterCurrentTitle)(NSString *currentTitle);

- (void)setScrollRate:(CGFloat)rate;
- (void)setNumberOfPages:(NSUInteger)numberOfPages;
- (void)setCurrentIndex:(NSUInteger)index;
- (void)setCurrentTitle:(NSString *)title;

@end
