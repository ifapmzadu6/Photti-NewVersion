//
//  PWNewAlbumEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWNewAlbumEditViewController.h"

#import "PWColors.h"
#import "PWDatePickerView.h"
#import "BlocksKit+UIKit.h"
#import "PWPicasaAPI.h"

#import "PWSelectItemFromArrayViewController.h"

typedef enum _PWNewAlbumEditViewControllerCellRow {
    PWNewAlbumEditViewControllerCellRowTitle = 0,
    PWNewAlbumEditViewControllerCellRowAccess,
    PWNewAlbumEditViewControllerCellRowTimestamp
} PWNewAlbumEditViewControllerCellRow;

@interface PWNewAlbumEditViewController ()

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) PWDatePickerView *datePickerView;
@property (weak, nonatomic) UITextField *textField;

@property (strong, nonatomic) NSString *timestamp;
@property (strong, nonatomic) NSString *accessDisplayString;

@property (nonatomic) BOOL isDisplayed;

@end

@implementation PWNewAlbumEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"新規アルバム";
    
    NSDate * date = [NSDate date];
    _timestamp = [NSString stringWithFormat:@"%lu", (unsigned long)[date timeIntervalSince1970]];
    
    _accessDisplayString = NSLocalizedString(@"非公開", nil);
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    UIBarButtonItem *createBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"作成" style:UIBarButtonItemStylePlain target:self action:@selector(createBarButtonAction)];
    [createBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = createBarButtonItem;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
    
    CGFloat dHeight = 216.0f + 44.0f;
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        dHeight = 162.0 + 44.0f;
    }
    _datePickerView.frame = CGRectMake(0.0f, rect.size.height - dHeight, rect.size.width, dHeight);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSIndexPath *indexPath in _tableView.indexPathsForSelectedRows) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        cell.textLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0) {
        if (indexPath.row == PWNewAlbumEditViewControllerCellRowTitle) {
            cell.textLabel.text = @"タイトル";
            CGSize textSize = [cell.textLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            UITextField *textField = [self makeTextField:textSize];
            cell.accessoryView = textField;
            if (!_isDisplayed) {
                _isDisplayed = YES;
                [textField becomeFirstResponder];
            }
        }
        else if (indexPath.row == PWNewAlbumEditViewControllerCellRowAccess) {
            cell.textLabel.text = @"共有";
            cell.detailTextLabel.text = @"非公開"; // 非公開、リンクを知っている人に公開、すべての人に公開
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (indexPath.row == PWNewAlbumEditViewControllerCellRowTimestamp) {
            cell.textLabel.text = @"日付";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterLongStyle;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:_timestamp.longLongValue];
            cell.detailTextLabel.text = [dateFormatter stringFromDate:date];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == PWNewAlbumEditViewControllerCellRowAccess) {
            NSArray *items = @[NSLocalizedString(@"すべての人に公開", nil), [NSString stringWithFormat:@"%@(%@)", NSLocalizedString(@"リンクを知っている人に公開", nil), NSLocalizedString(@"後で設定可能",nil)], NSLocalizedString(@"非公開", nil)];
            PWSelectItemFromArrayViewController *viewController = [[PWSelectItemFromArrayViewController alloc] initWithItems:items defaultIndex:[items indexOfObject:_accessDisplayString]];
            viewController.disableIndex = 1;
            viewController.title = NSLocalizedString(@"共有", nil);
            UILabel *label = (UILabel *)[_tableView cellForRowAtIndexPath:indexPath].detailTextLabel;
            __weak typeof(self) wself = self;
            [viewController setDoneBlock:^(NSString *selectedItem) {
                typeof(wself) sself = wself;
                if (!sself) return;
                
                sself.accessDisplayString = selectedItem;
                
                label.text = (NSString *)selectedItem;
            }];
            [self.navigationController pushViewController:viewController animated:YES];
        }
        else if (indexPath.row == PWNewAlbumEditViewControllerCellRowTimestamp) {
            [self enableDatePicker];
        }
    }
}

