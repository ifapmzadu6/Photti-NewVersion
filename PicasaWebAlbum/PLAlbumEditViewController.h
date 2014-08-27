//
//  PLAlbumEditViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/14.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@class PWDatePickerView;

@interface PLAlbumEditViewController : PABaseViewController

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UITextField *nameTextField;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) PWDatePickerView *datePickerView;

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *timestamp;
@property (strong, nonatomic) NSNumber *uploading_type;

@property (nonatomic) BOOL isDisplayed;

@property (copy, nonatomic) void (^saveButtonBlock)(NSString *name, NSNumber *timestamp, NSNumber *uploading_type);

- (id)initWithTitle:(NSString *)title timestamp:(NSNumber *)timestamp uploading_type:(NSNumber *)uploading_type;

@end
