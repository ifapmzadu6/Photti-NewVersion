//
//  PLAlbumEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/14.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAlbumEditViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLModelObject.h"
#import <BlocksKit+UIKit.h>
#import "PWDatePickerView.h"

@interface PLAlbumEditViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation PLAlbumEditViewController

- (id)initWithTitle:(NSString *)title timestamp:(NSNumber *)timestamp uploading_type:(NSNumber *)uploading_type {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Edit", nil);
        
        _name = title;
        _timestamp = timestamp;
        if (uploading_type) {
            _uploading_type = uploading_type;
        }
        else {
            _uploading_type = @(PLAlbumObjectTagUploadingTypeYES);
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [PAColors getColor:PWColorsTypeTintLocalColor];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    UIBarButtonItem *saveBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(saveBarButtonAction)];
    [saveBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = saveBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PAColors getColor:PWColorsTypeBackgroundLightColor];
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.exclusiveTouch = YES;
    [self.view addSubview:_tableView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem
- (void)cancelBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveBarButtonAction {
    if (_saveButtonBlock) {
        _saveButtonBlock(_nameTextField.text, _timestamp, _uploading_type);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0:
            numberOfRows = 2;
            break;
        case 1:
            numberOfRows = 1;
            break;
        default:
            break;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        cell.textLabel.textColor = [PAColors getColor:PWColorsTypeTextColor];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.clipsToBounds = YES;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Title", nil);
            CGSize textSize = [cell.textLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            cell.accessoryView = [self makeTextField:textSize];
            if (!_isDisplayed) {
                _isDisplayed = YES;
                [_nameTextField becomeFirstResponder];
            }
        }
        else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Date", nil);
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterLongStyle;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:_timestamp.longLongValue / 1000];
            cell.detailTextLabel.text = [dateFormatter stringFromDate:date];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Auto Uploading", nil);
            
            UISwitch *autoUploadingSwitch = [[UISwitch alloc] init];
            autoUploadingSwitch.on = (_uploading_type.integerValue == PLAlbumObjectTagUploadingTypeYES);
            __weak typeof(self) wself = self;
            [autoUploadingSwitch bk_addEventHandler:^(UISwitch * sender) {
                typeof(wself) sself = wself;
                if (!sself) return;
                
                if (sender.on) {
                    _uploading_type = @(PLAlbumObjectTagUploadingTypeYES);
                }
                else {
                    _uploading_type = @(PLAlbumObjectTagUploadingTypeNO);
                }
            } forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = autoUploadingSwitch;
        }
    }
    
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            [self enableDatePicker];
        }
    }
}

#pragma mark UITableViewCellOption
- (UITextField *)makeTextField:(CGSize)textSize {
    if (_nameTextField) {
        return _nameTextField;
    }
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width - textSize.width - 60.0f, 20.0f)];
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.font = [UIFont systemFontOfSize:15.0f];
    textField.text = _name;
    textField.returnKeyType = UIReturnKeyDone;
    [textField setBk_shouldReturnBlock:^BOOL(UITextField *textField) {
        [textField resignFirstResponder];
        
        return YES;
    }];
    textField.exclusiveTouch = YES;
    
    _nameTextField = textField;
    
    return textField;
}

- (void)enableDatePicker {
    UITextField *textField = _nameTextField;
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
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_timestamp.longLongValue / 1000];
    _datePickerView = [[PWDatePickerView alloc] initWithDate:date];
    _datePickerView.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    CGRect rect = self.view.bounds;
    CGFloat dHeight = 216.0f + 44.0f;
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        dHeight = 162.0 + 44.0f;
    }
    _datePickerView.frame = CGRectMake(0.0f, rect.size.height, rect.size.width, dHeight);
    __weak typeof(self) wself = self;
    [_datePickerView setDoneBlock:^(UIView *datePickerView, NSDate *date) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.timestamp = @((long long)[date timeIntervalSince1970] * 1000);
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



@end
