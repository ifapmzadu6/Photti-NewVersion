//
//  PAColors.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAColors.h"

@interface PAColors ()

@property NSMutableDictionary *colors;

@end

@implementation PAColors

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
	kPAColorsTheme theme = (kPAColorsTheme)[userDefaults integerForKey:@"kPAColorsTheme"];
	if (theme == kPAColorsThemeDefault) {
		[PAColors setDefaultColors];
	}
}

+ (UIColor *)getColor:(kPAColorsType)type {
    PAColors *sharedManager = [PAColors sharedManager];
    return [sharedManager getColor:type];
}

+ (void)setColor:(UIColor *)color type:(kPAColorsType)type {
    PAColors *sharedManager = [PAColors sharedManager];
    [sharedManager setColor:color type:type];
}

+ (void)setDefaultColors {
    PAColors *sharedManager = [PAColors sharedManager];
    [sharedManager setDefaultColors];
}

- (UIColor *)getColor:(kPAColorsType)type {
    return [_colors objectForKey:[self key:type]];
}

- (void)setColor:(UIColor *)color type:(kPAColorsType)type {
    [_colors setObject:color forKey:[self key:type]];
}

- (NSString *)key:(kPAColorsType)type {
	return [NSString stringWithFormat:@"PWT%d", type];
}

- (void)setDefaultColors {
    [self setColor:[UIColor colorWithRed:255.0f/255.0f green:83.0f/255.0f blue:83.0f/255.0f alpha:1.0f]
              type:kPAColorsTypeTintWebColor];
    [self setColor:[UIColor colorWithRed:115.0f/255.0f green:115.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
              type:kPAColorsTypeTintLocalColor];
    [self setColor:[UIColor colorWithRed:94.0f/255.0f green:174.0f/255.0f blue:158.0f/255.0f alpha:1.0f]
              type:kPAColorsTypeTintUploadColor];
    [self setColor:[UIColor colorWithRed:0.0f green:122.0f/255.0f blue:1.0f alpha:1.0f]
              type:kPAColorsTypeTintDefaultColor];
    
	[self setColor:[UIColor colorWithRed:61.0f/255.0f green:67.0f/255.0f blue:71.0f/255.0f alpha:1.0f]
			  type:kPAColorsTypeTextColor];
    [self setColor:[UIColor colorWithRed:0.405f green:0.411f blue:0.431f alpha:1.0f]
			  type:kPAColorsTypeTextDarkColor];
	[self setColor:[UIColor colorWithRed:0.528f green:0.532f blue:0.548f alpha:1.0f]
			  type:kPAColorsTypeTextLightColor];
	[self setColor:[UIColor colorWithRed:0.628f green:0.632f blue:0.644f alpha:1.0f]
			  type:kPAColorsTypeTextLightSubColor];
    
	[self setColor:[UIColor colorWithWhite:1.0f alpha:1.0f]
			  type:kPAColorsTypeBackgroundColor];
    [self setColor:[UIColor colorWithRed:235.0f/255.0f green:238.0f/255.0f blue:240.0f/255.0f alpha:1.0f]
			  type:kPAColorsTypeBackgroundLightColor];
	[self setColor:[UIColor colorWithRed:210.0f/255.0f green:213.0f/255.0f blue:215.0f/255.0f alpha:1.0f]
			  type:kPAColorsTypeBackgroundDarkColor];
}

@end
