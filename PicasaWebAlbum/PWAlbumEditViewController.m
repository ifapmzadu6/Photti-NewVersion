//
//  PWAlbumEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumEditViewController.h"

#import "PWColors.h"
#import "PWDatePickerView.h"
#import "BlocksKit+UIKit.h"

#import "PWSelectItemFromArrayViewController.h"

typedef enum _PWAlbumEditViewControllerCellRow {
    PWAlbumEditViewControllerCellRowTitle = 0,
    PWAlbumEditViewControllerCellRowTimestamp
} PWAlbumEditViewControllerCellRow;

typedef enum _PWAlbumEditViewControllerCellAccessRow {
    PWAlbumEditViewControllerCellAccessRowAccess,
    PWAlbumEditViewControllerCellAccessRowShare
} PWAlbumEditViewControllerCellAccessRow;

@interface PWAlbumEditViewController ()

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
    
    self.title = NSLocalizedString(@"アルバム編集", nil);
    
    _timestamp = _album.gphoto.timestamp;
    
    NSString *access = NSLocalizedString(@"非公開", nil);
    if ([_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessPublic]) {
        access = NSLocalizedString(@"すべての人に公開", nil);
    }
    else if ([_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessPrivate]) {
        access = NSLocalizedString(@"リンクを知っている人に公開", nil);
    }
    _accessDisplayString = access;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    UIBarButtonItem *createBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"保存", nil) style:UIBarButtonItemStylePlain target:self action:@selector(createBarButtonAction)];
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
    
    UIButton *linkCopyButton = _linkCopyButton;
    if (linkCopyButton) {
        linkCopyButton.frame = CGRectMake(20.0f, 2.0f, (rect.size.width - 40.0f) / 2.0f - 10.0f, 40.0f);
    }
    UIButton *linkShareButton = _linkShareButton;
    if (linkShareButton) {
        linkShareButton.frame = CGRectMake(20.0f + 20.0f + (rect.size.width - 40.0f) / 2.0f - 10.0f, 2.0f, (rect.size.width - 40.0f) / 2.0f - 10.0f, 40.0f);
    }
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        if ([_accessDisplayString isEqualToString:NSLocalizedString(@"非公開", nil)]) {
            return 1;
        }
    }
    return 2;
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
    cell.clipsToBounds = YES;
    
    if (indexPath.section == 0) {
        if (indexPath.row == PWAlbumEditViewControllerCellRowTitle) {
            cell.textLabel.text = @"タイトル";
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
            cell.textLabel.text = @"日付";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterLongStyle;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:_timestamp.longLongValue / 1000];
            cell.detailTextLabel.text = [dateFormatter stringFromDate:date];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == PWAlbumEditViewControllerCellAccessRowAccess) {
            cell.textLabel.text = @"共有";
            cell.detailTextLabel.text = _accessDisplayString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (indexPath.row == PWAlbumEditViewControllerCellAccessRowShare) {
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            
            CGRect rect = self.view.bounds;
            if (_linkCopyButton) {
                [_linkCopyButton removeFromSuperview];
                _linkCopyButton = nil;
            }
            if (_linkShareButton) {
                [_linkShareButton removeFromSuperview];
                _linkShareButton = nil;
            }
            if (!_linkCopyButton) {
                UIButton *linkCopyButton = [[UIButton alloc] initWithFrame:CGRectMake(20.0f, 2.0f, (rect.size.width - 40.0f) / 2.0f - 10.0f, 40.0f)];
                [linkCopyButton addTarget:self action:@selector(linkCopyAction) forControlEvents:UIControlEventTouchUpInside];
                linkCopyButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
                [linkCopyButton setTitle:NSLocalizedString(@"リンクをコピー", nil) forState:UIControlStateNormal];
                [linkCopyButton setTitleColor:linkCopyButton.tintColor forState:UIControlStateNormal];
                [linkCopyButton setTitleColor:[linkCopyButton.tintColor colorWithAlphaComponent:0.2f] forState:UIControlStateHighlighted];
                [cell.contentView addSubview:linkCopyButton];
                
                _linkCopyButton = linkCopyButton;
            }
            if (!_linkShareButton) {
                UIButton *linkShareButton = [[UIButton alloc] initWithFrame:CGRectMake(20.0f + 20.0f + (rect.size.width - 40.0f) / 2.0f - 10.0f, 2.0f, (rect.size.width - 40.0f) / 2.0f - 10.0f, 40.0f)];
                [linkShareButton addTarget:self action:@selector(linkShareAction) forControlEvents:UIControlEventTouchUpInside];
                linkShareButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
                [linkShareButton setTitle:NSLocalizedString(@"リンクを共有", nil) forState:UIControlStateNormal];
                [linkShareButton setTitleColor:linkShareButton.tintColor forState:UIControlStateNormal];
                [linkShareButton setTitleColor:[linkShareButton.tintColor colorWithAlphaComponent:0.2f] forState:UIControlStateHighlighted];
                [cell.contentView addSubview:linkShareButton];
                
                _linkShareButton = linkShareButton;
            }
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
    else if (indexPath.section == 1) {
        if (indexPath.row == PWAlbumEditViewControllerCellAccessRowAccess) {
            UILabel *label = (UILabel *)[_tableView cellForRowAtIndexPath:indexPath].detailTextLabel;
            UIViewController *viewController = [self viewControllerSelectItemViewController:label];
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UITextField *textField = _textField;
    if (textField) {
        CGFloat pointY = scrollView.contentOffset.y + 64.0f;
        if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            pointY -= 12.0f;
        }
        if (fabsf(pointY) > 30.0f) {
            [textField resignFirstResponder];
        }
    }
}

#pragma mark UITableViewCellOption
- (UITextField *)makeTextField:(CGSize)textSize {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width - textSize.width - 60.0f, 20.0f)];
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.font = [UIFont systemFontOfSize:15.0f];
    textField.text = _album.title;
    textField.returnKeyType = UIReturnKeyDone;
    [textField setBk_shouldReturnBlock:^BOOL(UITextField *textField) {
        [textField resignFirstResponder];
        
        return YES;
    }];
    
    _textField = textField;
    
    return textField;
}

