//
//  PAColors.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, kPAColorsTheme) {
	kPAColorsThemeDefault,
	kPAColorsThemeNight
};

typedef NS_ENUM(NSUInteger, kPAColorsType) {
	kPAColorsTypeTintWebColor,
	kPAColorsTypeTintLocalColor,
    kPAColorsTypeTintUploadColor,
    kPAColorsTypeTintDefaultColor,
	kPAColorsTypeBackgroundColor,
	kPAColorsTypeBackgroundLightColor,
	kPAColorsTypeBackgroundDarkColor,
	kPAColorsTypeTextColor,
	kPAColorsTypeTextDarkColor,
	kPAColorsTypeTextLightColor,
	kPAColorsTypeTextLightSubColor,
};

@interface PAColors : NSObject

+ (void)loadThemeColors;
+ (UIColor *)getColor:(kPAColorsType)type;
+ (void)setColor:(UIColor *)color type:(kPAColorsType)type;
+ (void)setDefaultColors;

@end
