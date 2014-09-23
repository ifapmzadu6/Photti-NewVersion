//
//  PAColors.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

typedef enum _PAColorsTheme {
	PAColorsThemeDefault,
	PAColorsThemeNight
} PAColorsTheme;

typedef enum _PAColorsType {
	PAColorsTypeTintWebColor,
	PAColorsTypeTintLocalColor,
    PAColorsTypeTintUploadColor,
    PAColorsTypeTintDefaultColor,
	PAColorsTypeBackgroundColor,
	PAColorsTypeBackgroundLightColor,
	PAColorsTypeBackgroundDarkColor,
	PAColorsTypeTextColor,
	PAColorsTypeTextDarkColor,
	PAColorsTypeTextLightColor,
	PAColorsTypeTextLightSubColor,
} PAColorsType;

@interface PAColors : NSObject

+ (void)loadThemeColors;
+ (UIColor *)getColor:(PAColorsType)type;
+ (void)setColor:(UIColor *)color type:(PAColorsType)type;
+ (void)setDefaultColors;

@end
