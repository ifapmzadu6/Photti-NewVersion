//
//  PWAlbumShareViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumShareViewController.h"

#import "PAColors.h"
#import "PWPicasaAPI.h"
#import "PAIcons.h"
#import <Reachability.h>

@interface PWAlbumShareViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) PWAlbumObject *album;

@property (nonatomic) NSUInteger selectedIndex;

@end

@implementation PWAlbumShareViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [super init];
    if (self) {
        _album = album;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = _album.title;
    
    for (NSString *access in [self arrayOfAccess]) {
        if ([access isEqualToString:_album.gphoto.access]) {
            _selectedIndex = [[self arrayOfAccess] indexOfObject:access];
        }
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    _tableView.exclusiveTouch = YES;
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.leftBarButtonItem = doneBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    self.navigationController.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PAColors getColor:PAColorsTypeTextColor]};
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    }
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    }
    cell.textLabel.text = nil;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    cell.textLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    UIView *view = [cell viewWithTag:100];
    if (view) {
        [view removeFromSuperview];
    }
    
    if (indexPath.section == 0) {
        NSString *key = [[self arrayOfAccess] objectAtIndex:indexPath.row];
        cell.textLabel.text = [[self dictionaryOfAccessDesplayString] objectForKey:key];
        if (indexPath.row == _selectedIndex) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.textLabel.textColor = [[PAColors getColor:PAColorsTypeTextColor] colorWithAlphaComponent:0.8f];
        }
    }
    else {
        if (indexPath.row == 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
            NSString *link = nil;
            if (![_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessProtected]) {
                for (PWPhotoLinkObject *linkObject in _album.link) {
                    if ([linkObject.rel isEqualToString:kPWPicasaAPILinkRelShare]) {
                        link = linkObject.href;
                    }
                }
            }
            if (!link) {
                cell.textLabel.text = @"http://";
                cell.textLabel.textColor = [[PAColors getColor:PAColorsTypeTextColor] colorWithAlphaComponent:0.5f];
            }
            else {
                cell.textLabel.text = link;
                cell.textLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
            }
        }
        else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UIButton *button = [UIButton new];
            button.tag = 100;
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            [button addTarget:self action:@selector(shareButtonAction) forControlEvents:UIControlEventTouchUpInside];
            button.frame = CGRectMake(0.0f, 0.0f, 150.0f, 32.0f);
            button.center = cell.contentView.center;
            button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
            [button setTitle:NSLocalizedString(@"Share the link", nil) forState:UIControlStateNormal];
            [button setBackgroundImage:[PAIcons imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
            [button setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:PAColorsTypeTintWebColor]] forState:UIControlStateNormal];
            [button setTitleColor:[PAColors getColor:PAColorsTypeTintWebColor] forState:UIControlStateHighlighted];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.clipsToBounds = YES;
            button.layer.borderColor = [PAColors getColor:PAColorsTypeTintWebColor].CGColor;
            button.layer.borderWidth = 1.0f;
            button.layer.cornerRadius = 5.0f;
            button.exclusiveTouch = YES;
            [cell.contentView addSubview:button];
            
            NSString *link = nil;
            if (![_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessProtected]) {
                for (PWPhotoLinkObject *linkObject in _album.link) {
                    if ([linkObject.rel isEqualToString:kPWPicasaAPILinkRelShare]) {
                        link = linkObject.href;
                    }
                }
            }
            if (!link) {
                button.alpha = 0.334f;
                button.userInteractionEnabled = NO;
            }
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Share", nil);
    }
    return NSLocalizedString(@"Link", nil);
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == _selectedIndex) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        
        if (![Reachability reachabilityForInternetConnection].isReachable) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not connected to network", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [alertView show];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alertView dismissWithClickedButtonIndex:0 animated:YES];
            });
            
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Saving...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
        [indicator startAnimating];
        [alertView setValue:indicator forKey:@"accessoryView"];
        [alertView show];
        
        NSString *access = [[self arrayOfAccess] objectAtIndex:indexPath.row];
        __weak typeof(self) wself = self;
        [PWPicasaAPI putModifyingAlbumWithID:_album.id_str
                                       title:nil
                                     summary:nil
                                    location:nil
                                      access:access
                                   timestamp:nil
                                    keywords:nil
                                  completion:^(NSError *error) {
                                      typeof(wself) sself = wself;
                                      if (!sself) return;
                                      if (error) {
#ifdef DEBUG
                                          NSLog(@"%@", error);
#endif
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [alertView dismissWithClickedButtonIndex:0 animated:YES];
                                              
                                              [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
                                          });
                                          return;
                                      }
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [alertView dismissWithClickedButtonIndex:0 animated:YES];
                                          
                                          sself.selectedIndex = indexPath.row;
                                          [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
                                      });
                                      
                                      if (sself.changedAlbumBlock) {
                                          sself.changedAlbumBlock();
                                      }
                                  }];
    }
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIButton
- (void)shareButtonAction {
    NSString *link = nil;
    if (![_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessProtected]) {
        for (PWPhotoLinkObject *linkObject in _album.link) {
            if ([linkObject.rel isEqualToString:kPWPicasaAPILinkRelShare]) {
                link = linkObject.href;
            }
        }
    }
    if (link) {
        NSURL *url = [NSURL URLWithString:link];
        UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[_album.title, url] applicationActivities:nil];
        [self.navigationController presentViewController:viewController animated:YES completion:nil];
    }
}

#pragma mark AccessLocalizedString
- (NSArray *)arrayOfAccess {
    static dispatch_once_t onceToken;
    static id array;
    dispatch_once(&onceToken, ^{
        array = @[kPWPicasaAPIGphotoAccessPublic, kPWPicasaAPIGphotoAccessPrivate, kPWPicasaAPIGphotoAccessProtected];
    });
    return array;
}

- (NSDictionary *)dictionaryOfAccessDesplayString {
    static dispatch_once_t onceToken;
    static id dictionary;
    dispatch_once(&onceToken, ^{
        //すべての人に公開
        dictionary = @{kPWPicasaAPIGphotoAccessPublic: NSLocalizedString(@"Public on the web", nil), kPWPicasaAPIGphotoAccessPrivate: NSLocalizedString(@"Anyone with the link", nil), kPWPicasaAPIGphotoAccessProtected: NSLocalizedString(@"Only you can access", nil)};
    });
    return dictionary;
}

@end
