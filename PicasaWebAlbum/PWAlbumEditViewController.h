//
//  PWAlbumEditViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@class PWAlbumObject;

@class PWDatePickerView;

@interface PWAlbumEditViewController : PABaseViewController

- (id)initWithAlbum:(PWAlbumObject *)album;

@property (copy, nonatomic) void (^successBlock)();

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) PWDatePickerView *datePickerView;
@property (strong, nonatomic) UITextField *textField;

@property (strong, nonatomic) NSString *timestamp;

@property (nonatomic) BOOL isDisplayed;

@end
