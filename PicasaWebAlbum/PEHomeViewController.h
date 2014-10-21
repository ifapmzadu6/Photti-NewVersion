//
//  PHHomeViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@class PEAlbumListDataSource, PEMomentListDataSource, PEPhotoListDataSource;

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

@interface PEHomeViewController : PABaseViewController <UITableViewDataSource>

+ (NSArray *)defaultEnabledItems;
+ (NSString *)localizedStringFromRowType:(NSString *)rowType;
+ (NSString *)rowTypeFromLocalizedString:(NSString *)rowType;

@property (strong, nonatomic, readonly) UITableView *tableView;
@property (strong, nonatomic, readonly) UIImageView *todayImageView;
@property (strong, nonatomic, readonly) UIImageView *yesterdayImageView;
@property (strong, nonatomic, readonly) UIImageView *thisWeekImageView;
@property (strong, nonatomic, readonly) UIImageView *lastWeekImageView;

@property (strong, nonatomic, readonly) NSArray *enabledItems;

@property (strong, nonatomic) PEAlbumListDataSource *albumListDataSource;
@property (strong, nonatomic) PEMomentListDataSource *momentListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *panoramaListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *videoListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *favoriteListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *timelapseListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *cloudListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *burstsListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *slomoVideosListDataSource;
@property (strong, nonatomic) PEPhotoListDataSource *allPhotoListDataSource;

@end
