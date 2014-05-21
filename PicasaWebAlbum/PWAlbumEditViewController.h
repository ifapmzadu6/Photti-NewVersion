//
//  PWAlbumEditViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PWPicasaAPI.h"

@class PWDatePickerView;

@interface PWAlbumEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithAlbum:(PWAlbumObject *)album;

@property (strong, nonatomic) void (^successBlock)();

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) PWDatePickerView *datePickerView;
@property (strong, nonatomic) UITextField *textField;

@property (strong, nonatomic) NSString *timestamp;

@property (nonatomic) BOOL isDisplayed;

@end