- (void)linkCopyAction {
    NSString *link = nil;
    for (PWPhotoLinkObject *linkObject in _album.link.allObjects) {
        if ([kPWPicasaAPILinkRelShare isEqualToString:linkObject.rel]) {
            link = linkObject.href;
        }
    }
    if (!link) {
        return;
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = link;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"コピーしました。", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Done", nil), nil];
    [alertView show];
}

- (void)linkShareAction {
    NSString *link = nil;
    for (PWPhotoLinkObject *linkObject in _album.link.allObjects) {
        if ([kPWPicasaAPILinkRelShare isEqualToString:linkObject.rel]) {
            link = linkObject.href;
        }
    }
    if (!link) {
        return;
    }
    NSURL *url = [NSURL URLWithString:link];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[_album.title, url] applicationActivities:nil];
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
}

- (UIViewController *)viewControllerSelectItemViewController:(UILabel *)label {
    NSArray *items = [self arrayOfAccessItem];
    NSUInteger index = NSUIntegerMax;
    for (NSString *item in items) {
        if ([item isEqualToString:_accessDisplayString]) {
            index = [items indexOfObject:item];
        }
    }
    PWSelectItemFromArrayViewController *viewController = [[PWSelectItemFromArrayViewController alloc] initWithItems:items defaultIndex:index];
    viewController.disableIndex = NSUIntegerMax;
    viewController.title = NSLocalizedString(@"共有", nil);
    __weak typeof(self) wself = self;
    [viewController setDoneBlock:^(NSString *selectedItem) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        sself.accessDisplayString = selectedItem;
        
        label.text = (NSString *)selectedItem;
        
        [sself.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    return viewController;
}

- (NSArray *)arrayOfAccessItem {
    NSArray *items = @[NSLocalizedString(@"すべての人に公開", nil), NSLocalizedString(@"リンクを知っている人に公開", nil), NSLocalizedString(@"非公開", nil)];
    return items;
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
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_timestamp.longLongValue / 1000];
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
    if (!_album) {
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"アルバムを保存しています", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    [alertView show];
    
    NSString *access = kPWPicasaAPIGphotoAccessProtected;
    if ([_accessDisplayString isEqualToString:NSLocalizedString(@"すべての人に公開", nil)]) {
        access = kPWPicasaAPIGphotoAccessPublic;
    }
    else if ([_accessDisplayString isEqualToString:NSLocalizedString(@"リンクを知っている人に公開", nil)]) {
        access = kPWPicasaAPIGphotoAccessPrivate;
    }
    
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
    [PWPicasaAPI putModifyingAlbumWithID:_album.id_str
                                   title:albumTitle
                                 summary:_album.summary
                                location:_album.gphoto.location
                                  access:access
                               timestamp:_timestamp
                                keywords:_album.media.keywords
                              completion:^(NSError *error) {
                                  if (error) {
                                      NSLog(@"%@", error.description);
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

@end
