//
//  PAGradientView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, kPAGradientViewDirection) {
    kPAGradientViewDirectionTopToBottom,
    kPAGradientViewDirectionBottomToTop,
    kPAGradientViewDirectionLeftToRight,
    kPAGradientViewDirectionRightToLeft
};

@interface PAGradientView : UIView

@property (nonatomic) kPAGradientViewDirection direction;   // default: TopToBottom

@property (strong, nonatomic) UIColor *startColor;
@property (strong, nonatomic) UIColor *endColor;

@end
