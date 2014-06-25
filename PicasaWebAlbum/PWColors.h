//
//  PWColors.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

typedef enum _PWColorsTheme {
	PWColorsThemeDefault,
	PWColorsThemeNight
} PWColorsTheme;

typedef enum _PWColorsType {
	PWColorsTypeTintWebColor,
	PWColorsTypeTintLocalColor,
    PWColorsTypeTintUploadColor,
	PWColorsTypeBackgroundColor,
	PWColorsTypeBackgroundLightColor,
	PWColorsTypeBackgroundDarkColor,
	PWColorsTypeTextColor,
	PWColorsTypeTextDarkColor,
	PWColorsTypeTextLightColor,
	PWColorsTypeTextLightSubColor,
} PWColorsType;

@interface PWColors : NSObject

+ (void)loadThemeColors;
+ (UIColor *)getColor:(PWColorsType)type;
+ (void)setColor:(UIColor *)color type:(PWColorsType)type;
+ (void)setDefaultColors;

@end