#pragma mark UITableViewCellOption
- (UITextField *)makeTextField:(CGSize)textSize {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width - textSize.width - 50.0f, 20.0f)];
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.font = [UIFont systemFontOfSize:15.0f];
    textField.placeholder = NSLocalizedString(@"新規アルバム", nil);
    textField.returnKeyType = UIReturnKeyDone;
    [textField setBk_shouldReturnBlock:^BOOL(UITextField *textField) {
        [textField resignFirstResponder];
        
        return YES;
    }];
    
    _textField = textField;
    
    return textField;
}

- (void)enableDatePicker {
    UITextField *textField = _textField;
    if (textField) {
        [textField resignFirstResponder];
    }
    
    _backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    _backgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    _backgroundView.alpha = 0.0f;
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disableDatePicker)];
    [_backgroundView addGestureRecognizer:tapGestureRecognizer];
    _backgroundView.userInteractionEnabled = YES;
    [self.navigationController.view addSubview:_backgroundView];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_timestamp.longLongValue];
    _datePickerView = [[PWDatePickerView alloc] initWithDate:date];
    CGRect rect = self.view.bounds;
    CGFloat dHeight = 216.0f + 44.0f;
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        dHeight = 162.0 + 44.0f;
    }
    _datePickerView.frame = CGRectMake(0.0f, rect.size.height, rect.size.width, dHeight);
    __weak typeof(self) wself = self;
    [_datePickerView setDoneBlock:^(UIView *datePickerView, NSDate *date) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.timestamp = [NSString stringWithFormat:@"%lu", (unsigned long)[date timeIntervalSince1970]];
        [sself.tableView reloadRowsAtIndexPaths:sself.tableView.indexPathsForSelectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [sself disableDatePicker];
    }];
    [_datePickerView setCancelBlock:^(UIView *datePickerView) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself disableDatePicker];
    }];
    [self.navigationController.view addSubview:_datePickerView];
    
    [UIView animateWithDuration:0.4f delay:0.0f options:(7 << 16) animations:^{
        _backgroundView.alpha = 1.0f;
        
        _datePickerView.frame = (CGRect){.origin = CGPointMake(0.0f, rect.size.height - (dHeight)), .size = _datePickerView.frame.size};
    } completion:nil];
}

- (void)disableDatePicker {
    for (NSIndexPath *indexPath in _tableView.indexPathsForSelectedRows) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    CGRect rect = self.view.bounds;
    [UIView animateWithDuration:0.4f delay:0.0f options:(7 << 16) animations:^{
        _backgroundView.alpha = 0.0f;
        
        _datePickerView.frame = (CGRect){.origin = CGPointMake(0.0f, rect.size.height), .size = _datePickerView.frame.size};
    } completion:^(BOOL finished) {
        [_backgroundView removeFromSuperview];
        _backgroundView = nil;
        
        [_datePickerView removeFromSuperview];
        _datePickerView = nil;
    }];
}

#pragma mark UIBarButtonItem
- (void)createBarButtonAction {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"アルバムを作成しています" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    [alertView show];
    
    NSString *access = kPWPicasaAPIGphotoAccessPrivate;
    if ([_accessDisplayString isEqualToString:NSLocalizedString(@"すべての人に公開", nil)]) {
        access = kPWPicasaAPIGphotoAccessPublic;
    }
    
    NSString *albumTitle = nil;
    UITextField *textField = _textField;
    if (textField) {
        albumTitle = textField.text;
    }
    if (!albumTitle) {
        albumTitle = NSLocalizedString(@"新規アルバム", nil);
    }
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI postCreatingNewAlbumRequest:albumTitle
                                     summary:nil
                                    location:nil
                                      access:access
                                   timestamp:_timestamp
                                    keywords:nil
                                  completion:^(NSError *error) {
                                      if (error) {
                                          NSLog(@"%@", error.description);
                                          return;
                                      }
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [alertView dismissWithClickedButtonIndex:0 animated:YES];
                                          
                                          typeof(wself) sself = wself;
                                          if (!sself) return;
                                          [sself dismissViewControllerAnimated:YES completion:nil];
                                          if (sself.successBlock) {
                                              sself.successBlock();
                                          }
                                      });
                                  }];
}

- (void)cancelBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
