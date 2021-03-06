//
//  PWAlbumEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumEditViewController.h"

#import "PAColors.h"
#import "PWPicasaAPI.h"
#import "PWDatePickerView.h"
#import "PADateTimestamp.h"
#import "PAActivityIndicatorView.h"
#import "PAAlertControllerKit.h"
#import <Reachability.h>

typedef NS_ENUM(NSUInteger, PWAlbumEditViewControllerCellRow) {
    PWAlbumEditViewControllerCellRowTitle,
    PWAlbumEditViewControllerCellRowTimestamp
};

typedef NS_ENUM(NSUInteger, PWAlbumEditViewControllerCellAccessRow) {
    PWAlbumEditViewControllerCellAccessRowAccess,
    PWAlbumEditViewControllerCellAccessRowShare
};

@interface PWAlbumEditViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) PWAlbumObject *album;

@end

@implementation PWAlbumEditViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [super init];
    if (self) {
        _album = album;        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Edit", nil);
    
    _timestamp = _album.gphoto.timestamp;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.exclusiveTouch = YES;
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    UIBarButtonItem *saveBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveBarButtonAction)];
    self.navigationItem.rightBarButtonItem = saveBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    self.navigationController.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PAColors getColor:kPAColorsTypeTextColor]};
    
    [[UITextField appearance] setTintColor:[PAColors getColor:kPAColorsTypeTintWebColor]];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
    
    CGFloat dHeight = 216.0f + 44.0f;
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        dHeight = 162.0 + 44.0f;
    }
    _datePickerView.frame = CGRectMake(0.0f, rect.size.height - dHeight, rect.size.width, dHeight);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    for (NSIndexPath *indexPath in _tableView.indexPathsForSelectedRows) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_textField resignFirstResponder];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        cell.textLabel.textColor = [PAColors getColor:kPAColorsTypeTextColor];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.clipsToBounds = YES;
    
    if (indexPath.section == 0) {
        if (indexPath.row == PWAlbumEditViewControllerCellRowTitle) {
            cell.textLabel.text = NSLocalizedString(@"Title", nil);
            CGSize textSize = [cell.textLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            UITextField *textField = _textField;
            if (!textField) {
                textField = [self makeTextField:textSize];
            }
            cell.accessoryView = textField;
            if (!_isDisplayed) {
                _isDisplayed = YES;
                [textField becomeFirstResponder];
            }
        }
        else if (indexPath.row == PWAlbumEditViewControllerCellRowTimestamp) {
            cell.textLabel.text = NSLocalizedString(@"Date", nil);
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterLongStyle;
            NSDate *date = [PADateTimestamp dateForTimestamp:_timestamp];
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
        if (indexPath.row == PWAlbumEditViewControllerCellRowTimestamp) {
            [self enableDatePicker];
        }
    }
}

#pragma mark UITableViewCellOption
- (UITextField *)makeTextField:(CGSize)textSize {
    if (_textField) {
        return _textField;
    }
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width - textSize.width - 60.0f, 20.0f)];
    textField.delegate = self;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.font = [UIFont systemFontOfSize:15.0f];
    textField.text = _album.title;
    textField.returnKeyType = UIReturnKeyDone;
    textField.exclusiveTouch = YES;
    
    _textField = textField;
    
    return textField;
}

#pragma mark UITextField
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark Methods
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
    
    NSDate *date = [PADateTimestamp dateForTimestamp:_timestamp];
    _datePickerView = [[PWDatePickerView alloc] initWithDate:date];
    _datePickerView.tintColor = [PAColors getColor:kPAColorsTypeTintWebColor];
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
        
        sself.timestamp = [PADateTimestamp timestampForDate:date];
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
- (void)saveBarButtonAction {
    if (!_album) {
        return;
    }
    
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [PAAlertControllerKit showNotCollectedToNetwork];
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Saving...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [PAAlertControllerKit attachActivityIndicatorView:alertView];
    [alertView show];
    
    NSString *albumTitle = nil;
    UITextField *textField = _textField;
    if (textField) {
        if (![textField.text isEqualToString:@""]) {
            albumTitle = textField.text;
        }
    }
    if (!albumTitle) {
        albumTitle = _album.title;
    }
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI putModifyingAlbumWithID:_album.id_str title:albumTitle summary:_album.summary location:_album.gphoto.location access:kPWPicasaAPIGphotoAccessProtected timestamp:_timestamp keywords:_album.media.keywords completion:^(NSError *error) {
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView dismissWithClickedButtonIndex:0 animated:YES];
            });
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


- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

@end
