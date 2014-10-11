//
//  PHHomeViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

static NSString * const kPEHomeViewControllerUserDefaultsEnabledItemKey = @"kPEHomeViewControllerUserDefaultsEnabledItemKey";
static NSString * const kPEHomeViewControllerUserDefaultsDisabledItemKey = @"kPEHomeViewControllerUserDefaultsDisabledItemKey";

static NSString * const kPEHomeViewControllerRowType_Albums = @"kPEHomeViewControllerRowType_Albums";
static NSString * const kPEHomeViewControllerRowType_Moments = @"kPEHomeViewControllerRowType_Moments";
static NSString * const kPEHomeViewControllerRowType_Videos = @"kPEHomeViewControllerRowType_Videos";
static NSString * const kPEHomeViewControllerRowType_Panoramas = @"kPEHomeViewControllerRowType_Panoramas";
static NSString * const kPEHomeViewControllerRowType_Timelapse = @"kPEHomeViewControllerRowType_Timelapse";
static NSString * const kPEHomeViewControllerRowType_Favorites = @"kPEHomeViewControllerRowType_Favorites";
static NSString * const kPEHomeViewControllerRowType_Cloud = @"kPEHomeViewControllerRowType_Cloud";
static NSString * const kPEHomeViewControllerRowType_Bursts = @"kPEHomeViewControllerRowType_Bursts";
static NSString * const kPEHomeViewControllerRowType_SlomoVideos = @"kPEHomeViewControllerRowType_SlomoVideos";
static NSString * const kPEHomeViewControllerRowType_AllPhotos = @"kPEHomeViewControllerRowType_AllPhotos";

@interface PEHomeViewController : PABaseViewController

+ (NSArray *)defaultEnabledItems;
+ (NSString *)localizedStringFromRowType:(NSString *)rowType;
+ (NSString *)rowTypeFromLocalizedString:(NSString *)rowType;

@end
