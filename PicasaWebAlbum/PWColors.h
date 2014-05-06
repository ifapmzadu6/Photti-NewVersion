//
//  PWColors.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _PWColorsTheme {
	PWColorsThemeDefault,
	PWColorsThemeNight
} PWColorsTheme;

typedef enum _PWColorsType {
	PWColorsTypeMainTintColor,
	PWColorsTypeSubTintColor,
	PWColorsTypeBackgroundColor,
	PWColorsTypeBackgroundLightColor,
	PWColorsTypeBackgroundDarkColor,
	PWColorsTypeTextColor,
	PWColorsTypeTextDarkColor,
	PWColorsTypeTextLightColor,
	PWColorsTypeTextLightSubColor,
    
    //BarColors
    PWColorsTypeBarColor
} PWColorsType;

@interface PWColors : NSObject

+ (void)loadThemeColors;
+ (UIColor *)getColor:(PWColorsType)type;
+ (void)setColor:(UIColor *)color type:(PWColorsType)type;
+ (void)setDefaultColors;

@end
