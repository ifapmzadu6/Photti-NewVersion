//
//  PWColors.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWColors.h"

@interface PWColors ()

@property NSMutableDictionary *colors;

@end

@implementation PWColors

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _colors = [NSMutableDictionary dictionary];
        [self setDefaultColors];
    }
    return self;
}

+ (void)loadThemeColors {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	PWColorsTheme theme = (PWColorsTheme)[userDefaults integerForKey:@"PWColorsTheme"];
	if (theme == PWColorsThemeDefault) {
		[PWColors setDefaultColors];
	}
}

+ (UIColor *)getColor:(PWColorsType)type {
    PWColors *sharedManager = [PWColors sharedManager];
    return [sharedManager getColor:type];
}

+ (void)setColor:(UIColor *)color type:(PWColorsType)type {
    PWColors *sharedManager = [PWColors sharedManager];
    [sharedManager setColor:color type:type];
}

+ (void)setDefaultColors {
    PWColors *sharedManager = [PWColors sharedManager];
    [sharedManager setDefaultColors];
}

- (UIColor *)getColor:(PWColorsType)type {
    return [_colors objectForKey:[self key:type]];
}

- (void)setColor:(UIColor *)color type:(PWColorsType)type {
    [_colors setObject:color forKey:[self key:type]];
}

- (NSString *)key:(PWColorsType)type {
	return [NSString stringWithFormat:@"PWT%d", type];
}

- (void)setDefaultColors {
    [self setColor:[UIColor colorWithRed:255.0f/255.0f green:83.0f/255.0f blue:83.0f/255.0f alpha:1.0f]
              type:PWColorsTypeTintWebColor];
    [self setColor:[UIColor colorWithRed:115.0f/255.0f green:115.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
              type:PWColorsTypeTintLocalColor];
    [self setColor:[UIColor colorWithRed:94.0f/255.0f green:174.0f/255.0f blue:158.0f/255.0f alpha:1.0f]
              type:PWColorsTypeTintUploadColor];
    
	[self setColor:[UIColor colorWithRed:61.0f/255.0f green:67.0f/255.0f blue:71.0f/255.0f alpha:1.0f]
			  type:PWColorsTypeTextColor];
    [self setColor:[UIColor colorWithRed:0.405f green:0.411f blue:0.431f alpha:1.0f]
			  type:PWColorsTypeTextDarkColor];
	[self setColor:[UIColor colorWithRed:0.528f green:0.532f blue:0.548f alpha:1.0f]
			  type:PWColorsTypeTextLightColor];
	[self setColor:[UIColor colorWithRed:0.628f green:0.632f blue:0.644f alpha:1.0f]
			  type:PWColorsTypeTextLightSubColor];
	[self setColor:[UIColor colorWithWhite:1.0f alpha:1.0f]
			  type:PWColorsTypeBackgroundColor];
    [self setColor:[UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f]
			  type:PWColorsTypeBackgroundLightColor];
	[self setColor:[UIColor colorWithRed:210.0f/255.0f green:213.0f/255.0f blue:215.0f/255.0f alpha:1.0f]
			  type:PWColorsTypeBackgroundDarkColor];
}

@end
